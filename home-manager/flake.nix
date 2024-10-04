{
  description = "Home Manager configuration";

  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.nixgl.url = "github:nix-community/nixGL";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = inputs@{ nixgl, nixpkgs, home-manager, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ nixgl.overlay ];
        };
        variables = import ./variables.nix;
      in {
        packages.homeConfigurations.${variables.username} =
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;

            modules = [ ./home.nix ];
          };
        packages.bootstrap = pkgs.writeShellApplication {
          name = "bootstrap";
          runtimeInputs = [ pkgs.git ];
          text = ''
            DOT_DIR=$HOME/.dotfiles
            echo "Initializing dotfiles repo: $DOT_DIR" && \
            git clone --bare https://github.com/sindrip/dotfiles.git "$DOT_DIR" && \
            git --git-dir "$DOT_DIR" --work-tree="$HOME" checkout && \
            cd "$HOME"/nix && \
            nix profile install
          '';
        };
      });
}
