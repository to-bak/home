{ config, pkgs, pkgs-stable, lib, environment, ... }:

let
  packages_stable = with pkgs-stable; [
    # MISC
    google-chrome
    cachix
    # appimage-run
    # appimagekit
    arandr

    # SYSTEM
    ripgrep
    autorandr
    networkmanagerapplet
    flameshot
    pavucontrol
    brightnessctl
    pulsemixer

    # DEVELOPMENT
    gnumake
    gdb
    neovim
    emacs29
    nixfmt-classic

    # DEFAULT

    # vlc
    # spotify
    # spotifyd
  ];

  packages_unstable = with pkgs; [
    # MISC
    nmap
    whois
    tcpdump
    xclip
    zathura

    # DEVELOPMENT
    kind
    ctlptl
    tilt
    jq
    yq-go
    gh
    delta
    kubectl
    kubelogin
    kubectx
    kubernetes-helm
    azure-cli

    # TERMINAL
    any-nix-shell
    gotop
    htop
    neofetch
    zip
    unzip
    gnupg
    feh
  ];
in
{
  home.stateVersion = "22.11";
  home.username = environment.username;
  home.homeDirectory = environment.homeDir;

  home.packages = packages_stable ++ packages_unstable;

  imports = [ ./configs/main.nix ];
}
