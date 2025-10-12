{ config, pkgs, extendedLib, ... }:

with extendedLib;
let 
   cfg = config.modules.misc.shell.fish;
in
{
  options.modules.misc.shell.fish = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    programs.fish = {
      enable = true;
      shellAliases = {
        "nuke" = "docker ps -aq | xargs -r docker stop | xargs docker rm -f";
      };
      interactiveShellInit = ''
      # Fish configuration
      set fish_color_user --bold brgreen
      set fish_greeting ""
      # Fix up nix-env & friends for Nix 2.0
      # export NIX_REMOTE=daemon
    '';
    };

    home.packages = with pkgs; [
      zoxide
    ];

    programs.zoxide = {
      enable = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
    };
  };
}
