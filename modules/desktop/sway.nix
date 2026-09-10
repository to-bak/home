{ config, pkgs, extendedLib, ... }:

with extendedLib;
let cfg = config.modules.desktop.sway;
in {
  options.modules.desktop.sway.enable = mkBoolOpt false;

  config = mkIf cfg.enable {
    wayland.windowManager.sway = {
      enable = true;
      config = null;
      xwayland = true;
      systemd.enable = true;
      extraSessionCommands = ''
        export MOZ_ENABLE_WAYLAND=1
        export NIXOS_OZONE_WL=1
        export QT_QPA_PLATFORM="wayland;xcb"
        export SDL_VIDEODRIVER=wayland,x11
        export XDG_CURRENT_DESKTOP=sway
        export XDG_SESSION_DESKTOP=sway
        export XDG_SESSION_TYPE=wayland
      '';
      extraConfig = builtins.replaceStrings [ "@wallpaper@" ]
        [ "${../../wallpapers/nord_dark_city.png}" ]
        (builtins.readFile ../../configs/sway/config);
    };

    services.swayidle = {
      enable = true;
      systemdTarget = "sway-session.target";
      events = [
        {
          event = "before-sleep";
          command = "/usr/bin/swaylock -f -c 000000";
        }
        {
          event = "lock";
          command = "/usr/bin/swaylock -f -c 000000";
        }
      ];
    };

    home.packages = with pkgs; [
      brightnessctl
      grim
      jq
      kanshi
      pulsemixer
      slurp
      swappy
      wl-clipboard
      wmenu
    ];

    home.configFile."xdg-desktop-portal/portals.conf".source =
      ../../configs/xdg-desktop-portal/portals.conf;
  };
}
