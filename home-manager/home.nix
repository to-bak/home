{ config, pkgs, lib, environment, ... }:

{
  home.stateVersion = "22.11";
  home.username = environment.username;
  home.homeDirectory = environment.homeDir;

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    # MISC
    cachix
    appimage-run
    appimagekit
    arandr
    tmate
    networkmanagerapplet
    flameshot
    pavucontrol
    brightnessctl
    pulsemixer
    ripgrep
    autorandr
    jq
    yq-go
    gh
    delta
    kubectl
    kubelogin
    kubectx
    kubernetes-helm
    azure-cli
    nmap
    whois
    tcpdump
    google-chrome

    # TERMINAL
    any-nix-shell
    gotop
    htop
    neofetch
    zip
    unzip
    gnupg
    feh

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
    xclip
    zathura

    #Tilt
    kind
    ctlptl
    tilt

  ];

  imports = [ ./configs/main.nix ];
}
