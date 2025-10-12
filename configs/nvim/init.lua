vim.wo.number = true
vim.opt.clipboard:append("unnamedplus")
vim.o.ignorecase = true

-- Telescope
require("telescope").setup
{
   defaults = {
      mappings = {
         i = {
            ["<C-j>"] = "move_selection_next",
            ["<C-k>"] = "move_selection_previous",
            ["<C-n>"] = "cycle_history_next",
            ["<C-p>"] = "cycle_history_prev",
         },
         n = {
            ["<C-j>"] = "move_selection_next",
            ["<C-k>"] = "move_selection_previous",
         },
      },
   },
}

local telescope_builtin = require('telescope.builtin')

vim.keymap.set('n', '<C-c>pr', telescope_builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<C-c>pf', telescope_builtin.find_files, { desc = 'Telescope find_files' })
vim.keymap.set('n', '<C-c>b', telescope_builtin.buffers, { desc = 'Telescope buffers' })

-- Treesitter
require("nvim-treesitter.configs").setup {
   auto_install = false,
   highlight = {
      enable = true,
   },
}

-- Neorg
require("neorg").setup {
   load = {
      ["core.defaults"] = {},
      ["core.concealer"] = {},
      ["core.dirman"] = {
         config = {
            workspaces = {
               personal = "~/personal",
	       work = "~/work",
            },
            default_workspace = "personal",
         },
      },
   },
}

-- Neogit
local neogit = require('neogit')

vim.keymap.set('n', '<C-x>g', neogit.open, { desc = 'Telescope buffers' })

-- Theme
vim.opt.background = "dark" -- set this to dark or light
vim.cmd("colorscheme oxocarbon")


-- Dashboard
require('dashboard').setup {
  theme = "doom",
}
