return {
    { 'nvim-telescope/telescope.nvim', tag = '0.1.8',
      dependencies = { 'nvim-lua/plenary.nvim' },
      keys = {
         {"<C-c>pr", function() require("telescope.builtin").live_grep() end, desc = "telescope ripgrep"},
         {"<C-c>pf", function() require("telescope.builtin").find_files() end, desc = "telescope find_files"},
         {"<C-x>b", function() require("telescope.builtin").buffers() end, desc = "telescope buffers"},
      },
      config = function()
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
      end
    },
    {
       'nvim-telescope/telescope-project.nvim',
       dependencies = {
          'nvim-telescope/telescope.nvim',
       },
       keys = {
          {"<C-c>pp", function() require("telescope").extensions.project.project{} end, desc = "Telescope projects"}
       }
    },
    {
       "nvim-telescope/telescope-file-browser.nvim",
       dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
       keys = {
          {"<C-c><C-f>", function() require("telescope").extensions.file_browser.file_browser() end , desc = "File browser" }
       },
       config = function()
          require("telescope").setup
          {
             extensions = {
                file_browser = {
                   theme = "ivy",
                   cwd_to_path = true,
                },
             },
          }
       end
    }
}
