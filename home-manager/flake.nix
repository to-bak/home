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
    homeConfigurations.${variables.username} = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      modules = [ ./home.nix ];

    };
  };
}
