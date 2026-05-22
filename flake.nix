{
  description = "Home Manager configuration";

  inputs.nixpkgs-stable.url = "github:nixos/nixpkgs";
  # both references of nixpkgs and home-manager are taken from August 2025.
  # It is important that nixpkgs and home-manager match from same release ish.
  # tmux + sesh has a bug, which prevents me from making this rolling right now.
  # inputs.nixpkgs.url = "github:nixos/nixpkgs/257a9da3736e03e3421ffefb5d125d2047dfaca9";
  # inputs.home-manager = {
  #   url = "github:nix-community/home-manager/6911d3e7f475f7b3558b4f5a6aba90fa86099baa";
  #   inputs.nixpkgs.follows = "nixpkgs";
  # };
  # inputs.neovim-pkgs.url = ""

  inputs.nixpkgs.url = "github:nixos/nixpkgs/release-25.11";
  inputs.home-manager = {
    url = "github:nix-community/home-manager/release-25.11";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # kubelogin 2.x has a persistent token bug. We revert to 0.1.7 found in nixpkgs: 0bd7f95e4588643f2c2d403b38d8a2fe44b0fc73
  # Found using: https://lazamar.co.uk/nix-versions/?channel=nixpkgs-unstable&package=kubelogin
  inputs.nixpkgs-kubelogin.url = "github:nixos/nixpkgs/0bd7f95e4588643f2c2d403b38d8a2fe44b0fc73";
  # sesh is broken on newer nixpkgs.
  inputs.nixpkgs-sesh.url = "github:nixos/nixpkgs/257a9da3736e03e3421ffefb5d125d2047dfaca9";
  # nvim-orgmode 0.7.2+ has cross-file headline link completion and other fixes.
  # release-25.11 only ships 0.7.1, so we pull orgmode from unstable.
  inputs.nixpkgs-orgmode.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.nixGL.url = "github:nix-community/nixGL";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.emacs-overlay.url = "github:nix-community/emacs-overlay";

  outputs =
    inputs@{
      self,
      nixGL,
      nixpkgs,
      nixpkgs-stable,
      nixpkgs-kubelogin,
      nixpkgs-sesh,
      nixpkgs-orgmode,
      home-manager,
      flake-utils,
      emacs-overlay,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nixGL.overlay ];
        config.allowUnfree = true;
      };

      pkgs-stable = import nixpkgs-stable {
        inherit system;
        overlays = [ nixGL.overlay emacs-overlay.overlay ];
        config.allowUnfree = true;
      };

      pkgs-kubelogin = import nixpkgs-kubelogin {
        inherit system;
        config.allowUnfree = true;
      };

      pkgs-sesh = import nixpkgs-sesh {
        inherit system;
        config.allowUnfree = true;
      };

      pkgs-orgmode = import nixpkgs-orgmode {
        inherit system;
      };

      args = { inherit self; inherit (nixpkgs) lib; inherit pkgs; };

      extendedLib = import ./lib args;

      # Local (gitignored) host configurations loaded via --impure.
      # Defined in hosts/local.nix as { configName = [ ./module.nix ]; }
      localConfigPath = builtins.getEnv "HOME" + "/.config/home-manager/hosts/local.nix";
      localHosts =
        if builtins.pathExists localConfigPath
        then builtins.mapAttrs (_: modules:
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            inherit modules;
            extraSpecialArgs = { inherit pkgs-stable pkgs-kubelogin pkgs-sesh pkgs-orgmode extendedLib nixGL; };
          }
        ) (import localConfigPath)
        else {};

    in {
      environment.shells = with pkgs; [ fish ];
      users.defaultUserShell = pkgs.fish;

      packages.homeConfigurations = {
        oliverbak =
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [ ./hosts/ubuntu_24_04_desktop_home.nix ];
            extraSpecialArgs = { inherit pkgs-stable pkgs-kubelogin pkgs-sesh pkgs-orgmode extendedLib nixGL; };
          };
      } // localHosts;

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
