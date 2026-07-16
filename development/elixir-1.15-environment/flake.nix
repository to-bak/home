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

        beam = pkgs.beam.packagesWith pkgs.beam.interpreters.erlang_28;

        erlang = beam.erlang;
        elixir = beam.elixir_1_18;

        elixir-ls = beam.elixir-ls.override {
          inherit elixir;
        };

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
            pkgs.glibcLocales
            pkgs.postgresql
            pkgs.ctags
            pkgs.protobuf
            erlang
            elixir
            elixir-ls
            pkgs.rebar3
          ];
        };

      });
}
