{ config, pkgs, extendedLib, ... }:

with extendedLib;
let cfg = config.modules.desktop.sway;
in {
  options.modules.desktop.sway.enable = mkBoolOpt false;

  config = mkIf cfg.enable {
    wayland.windowManager.sway = {
      enable = true;
      package = config.lib.nixGL.wrap pkgs.sway;
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

    systemd.user.services.sway-opacity = {
      Unit = {
        Description = "Apply focused and unfocused Sway window opacity";
        PartOf = [ "sway-session.target" ];
        After = [ "sway-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Service = {
        ExecStart = "${../../scripts/sway-opacity}";
        Environment = [
          "PATH=${pkgs.lib.makeBinPath [ pkgs.sway pkgs.jq ]}"
        ];
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install.WantedBy = [ "sway-session.target" ];
    };

    systemd.user.services.cliphist-text = {
      Unit = {
        Description = "Store Wayland text clipboard history";
        PartOf = [ "sway-session.target" ];
        After = [ "sway-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Service = {
        ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install.WantedBy = [ "sway-session.target" ];
    };

    systemd.user.services.cliphist-image = {
      Unit = {
        Description = "Store Wayland image clipboard history";
        PartOf = [ "sway-session.target" ];
        After = [ "sway-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Service = {
        ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install.WantedBy = [ "sway-session.target" ];
    };

    home.packages = with pkgs; [
      brightnessctl
      cliphist
      grim
      jq
      kanshi
      pulsemixer
      slurp
      swappy
      wl-clipboard
      wtype
    ];

    home.configFile."xdg-desktop-portal/portals.conf".source =
      ../../configs/xdg-desktop-portal/portals.conf;
  };
}
