{ config, pkgs, extendedLib, ... }:

with extendedLib;
let
   cfg = config.modules.misc.syncthing;
in
{
  options.modules.misc.syncthing = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.syncthing.enable = true;
  };
}
