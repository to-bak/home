vim.wo.number = true
vim.opt.clipboard:append("unnamedplus")
vim.o.ignorecase = true
vim.opt.swapfile = false
vim.cmd('packadd cfilter')

-- Plenary.nvim
local async = require "plenary.async"

-- CommandLine
vim.keymap.set('c', '<C-y>', '<C-r>+', { desc = 'Paste from system clipboard' })
vim.keymap.set('c', '<C-j>', '<C-n>', { desc = 'Next completion item' })
vim.keymap.set('c', '<C-k>', '<C-p>', { desc = 'Previous completion item' })

-- Telescope
local telescope = require('telescope')
local telescope_actions = require('telescope.actions')

local function telescope_yank(promt_bufnr)
  -- This pulls from the + register (system clipboard)
  local selection = vim.fn.getreg('+'):gsub('\n', '')
  vim.api.nvim_put({ selection }, 'c', false, true)
end

telescope.setup
{
   defaults = {
      mappings = {
         i = {
            ["<C-j>"] = "move_selection_next",
            ["<C-k>"] = "move_selection_previous",
            ["<C-n>"] = "cycle_history_next",
            ["<C-p>"] = "cycle_history_prev",
	    ["<C-y>"] = telescope_yank,
	    ["<C-o>"] = telescope_actions.smart_send_to_qflist + telescope_actions.open_qflist,
         },
         n = {
            ["<C-j>"] = "move_selection_next",
            ["<C-k>"] = "move_selection_previous",
	    ["<C-y>"] = telescope_yank,
	    ["<C-o>"] = telescope_actions.smart_send_to_qflist + telescope_actions.open_qflist,
         },
      },
   },
}

telescope.load_extension('fzf')
telescope.load_extension('ui-select')

local telescope_builtin = require('telescope.builtin')


vim.keymap.set('n', '<C-c>pr', telescope_builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<C-c>pf', telescope_builtin.find_files, { desc = 'Telescope find_files' })
vim.keymap.set('n', '<C-c>b', telescope_builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<C-c>pq', telescope_builtin.quickfix, { desc = 'Telescope quickfix' })

-- Which-key
local which_key = require("which-key")

-- Treesitter
require("nvim-treesitter.configs").setup {
   auto_install = false,
   highlight = {
      enable = true,
   },
}

-- Neogit
local neogit = require('neogit')
neogit.setup({
  auto_refresh = true,
})

-- Neogit hijacks ToggleTerm keybinds,
-- so we add it back! I hate everything about this
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'Neogit*',
  callback = function(ev)
    vim.schedule(function()
      vim.keymap.set('n', '<C-t>', '<cmd>ToggleTerm size=40 direction=float<CR>', {
        buffer = ev.buf, desc = 'Floating terminal',
      })
    end)
  end,
})

vim.keymap.set('n', '<C-x>g', neogit.open, { desc = 'NeoGit' })

-- Theme
vim.opt.background = "dark" -- set this to dark or light
vim.cmd("colorscheme oxocarbon")

-- Noice
require("noice").setup({
  messages = {
    enabled = false,
  },
  presets = {
    bottom_search = false,
    command_palette = false,
    long_message_to_split = true,
    inc_rename = false,
    lsp_doc_border = false,
  },
})

-- Snacks
require("snacks").setup({
  opts = {
    -- lazygit = { enabled = true },
    bigfile = { enabled = true },
    quickfile = { enabled = true },
    statuscolumn = { enabled = true },
    bufdelete = { enabled = true },
    gitbrowse = { enabled = true },
  }
})

vim.keymap.set('n', '<C-x>t', function() Snacks.gitbrowse() end, { desc = 'Git in browser' })

local toggleterm = require("toggleterm")

toggleterm.setup({
  float_opts = {
    border = 'curved'
  }
})

vim.keymap.set('n', '<C-t>', "<cmd>ToggleTerm size=40 direction=float<CR>", { desc = 'Floating terminal' })
vim.keymap.set('t', '<C-t>', "<cmd>ToggleTerm size=40 direction=float<CR>", { desc = 'Floating terminal' })

-- Misc

-- This is a collaboration between Alacritty|Tmux|Neovim
-- 1. Tmux ignores Ctrl-Backspace. Solution: remap Ctrl-Backspace to <Esc><DEL> in alacritty.
-- 2. Neovim must now remap <Esc><DEL> to interpret it as Ctrl-Backspace/Ctrl-w
vim.keymap.set("i", "<M-BS>", "<C-w>", { expr = false })
vim.keymap.set("c", "<M-BS>", "<C-w>", { desc = 'Delete word backward' })


-- Better QuickFix lists
require("quicker").setup()
require("bqf").setup({ })


local flash = require("flash")
flash.setup({
  highlight = {
    matches = false,
    multi_label = true,
  }
})
vim.keymap.set("n", "<C-e>", flash.jump, { desc = 'Toggle flash' })

-- Git signs
require('gitsigns').setup({})

-- LSP
vim.lsp.config['elixir_ls'] = {
  cmd = { 'elixir-ls' },
  filetypes = { 'elixir', 'eelixir' },
  root_markers = { '.git' },
}

vim.lsp.enable('elixir_ls')

vim.lsp.enable('org')

require('render-markdown').setup({
    render_modes = true,
})

vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
  pattern = "markdown",
  callback = function()
    -- Force the fold method to use Treesitter expressions
    vim.opt_local.foldmethod = "expr"
    vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    
    -- Keep folds open by default (set to 0 to start collapsed)
    vim.opt_local.foldlevel = 99
    
    -- This 'zx' command forces Neovim to re-scan the folds immediately
    vim.cmd([[normal! zx]])
  end,
})

-- Shared org keybindings (used across org, agenda, capture, and note modes)
local orgkeys = {
  todo        = '<C-c><C-t>',
  deadline    = '<C-c>od',
  schedule    = '<C-c>os',
  priority    = '<C-c>op',
  tags        = '<C-c>ot',
  refile      = '<C-c>or',
  archive     = '<C-c>ox',
  confirm     = '<C-c><C-c>',
  cancel      = '<C-c><C-k>',
  agenda      = '<C-c>a',
  capture     = '<C-c>c',
  open        = '<C-c>oo',
  note        = '<C-c>on',
  insert_link = '<C-c>ol',
  store_link  = '<C-c>oL',
}

require('orgmode').setup({
  org_agenda_files = '~/notes/work/**/*',
  org_agenda_start_on_weekday = false,
  org_agenda_span = 18,
  org_deadline_warning_days = 0,
  org_id_link_to_org_use_id = true,
  org_agenda_prefix_format = {
    agenda = ' %i %-12:c %-30.30b ',
    todo   = ' %i %-12:c %-30.30b ',
  },
  org_default_notes_files = "~/notes/work/inbox.org",
  org_hide_leading_stars = true,
  org_hide_emphasis_markers = true,
  org_todo_keywords = { 'TODO(t)', 'NEXT(n)', 'STARTED(s)', 'WAITING(w)', 'FUTURE(f)', '|', 'DONE(d)', 'CANCELLED(c)' },
  org_startup_folded = "content",
  org_archive_location = "~/notes/work/archive.org",
  win_split_mode = "auto",
  org_capture_templates = {
    a = {
      description = 'Agenda - task',
      template = '* TODO %?\nSCHEDULED: %t',
      target = '~/notes/work/inbox.org',
      headline = 'Tasks',
    },
  },
  org_agenda_custom_commands = {
    o = {
      description = 'Orphan TODOs & FUTURE items',
      types = {
        {
          type = 'tags_todo',
          match = '/TODO|NEXT|STARTED|WAITING',
          org_agenda_todo_ignore_scheduled = 'all',
          org_agenda_todo_ignore_deadlines = 'all',
          org_agenda_overriding_header = 'Orphan TODOs (no schedule/deadline)',
        },
        {
          type = 'tags_todo',
          match = '/FUTURE',
          org_agenda_overriding_header = 'FUTURE items',
        },
      },
    },
  },
  mappings = {
    global = {
      org_agenda = orgkeys.agenda,
      org_capture = orgkeys.capture,
    },
    org = {
      org_next_visible_heading = { '}', '<C-j>' },
      org_previous_visible_heading = { '{', '<C-k>' },
      org_todo = orgkeys.todo,
      org_deadline = orgkeys.deadline,
      org_schedule = orgkeys.schedule,
      org_priority = orgkeys.priority,
      org_add_note = orgkeys.note,
      org_refile = false,
      org_timestamp_down = false,
      org_insert_link = orgkeys.insert_link,
      org_store_link = orgkeys.store_link,
      org_set_tags_command = orgkeys.tags,
      org_open_at_point = orgkeys.open,
      org_archive_subtree = orgkeys.archive,
    },
    capture = {
      org_capture_finalize = orgkeys.confirm,
      org_capture_kill = orgkeys.cancel,
    },
    note = {
      org_note_finalize = orgkeys.confirm,
      org_note_kill = orgkeys.cancel,
    },
    agenda = {
      org_agenda_todo = orgkeys.todo,
      org_agenda_deadline = orgkeys.deadline,
      org_agenda_schedule = orgkeys.schedule,
      org_agenda_priority = orgkeys.priority,
      org_agenda_set_tags = orgkeys.tags,
      org_agenda_refile = orgkeys.refile,
      org_agenda_archive = orgkeys.archive,
    },
  },
})

-- Org agenda which-key group
which_key.add({ '<C-c>o', group = 'Org Agenda Shortcuts' })

-- Custom orgmode extensions (see lua/org_custom.lua)
local org_custom = require('org_custom')
vim.keymap.set('n', '<C-c>or', org_custom.refile, { desc = 'Refile (full path)' })
vim.keymap.set('n', '<C-c>oP', org_custom.set_property, { desc = 'Set property' })
-- vim.keymap.set('n', '<C-c>ol', org_custom.insert_link, { desc = 'Insert link' })

-- Org-roam
require("org-roam").setup({
  directory = "~/notes/work",
  bindings = {
    prefix = "<C-c>n",
  },
  templates = {
    d = {
      description = "default",
      target = "%<%Y%m%d%H%M%S>-%[slug].org",
      template = "%?",
    },
    m = {
      description = "meeting",
      target = "roam/meetings/%<%Y%m%d>-%[slug].org",
      template = "* Attendees\n- %?\n* Agenda\n- \n* Notes\n- \n* Gemini Notes\n* Action Items\n** TODO ",
    },
  },
})

which_key.add({ '<C-c>n', group = 'Org Roam' })
which_key.add({ '<C-c>nd', group = 'Org Roam Dailies' })

-- Forward links in quickfix
vim.keymap.set('n', '<C-c>nQ', function()
  require("org-roam").ui.open_quickfix_list({ links = true, show_preview = true })
end, { desc = 'Quickfix forward links' })

-- C-j/C-k navigation in org-roam select picker
vim.api.nvim_create_autocmd("FileType", {
  pattern = "org-roam-select",
  callback = function(ev)
    vim.keymap.set("i", "<C-j>", "<C-n>", { buffer = ev.buf, remap = true })
    vim.keymap.set("i", "<C-k>", "<C-p>", { buffer = ev.buf, remap = true })
  end,
})

-- Ensure org TODO keywords are visible against headline backgrounds
vim.api.nvim_set_hl(0, '@org.keyword.todo', { fg = '#ee5396', bold = true })
vim.api.nvim_set_hl(0, '@org.keyword.next', { fg = '#ff832b', bold = true })
vim.api.nvim_set_hl(0, '@org.keyword.started', { fg = '#78a9ff', bold = true })
vim.api.nvim_set_hl(0, '@org.keyword.waiting', { fg = '#be95ff', bold = true })
vim.api.nvim_set_hl(0, '@org.keyword.done', { fg = '#42be65', bold = true })
vim.api.nvim_set_hl(0, '@org.keyword.cancelled', { fg = '#565656', bold = true })

require('headlines').setup({
  org = {
    fat_headlines = false,
    headline_highlights = false,
    codeblock_highlight = false,
    dash_highlight = false,
  },
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'org',
  callback = function()
    vim.opt_local.conceallevel = 2
    vim.opt_local.concealcursor = 'nc'
  end,
})

-- Tmux integration
local function smart_move(direction, tmux_cmd)
  local curwin = vim.api.nvim_get_current_win()
  vim.cmd('wincmd ' .. direction)
  if curwin == vim.api.nvim_get_current_win() then
    vim.fn.system('tmux select-pane ' .. tmux_cmd)
  end
end

vim.keymap.set('n', '<C-w>h', function() smart_move('h', '-L') end, {silent = true})
vim.keymap.set('n', '<C-w>j', function() smart_move('j', '-D') end, {silent = true})
vim.keymap.set('n', '<C-w>k', function() smart_move('k', '-U') end, {silent = true})
vim.keymap.set('n', '<C-w>l', function() smart_move('l', '-R') end, {silent = true})
