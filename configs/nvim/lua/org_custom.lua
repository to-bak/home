-- org_custom.lua
--
-- Custom nvim-orgmode extensions.
--
-- Functions:
--   refile()        - Refile with full outline path in completion
--                     (e.g. projects.org/Active-Active/Meetings)
--                     nvim-orgmode's built-in refile only shows the immediate
--                     headline title, making same-named headings under different
--                     parents indistinguishable. As of 0.7.2, upstream still
--                     does NOT show full outline paths.
--
--   set_property()  - Set an arbitrary :PROPERTIES: key/value on the headline
--                     under cursor. Only works in org buffers (not agenda).

local M = {}

-- Shared helpers

local function outline_path(headline)
  local parts = {}
  local h = headline
  while h do
    table.insert(parts, 1, h.title)
    h = h.parent
  end
  return table.concat(parts, '/')
end

local function collect(headlines, out)
  for _, h in ipairs(headlines) do
    table.insert(out, h)
    collect(h.headlines, out)
  end
end

local function build_headline_index()
  local orgapi = require('orgmode.api')
  local candidates = {}
  local labels = {}
  -- pcall per file: orgmode's map_child_headlines can crash on stale state
  local ok, files = pcall(orgapi.load)
  if not ok then
    vim.notify('orgmode: failed to load files, retrying...', vim.log.levels.WARN)
    ok, files = pcall(orgapi.load)
    if not ok then return candidates, labels end
  end
  for _, file in ipairs(files) do
    local fname = vim.fn.fnamemodify(file.filename, ':t')
    local all = {}
    local cok, _ = pcall(collect, file.headlines, all)
    if cok then
      for _, h in ipairs(all) do
        local label = fname .. '/' .. outline_path(h)
        if not candidates[label] then
          table.insert(labels, label)
          candidates[label] = { headline = h, file = fname, title = h.title }
        end
      end
    end
  end
  return candidates, labels
end

local function fuzzy_complete(labels)
  return function(arg_lead)
    if not arg_lead or #arg_lead == 0 then
      return table.concat(labels, '\n')
    end
    return table.concat(vim.fn.matchfuzzy(labels, arg_lead), '\n')
  end
end

-- Refile with full outline path
function M.refile()
  local orgapi = require('orgmode.api')
  local source_file = orgapi.current()
  local source = source_file:get_closest_headline()
  if not source then
    vim.notify('No headline found under cursor', vim.log.levels.WARN)
    return
  end

  local candidates, labels = build_headline_index()

  -- Also add file-level targets
  local file_candidates = {}
  for _, file in ipairs(orgapi.load()) do
    local fname = vim.fn.fnamemodify(file.filename, ':t') .. '/'
    if not candidates[fname] then
      table.insert(labels, 1, fname)
      file_candidates[fname] = file
    end
  end

  _G._org_refile_complete = fuzzy_complete(labels)

  vim.ui.input({
    prompt = 'Refile to: ',
    completion = 'custom,v:lua._org_refile_complete',
  }, function(input)
    if not input or input == '' then return end
    local target = file_candidates[input]
      or (candidates[input] and candidates[input].headline)
    if not target then
      vim.notify('Invalid refile target: ' .. input, vim.log.levels.ERROR)
      return
    end
    orgapi.refile({ source = source, destination = target })
  end)
end

-- Set property on headline under cursor
function M.set_property()
  local orgapi = require('orgmode.api')
  local file = orgapi.current()
  local headline = file:get_closest_headline()
  if not headline then
    vim.notify('No headline found under cursor', vim.log.levels.WARN)
    return
  end
  vim.ui.input({ prompt = 'Property: ' }, function(key)
    if not key or key == '' then return end
    vim.ui.input({ prompt = 'Value: ' }, function(value)
      if not value then return end
      headline:set_property(key, value)
    end)
  end)
end

return M
