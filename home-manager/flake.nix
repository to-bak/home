{
  description = "Home Manager configuration";

  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.nixgl.url = "github:nix-community/nixGL";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.flake-env.url = "flake:flake-env";

  outputs =
    inputs@{ nixgl, nixpkgs, home-manager, flake-utils, flake-env, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ nixgl.overlay ];
        };
        environment = flake-env.nixosModules.environment;
      in {
        packages.homeConfigurations.${environment.username} =
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [ ./home.nix ];
            extraSpecialArgs = { inherit environment; };
          };
        packages.bootstrap = pkgs.writeShellApplication {
          name = "bootstrap";
          runtimeInputs = [ pkgs.git pkgs.home-manager ];
          text = ''
            DOT_DIR=$HOME/.dotfiles
            ENV_DIR=$HOME/.flake-env
            if [ -d "$ENV_DIR" ]; then
              echo "BOOTSTRAPPING" && \
              git clone https://github.com/to-bak/home.git "$DOT_DIR" && \
              ln -sfn "$DOT_DIR"/home-manager "$HOME"/.config/home-manager && \
              ln -sfn "$DOT_DIR"/nix "$HOME"/.config/nix && \
              ln -sfn "$DOT_DIR"/autorandr "$HOME"/.config/autorandr && \
              ln -sfn "$DOT_DIR"/.emacs.d "$HOME"/.emacs.d && \
              ln -sfn "$DOT_DIR"/.profile "$HOME"/.profile && \
              cd "$DOT_DIR"/home-manager && \
              nix flake lock --update-input flake-env && \
              home-manager switch
            else
              echo "Failed to bootstrap. Error: flake-env not found, see README.md"
            fi
          '';
        };
      });
}
