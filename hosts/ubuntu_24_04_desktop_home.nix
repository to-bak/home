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

  nixpkgs.config.allowUnfreePredicate = _: true;

  modules.desktop = { 
    i3.enable = true; 
    rofi.enable = true;
    polybar.enable = true;
  };
  modules.editors.neovim.enable = true;

  programs.home-manager.enable = true;
  programs.command-not-found.enable = true;
  programs.ssh.enable = true;
}
