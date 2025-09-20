# https://github.com/NixOS/nixpkgs/pull/277180
{
  description = "A devShell example";

  inputs = {
    nixpkgs.url      = "github:nixos/nixpkgs";
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
          nativeBuildInputs = [
            pkg-config
          ];
          buildInputs = [
            rust-bin.stable."1.86.0".default
            protobuf
            srtp
            clang
            libclang
            rust-analyzer
            go
            cmake
          ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;
        };

      }
    );
}
