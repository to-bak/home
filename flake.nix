{
  description = "Environment flake";

  outputs = { ... }: {
    nixosModules = { environment = import ./environment.nix; };
  };
}
