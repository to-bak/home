return {
    { 'nvim-telescope/telescope.nvim', tag = '0.1.8',
      dependencies = { 'nvim-lua/plenary.nvim' },
      keys = {
         {"<C-c>pr", function() require("telescope.builtin").live_grep() end, desc = "telescope ripgrep"},
         {"<C-x>b", function() require("telescope.builtin").buffers() end, desc = "telescope buffers"},
      }
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
          {"<C-x><C-f>", function() require("telescope").extensions.file_browser.file_browser() end , desc = "File browser" }
       },
       config = function() require("telescope").setup {extensions = {file_browser = {cwd_to_path = true,},},} end
    }
}
