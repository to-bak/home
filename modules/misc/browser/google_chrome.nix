{ config, pkgs, extendedLib, ... }:

with extendedLib;
let 
   cfg = config.modules.misc.browser.google_chrome;
in
{
  options.modules.misc.browser.google_chrome = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
      home.packages = with pkgs; [
        google-chrome
      ];
  };
}
