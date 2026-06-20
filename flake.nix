{
  description = "Home Manager configuration";

  inputs.nixpkgs-emacs.url = "github:nixos/nixpkgs/release-25.11";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/release-25.11";
  inputs.home-manager = {
    url = "github:nix-community/home-manager/release-25.11";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # kubelogin 2.x has a persistent token bug. We revert to 0.1.7 found in nixpkgs: 0bd7f95e4588643f2c2d403b38d8a2fe44b0fc73
  # Found using: https://lazamar.co.uk/nix-versions/?channel=nixpkgs-unstable&package=kubelogin
  inputs.nixpkgs-kubelogin.url = "github:nixos/nixpkgs/0bd7f95e4588643f2c2d403b38d8a2fe44b0fc73";
  # nvim-orgmode 0.7.2+ has cross-file headline link completion and other fixes.
  # release-25.11 only ships 0.7.1, so we pull orgmode from unstable.
  inputs.nixpkgs-orgmode.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.nixGL.url = "github:nix-community/nixGL";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs =
    inputs@{
      self,
      nixGL,
      nixpkgs,
      nixpkgs-emacs,
      nixpkgs-kubelogin,
      nixpkgs-orgmode,
      home-manager,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nixGL.overlay ];
        config.allowUnfree = true;
      };

      pkgs-emacs = import nixpkgs-emacs {
        inherit system;
        config.allowUnfree = true;
      };

      pkgs-kubelogin = import nixpkgs-kubelogin {
        inherit system;
        config.allowUnfree = true;
      };

      pkgs-orgmode = import nixpkgs-orgmode {
        inherit system;
      };

      args = { inherit self; inherit (nixpkgs) lib; inherit pkgs; };

      extendedLib = import ./lib args;

      # Host configs: hosts/hosts.nix maps profile names to filenames.
      # Host files are resolved from the filesystem (requires --impure).
      hostsDir = builtins.getEnv "HOME" + "/.config/home-manager/hosts";
      hostConfigs = builtins.mapAttrs (_: filename:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ (hostsDir + "/${filename}") ];
          extraSpecialArgs = { inherit pkgs-emacs pkgs-kubelogin pkgs-orgmode extendedLib nixGL; };
        }
      ) (import ./hosts/hosts.nix);

    in {
      environment.shells = with pkgs; [ fish ];
      users.defaultUserShell = pkgs.fish;

      packages.homeConfigurations = hostConfigs;

      packages.bootstrap = pkgs.writeShellApplication {
          name = "bootstrap";
          runtimeInputs = [ pkgs.git pkgs.home-manager ];
          text = ''
            DOT_DIR=$HOME/.config/home-manager

            if [ ! -d "$DOT_DIR" ]; then
            echo "==> $DOT_DIR doesn't exist, cloning into $DOT_DIR"
            git clone https://github.com/to-bak/home.git "$DOT_DIR"
            else
            echo "==> $DOT_DIR already exists, proceeding bootstrapping."
            fi

            home-manager switch -b backup --extra-experimental-features 'nix-command flakes'
          '';
        };

    });
}
