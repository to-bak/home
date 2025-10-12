{ config, pkgs, extendedLib, ... }:

with extendedLib;
let 
   cfg = config.modules.misc.direnv;
in
{
  options.modules.misc.direnv = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
