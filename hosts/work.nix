{
  config,
  extendedLib,
  pkgs,
  nixGL,
  ...
}:

with extendedLib;
{
  imports = [
    ../modules/home.nix
    # Uncomment modules as needed:
    # ../modules/desktop
    # ../modules/services
    # ../modules/editors
    ../modules/misc
  ];

  # Identity is read from the environment at build time (requires --impure).
  # Run: home-manager switch --flake .#work --impure
  home.username    = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";
  home.stateVersion = "23.11";

  nixpkgs.config.allowUnfreePredicate = _: true;

  # Add work-specific packages here:
  # home.packages = with pkgs; [ ];

  # Add work-specific module configuration here:
  modules.misc = {
    direnv.enable = true;
    shell.fish.enable = true;
  };

  programs.home-manager.enable = true;
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
  };
}
