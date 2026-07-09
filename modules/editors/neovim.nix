{ config, pkgs, pkgs-orgmode, extendedLib, ... }:

with extendedLib;
let 
   cfg = config.modules.editors.neovim;
in
{

  options.modules.editors.neovim = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    programs.neovim.enable = true;

    programs.neovim.plugins = with pkgs; [
      vimPlugins.nvim-treesitter
      vimPlugins.nvim-treesitter.withAllGrammars
      vimPlugins.telescope-nvim
      vimPlugins.telescope-fzf-native-nvim
      vimPlugins.telescope-ui-select-nvim
      vimPlugins.neorg
      vimPlugins.neogit
      vimPlugins.oxocarbon-nvim
      vimPlugins.noice-nvim
      vimPlugins.snacks-nvim
      vimPlugins.toggleterm-nvim
      vimPlugins.nvim-bqf
      vimPlugins.fzf-vim
      vimPlugins.quicker-nvim
      vimPlugins.flash-nvim
      vimPlugins.gitsigns-nvim
      vimPlugins.plenary-nvim
      vimPlugins.which-key-nvim
      vimPlugins.render-markdown-nvim
      pkgs-orgmode.vimPlugins.orgmode
      pkgs-orgmode.vimPlugins.org-roam-nvim
      vimPlugins.headlines-nvim
    ];

    programs.neovim.extraPackages = with pkgs; [
      tree-sitter
    ];

    home.packages = with pkgs; [
      luarocks
      lua5_1
    ];

    home.file = {
      ".config/nvim" = {
        source = ../../configs/nvim;
        recursive = true;
      };
    };
  };
}
