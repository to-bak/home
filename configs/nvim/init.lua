vim.wo.number = true
vim.opt.clipboard:append("unnamedplus")
vim.o.ignorecase = true

-- Telescope
local telescope = require('telescope')
local telescope_actions = require('telescope.actions')

telescope.setup
{
   defaults = {
      mappings = {
         i = {
            ["<C-j>"] = "move_selection_next",
            ["<C-k>"] = "move_selection_previous",
            ["<C-n>"] = "cycle_history_next",
            ["<C-p>"] = "cycle_history_prev",
	    ["<C-o>"] = telescope_actions.smart_send_to_qflist + telescope_actions.open_qflist,
         },
         n = {
            ["<C-j>"] = "move_selection_next",
            ["<C-k>"] = "move_selection_previous",
	    ["<C-o>"] = telescope_actions.smart_send_to_qflist + telescope_actions.open_qflist,
         },
      },
   },
}

telescope.load_extension('fzf')

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
local neorg_builtin = require("neorg")

neorg_builtin.setup {
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

vim.keymap.set('n', '<C-c><C-t>', "<Plug>(neorg.qol.todo-items.todo.task-cycle)", { desc = 'cycle todo item' })


-- Neogit
local neogit = require('neogit')

-- vim.keymap.set('n', '<C-x>g', neogit.open, { desc = 'Telescope buffers' })

-- Theme
vim.opt.background = "dark" -- set this to dark or light
vim.cmd("colorscheme oxocarbon")


-- Dashboard
require('dashboard').setup {
  theme = "doom",
}

-- Noice
require("noice").setup({
  lsp = {
    -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
    override = {
      ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true,
      -- ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
    },
  },
  -- you can enable a preset for easier configuration
  presets = {
    bottom_search = false, -- use a classic bottom cmdline for search
    command_palette = false, -- position the cmdline and popupmenu together
    long_message_to_split = true, -- long messages will be sent to a split
    inc_rename = false, -- enables an input dialog for inc-rename.nvim
    lsp_doc_border = false, -- add a border to hover docs and signature help
  },
})

-- Snacks
require("snacks").setup({
  opts = {
    lazygit = { }
  }
})

vim.keymap.set('n', '<C-x>g', function() Snacks.lazygit() end, { desc = 'Lazygit' })

local toggleterm = require("toggleterm")
toggleterm.setup({
  size = 20
})

vim.keymap.set('n', '<C-t>', "<cmd>ToggleTerm size=40 direction=float<CR>", { desc = 'Floating terminal' })
vim.keymap.set('t', '<C-t>', "<cmd>ToggleTerm size=40 direction=float<CR>", { desc = 'Floating terminal' })

-- Misc

-- This is a collaboration between Alacritty|Tmux|Neovim
-- 1. Tmux ignores Ctrl-Backspace. Solution: remap Ctrl-Backspace to <Esc><DEL> in alacritty.
-- 2. Neovim must now remap <Esc><DEL> to interpret it as Ctrl-Backspace/Ctrl-w
vim.keymap.set("i", "<M-BS>", "<C-w>", { expr = false })


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

