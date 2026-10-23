{ pkgs, ... }:

let reveal-js = pkgs.callPackage ./packages/reveal-js.nix { };
in {
  home.packages = [ reveal-js ];
  home.dataFile."reveal.js".source = "${reveal-js}/share/reveal.js";
}
