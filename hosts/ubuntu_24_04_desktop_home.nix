{
  config,
  extendedLib,
  pkgs,
  nixpkgs,
  ...
}:

with extendedLib;
let
  cfg = config.home;
  lib = extendedLib;
in
{
  imports = [
    ../modules/home.nix
    ../modules/desktop
    ../modules/services
    ../modules/editors
    ../modules/misc
  ];

  home.username = "oliverbak";
  home.homeDirectory = "/home/oliverbak";
  home.stateVersion = "23.11";

  home.packages = with pkgs; [
    nixgl.nixGLIntel
  ];

  nixpkgs.config.allowUnfreePredicate = _: true;

  modules.desktop = { 
    i3.enable = true; 
    rofi.enable = true;
    polybar.enable = true;
    compton.enable = true;
  };

  modules.editors.neovim.enable = true;
  modules.services.dunst.enable = true;

  modules.misc = {
    direnv.enable = true;
    fzf.enable = true;
    kubernetes.enable = true;
    ripgrep.enable = true;
    shell.fish.enable = true;
    browser.google_chrome.enable = true;
    terminal.alacritty.enable = true;
  };

  home.file.".config/nix/" = {
    source = ../configs/nix;
    recursive = true;
  };

  programs.home-manager.enable = true;
  programs.command-not-found.enable = true;
  programs.ssh.enable = true;
}
