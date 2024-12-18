{
  description = "A devShell example";

  inputs = {
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url  = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
      in
      {
        devShells.default = with pkgs; mkShell rec {
          buildInputs = [
            udev
            alsa-lib
            vulkan-loader
            vulkan-headers
            vulkan-tools
            xorg.libX11
            xorg.libXcursor
            xorg.libXi
            xorg.libXrandr
            libdrm
            libxkbcommon
            wayland
            rust-bin.stable."1.82.0".default
            coreutils
          ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;
        };

      }
    );
}
