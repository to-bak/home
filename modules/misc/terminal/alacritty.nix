{ config, pkgs, extendedLib, nixGL, ... }:

with extendedLib;
let 
   cfg = config.modules.misc.terminal.alacritty;
in
{
  options.modules.misc.terminal.alacritty = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      package = config.lib.nixGL.wrap pkgs.alacritty;

      settings = {
        window = {
          title = "Terminal";

          padding = { y = 10; x=10;};
          dimensions = {
            lines = 75;
            columns = 100;
          };
        };

       terminal.shell = { program = "${pkgs.fish}/bin/fish"; };
      };
    };
  };
}
