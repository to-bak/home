{ ... }:

{
  imports = [
    ./auto_include.nix
    ./browser
    ./terminal
    ./shell
    ./fzf.nix
    ./lnav.nix
    ./direnv.nix
    ./ripgrep.nix
    ./kubernetes.nix
  ];
}
