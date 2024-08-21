# credits: @LightDiscord who helped me to update to picom
{ pkgs, ... }:

{
  services.picom = {
    enable = true;

    activeOpacity = 0.94;
    inactiveOpacity = 0.86;
    opacityRules = [
           "100:class_g = 'Chromium-browser'"
           "100:class_g = 'Google-chrome'"
           "100:class_g = 'Spotify'"
           "100:class_g = 'discord'"];
    menuOpacity = 0.8;

    vSync = true;

    settings = {
      frame-opacity = 0.7;
      blur-method = "dual_kawase";
      blur-strength = 1;
      alpha-step = 0.06;
      detect-client-opacity = true;
      detect-rounded-corners = true;
      paint-on-overlay = true;
      detect-transient = true;
      mark-wmwin-focused = true;
      mark-ovredir-focused = true;
    };
  };
}
