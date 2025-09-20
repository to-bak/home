{
  description = "Home Manager configuration";

  inputs.nixpkgs-stable.url = "github:nixos/nixpkgs";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  # kubelogin 2.x has a persistent token bug. We revert to 0.1.7 found in nixpkgs: 0bd7f95e4588643f2c2d403b38d8a2fe44b0fc73
  # Found using: https://lazamar.co.uk/nix-versions/?channel=nixpkgs-unstable&package=kubelogin
  inputs.nixpkgs-kubelogin.url = "github:nixos/nixpkgs/0bd7f95e4588643f2c2d403b38d8a2fe44b0fc73";
  inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.nixgl.url = "github:nix-community/nixGL";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.flake-env.url = "flake:flake-env";
  inputs.stylix.url = "github:danth/stylix";
  inputs.emacs-overlay.url = "github:nix-community/emacs-overlay";

  outputs =
    inputs@{
      nixgl,
      nixpkgs,
      nixpkgs-stable,
      nixpkgs-kubelogin,
      home-manager,
      flake-utils,
      flake-env,
      stylix,
      emacs-overlay,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nixgl.overlay ];
        config.allowUnfree = true;
      };

      pkgs-stable = import nixpkgs-stable {
        inherit system;
        overlays = [ nixgl.overlay emacs-overlay.overlay ];
        config.allowUnfree = true;
      };

      pkgs-kubelogin = import nixpkgs-kubelogin {
        inherit system;
        config.allowUnfree = true;
      };

      environment = flake-env.nixosModules.${system}.environment;
    in {
      packages.homeConfigurations.${environment.username} =
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home.nix stylix.homeManagerModules.stylix ];
          extraSpecialArgs = { inherit environment pkgs-stable pkgs-kubelogin; };
        };
        packages.bootstrap = pkgs.writeShellApplication {
          name = "bootstrap";
          runtimeInputs = [ pkgs.git pkgs.home-manager ];
          text = ''
            DOT_DIR=$HOME/.dotfiles
            ENV_DIR=$HOME/.flake-env

            if [ ! -d "$DOT_DIR" ]; then
            echo "==> .dotfiles doesn't exist, cloning into ~/.dotfiles"
            git clone https://github.com/to-bak/home.git "$DOT_DIR"
            else
            echo "==> ~/.dotfiles already exists, proceeding bootstrapping."
            fi

            if [ -d "$ENV_DIR" ]; then
            echo "mkdir -p ~/.config/nix if not exists" && \
            mkdir -p "$HOME"/.config/nix && \
            echo "==> linking static configs to approriate files" && \
            ln -sfn "$DOT_DIR"/home-manager "$HOME"/.config/home-manager && \
            ln -sfn "$DOT_DIR"/nix.conf "$HOME"/.config/nix/nix.conf && \
            ln -sfn "$DOT_DIR"/autorandr "$HOME"/.config/autorandr && \
            ln -sfn "$DOT_DIR"/.emacs.d "$HOME"/.emacs.d && \
            ln -sfn "$DOT_DIR"/neovim "$HOME"/.config/nvim && \
            ln -sfn "$DOT_DIR"/.profile "$HOME"/.profile && \
            echo "==> updating flake-env to reflect local environment" && \
            cd "$DOT_DIR"/home-manager && \
            nix flake lock --update-input flake-env && \
            echo "==> applying home-manager switch" && \
            home-manager switch
            else
            echo "Failed to bootstrap. Error: flake-env not found, see README.md"
            fi
          '';
        };
    });
}
