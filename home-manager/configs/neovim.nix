{ config, pkgs-stable, lib, environment, ... }:

{
  programs.neovim.enable = true;

  programs.neovim.plugins = with pkgs-stable; [
    vimPlugins.nvim-treesitter.withAllGrammars
    vimPlugins.nvim-treesitter
    vimPlugins.telescope-nvim
    vimPlugins.telescope-project-nvim
    vimPlugins.neorg
    vimPlugins.neogit
    vimPlugins.oxocarbon-nvim
    vimPlugins.dashboard-nvim
  ];

  programs.neovim.extraPackages = with pkgs-stable; [
    tree-sitter
    tree-sitter-grammars.tree-sitter-norg
    tree-sitter-grammars.tree-sitter-norg-meta
  ];

  home.file = {
    ".config/nvim" = {
      source = ../../neovim;
      recursive = true;
    };
  };
}
