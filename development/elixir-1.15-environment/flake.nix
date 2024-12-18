# https://github.com/NixOS/nixpkgs/pull/277180
{
  description = "Elixir development flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        elixir = pkgs.beam.packages.erlang_26.elixir_1_15;
        beamPkg = pkgs.beam.packagesWith pkgs.erlang_26;
        elixir-ls = (beamPkg.elixir-ls.override {
          mixRelease = beamPkg.mixRelease.override { elixir = elixir; };
        });
      in {

        devShells.default = with pkgs;
          mkShell {
            buildInputs = [
              gnumake
              gcc
              readline
              openssl
              zlib
              libxml2
              curl
              libiconv
              elixir
              elixir-ls
              rebar3
              glibcLocales
              postgresql
              ctags
              protobuf
              erlang
            ];
          };

      });
}
