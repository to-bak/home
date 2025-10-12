{ config, pkgs, pkgs-stable, pkgs-kubelogin, lib, environment, ... }:

{
  imports = [
    ./auto_include.nix
    ./fzf.nix
    ./direnv.nix
    ./ripgrep.nix
  ];
}
