# https://github.com/NixOS/nixpkgs/pull/277180
{
  description = "Elixir development flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
        elixir = pkgs.beam.packages.erlang_27.elixir_1_17;
        beamPkg = pkgs.beam.packagesWith pkgs.erlang_27;
        elixir-ls = (beamPkg.elixir-ls.override {
          mixRelease = beamPkg.mixRelease.override { elixir = elixir; };
        });
      in {

        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.gnumake
            pkgs.gcc
            pkgs.readline
            pkgs.openssl
            pkgs.zlib
            pkgs.libxml2
            pkgs.curl
            pkgs.libiconv
            elixir
            elixir-ls
            pkgs.rebar3
            pkgs.glibcLocales
            pkgs.ctags
            pkgs.protobuf
            pkgs.erlang
          ];

          LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
          PATH = "~/.mix/escripts:$PATH";
        };

      });
}
