{ config, pkgs-stable, extendedLib, ... }:

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

    programs.neovim.plugins = with pkgs-stable; [
      vimPlugins.nvim-treesitter.withAllGrammars
      vimPlugins.nvim-treesitter
      vimPlugins.telescope-nvim
      vimPlugins.telescope-fzf-native-nvim
      vimPlugins.neorg
      vimPlugins.neogit
      vimPlugins.oxocarbon-nvim
      vimPlugins.dashboard-nvim
      vimPlugins.noice-nvim
      vimPlugins.snacks-nvim
      vimPlugins.toggleterm-nvim
      vimPlugins.nvim-bqf
      vimPlugins.fzf-vim
    ];

    programs.neovim.extraPackages = with pkgs-stable; [
      tree-sitter
      tree-sitter-grammars.tree-sitter-norg
      tree-sitter-grammars.tree-sitter-norg-meta
    ];

    home.packages = with pkgs-stable; [
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
