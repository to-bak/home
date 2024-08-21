{ pkgs, ... }:

{
  programs.emacs = {
    enable = true;
    package = pkgs.emacsUnstable;
    extraPackages = (epkgs: [ epkgs.vterm ] );
  };
}
