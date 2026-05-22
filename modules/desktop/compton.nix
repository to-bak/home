{ config, pkgs, extendedLib, ... }:

with extendedLib;
let 
   cfg = config.modules.desktop.compton;
in
{
  options.modules.desktop.compton = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.picom = {
      enable = true;

      activeOpacity = 0.96;
      inactiveOpacity = 0.86;
      opacityRules = [
        "100:class_g = 'Chromium-browser'"
        "100:class_g = 'Google-chrome'"
        "100:class_g = 'Spotify'"
        "100:class_g = 'discord'"
      ];

      menuOpacity = 0.8;
      vSync = true;
      settings = {
        frame-opacity = 0.7;
        blur-method = "dual_kawase";
        blur-strength = 1;
        alpha-step = 0.06;
        corner-radius = 8.0;
        round-borders = 1;
        detect-client-opacity = true;
        detect-rounded-corners = true;
        paint-on-overlay = true;
        detect-transient = true;
        mark-wmwin-focused = true;
        mark-ovredir-focused = true;
      };
    };
  };
}
