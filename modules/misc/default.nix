{ ... }:

{
  imports = [
    ./auto_include.nix
    ./browser
    ./terminal
    ./shell
    ./fzf.nix
    ./direnv.nix
    ./ripgrep.nix
    ./reveal.nix
    ./kubernetes.nix
  ];
}
