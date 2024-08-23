{
  description = "Home Manager configuration";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
  inputs.home-manager = {
    url = "github:nix-community/home-manager/release-23.11";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.nixgl.url = "github:nix-community/nixGL";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = inputs@{ nixgl, nixpkgs, home-manager, flake-utils, ... }:
  let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      overlays = [ nixgl.overlay ];
    };
    variables = import ./variables.nix;
  in {
    packages.bootstrap = pkgs.writeShellApplication {
      name = "bootstrap";
      runtimeInputs = [ pkgs.git ];
      text = ''
        echo "Initializing dotfiles repo: $HOME/.cfg/" && \
        git clone --bare https://github.com/SamWolfs/dotfiles-v2.git $HOME/.cfg/ && \
        git --git-dir=$HOME/.cfg/ --work-tree=$HOME checkout && \
        cd $HOME/nix && \
        nix profile install
          '';
    };

    homeConfigurations.${variables.username} = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      modules = [ ./home.nix ];

    };

    packages.bootstrap = pkgs.writeShellApplication {
      name = "bootstrap";
      runtimeInputs = [ pkgs.git ];
      text = ''
        DOT_DIR=$HOME/.home
        echo "Initializing dotfiles repo: $DOT_DIR" && \
        git clone --bare https://github.com/to-bak/home.git $DOT_DIR && \
        git --git-dir $DOT_DIR --work-tree=$HOME checkout && \
        cd $HOME/nix
      '';
    };
  };

}
