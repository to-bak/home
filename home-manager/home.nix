 config, pkgs, lib, environment, ... }:

{
  home.stateVersion = "22.11";
  home.username = environment.username;
  home.homeDirectory = environment.homeDir;

  home.packages = with pkgs; [
    # MISC
    cachix
    appimage-run
    appimagekit
    arandr
    tmate
    flameshot
    pavucontrol
    brightnessctl
    pulsemixer
    ripgrep
    direnv
    autorandr
    jq
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

    vlc
    # spotify
    # spotifyd
    zathura

    #Tilt
    kind
    ctlptl
    tilt

  ];

  imports = [ ./configs/main.nix ];
}
