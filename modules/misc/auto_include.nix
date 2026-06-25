{ pkgs, ... }:
let
  tex = pkgs.texlive.combine {
    inherit (pkgs.texlive)
      scheme-medium               # Your base engine and standard tools
      collection-latexextra       # Thousands of extra packages (includes wrapfig, rotating, capt-of, ulem)
      collection-fontsrecommended # Standard widely-used fonts
      collection-mathscience;     # Everything you need for math, physics, and computer science
  };
in
{
  home.packages = with pkgs; [
    # MISC
    tex
    cachix
    networkmanagerapplet
    flameshot
    gnumake
    gdb
    nixfmt-classic
    git
    nmap
    awscli
    whois
    tcpdump
    xclip
    zathura
    jq
    yq-go
    go-jsonnet
    jsonnet-bundler
    gh
    delta
    websocat
    any-nix-shell
    gotop
    htop
    zip
    unzip
    gnupg
    lazygit
    lazydocker
    mscgen
  ];
}
