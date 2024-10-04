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
            extraSpecialArgs = { inherit variables; };
          };
        packages.bootstrap = pkgs.writeShellApplication {
          name = "bootstrap";
          runtimeInputs = [ pkgs.git pkgs.home-manager ];
          text = ''
          echo "$GITHUB_GHP"
          DOT_DIR=$HOME/.dotfiles
          git clone https://github.com/to-bak/home.git "$DOT_DIR" && \
          cp "$HOME/variables.nix" "$DOT_DIR"/home-manager/variables.nix && \
          rm "$HOME"/variables.nix && \
          ln -sfn "$DOT_DIR"/home-manager "$HOME"/.config/home-manager && \
          ln -sfn "$DOT_DIR"/nix "$HOME"/.config/nix && \
          ln -sfn "$DOT_DIR"/autorandr "$HOME"/.config/autorandr && \
          ln -sfn "$DOT_DIR"/.emacs.d "$HOME"/.emacs.d && \
          ln -sfn "$DOT_DIR"/.profile "$HOME"/.profile && \
          home-manager switch
          '';
        };
      });
}
