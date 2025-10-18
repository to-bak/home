{ config, pkgs, extendedLib, nixGL, ... }:

with extendedLib;
let 
   cfg = config.modules.misc.terminal.kitty;
in
{
  options.modules.misc.terminal.kitty = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    programs.kitty = {
      enable = true;
      package = config.lib.nixGL.wrap pkgs.kitty;

      shellIntegration.enableFishIntegration = true;

    };

    home.configFile."kitty" = {
      source = ../../../configs/kitty;
      recursive = true;
    };
  };
}
