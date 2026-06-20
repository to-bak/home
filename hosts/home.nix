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
    ../modules/desktop
    ../modules/services
    ../modules/editors
    ../modules/misc
  ];

  # Identity is read from the environment at build time (requires --impure).
  # This avoids hardcoding personal details in the repo.
  home.username    = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";
  home.stateVersion = "23.11";

  home.packages = with pkgs; [
    nixgl.nixGLIntel
  ];

  targets.genericLinux.nixGL = {
    packages = nixGL.packages; # you must set this or everything will be a noop
    defaultWrapper = "mesa"; # choose from options
    installScripts = ["mesa"];
    vulkan.enable = false;
  };

  nixpkgs.config.allowUnfreePredicate = _: true;

  modules.desktop = {
    i3.enable = true;
    rofi.enable = true;
    polybar.enable = true;
    compton.enable = true;
  };

  modules.editors.neovim.enable = true;
  modules.editors.emacs.enable = true;
  modules.services.dunst.enable = true;

  modules.misc = {
    direnv.enable = true;
    fzf.enable = true;
    kubernetes.enable = true;
    ripgrep.enable = true;
    shell.fish.enable = true;
    browser.chromium.enable = true;
    terminal.alacritty.enable = true;
    terminal.tmux = {
      enable = true;
      sessionizer = {
        shallowDirs = [
          "$HOME/notes/"
        ];
        deepDirs = [
          "$HOME/git"
        ];
      };
    };
  };

  home.file.".config/nix/" = {
    source = ../configs/nix;
    recursive = true;
  };

  programs.home-manager.enable = true;
  programs.command-not-found.enable = true;
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
  };
}
