{ pkgs, ... }:

with pkgs;
let
  default-python = python3.withPackages (python-packages:
    with python-packages; [
      pip
      black
      flake8
      setuptools
      wheel
      twine
      flake8
      virtualenv
    ]);

  tex = (pkgs.texlive.combine {
    inherit (pkgs.texlive) scheme-full;
    });

in {
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

    # DEFAULT

    vlc
    # spotify
    # spotifyd
    zathura

    # PLANTUML
    jdk11
    graphviz

    #Latex Full package
    tex

    #Tilt
    kind
    ctlptl
    tilt

  ];

}
