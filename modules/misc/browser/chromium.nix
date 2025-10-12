{ config, pkgs, extendedLib, ... }:

with extendedLib;
let 
   cfg = config.modules.misc.browser.chromium;
in
{
  options.modules.misc.browser.chromium = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
      programs.chromium = {
        enable = true;
	commandLineArgs = [
	  "--no-sandbox"
	];
      };
  };
}
