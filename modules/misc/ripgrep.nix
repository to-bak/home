{ config, pkgs, extendedLib, ... }:

with extendedLib;
let 
   cfg = config.modules.misc.ripgrep;
in
{
  options.modules.misc.ripgrep = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    programs.ripgrep = {
      enable = true;
      arguments = [
        "--hidden"
        "--glob=!.git/*"
      ];
    };
  };
}
