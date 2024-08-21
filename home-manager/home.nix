{ config, pkgs, lib, ... }:
let
  variables = import ./variables.nix;
in
{
  home.stateVersion = "22.11";
  home.username = variables.username;
  home.homeDirectory = variables.homeDir;

  imports = [ ./configs/main.nix ./packages/main.nix ];

  services.emacs.enable = true;
}
