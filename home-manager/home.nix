{ config, pkgs, pkgs-stable, pkgs-kubelogin, lib, environment, ... }:

let
  packages_stable = with pkgs-stable; [
    # MISC
    firefox
    cachix
    # appimage-run
    # appimagekit
    arandr

    # SYSTEM
    autorandr
    networkmanagerapplet
    flameshot
    pavucontrol
    brightnessctl
    pulsemixer
    texlive.combined.scheme-full

    # DEVELOPMENT
    gnumake
    gdb
    nixfmt-classic
    emacs-git

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
    neovim
    luarocks
    lua5_1
    # google-chrome

    # DEVELOPMENT
    kind
    ctlptl
    tilt
    jq
    yq-go
    gh
    delta
    kubectl
    kubectx
    kubernetes-helm
    azure-cli
    websocat

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

  packages_kubelogin = with pkgs-kubelogin; [
    kubelogin
  ];
in
{
  home.stateVersion = "22.11";
  home.username = environment.username;
  home.homeDirectory = environment.homeDir;

  home.packages = packages_stable ++ packages_unstable ++ packages_kubelogin;

  imports = [ ./configs/main.nix ];
}
