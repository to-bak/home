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
  inputs.emacs-overlay.url = "github:nix-community/emacs-overlay";

  outputs =
    inputs@{
      self,
      nixgl,
      nixpkgs,
      nixpkgs-stable,
      nixpkgs-kubelogin,
      home-manager,
      flake-utils,
      flake-env,
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

      args = { inherit self; inherit (nixpkgs) lib; inherit pkgs; };

      extendedLib = import ./lib args;

      environment = flake-env.nixosModules.${system}.environment;
    in {
      packages.homeConfigurations.${environment.username} =
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./hosts/ubuntu_24_04_desktop_home.nix ];
          extraSpecialArgs = { inherit environment pkgs-stable pkgs-kubelogin extendedLib; };
        };
    });
}
