{ config, pkgs, extendedLib, ... }:

with extendedLib;
let cfg = config.modules.desktop.waybar;
in {
  options.modules.desktop.waybar.enable = mkBoolOpt false;

  config = mkIf cfg.enable {
    home.packages = [ pkgs.waybar ];

    home.configFile."waybar" = {
      source = ../../configs/waybar;
      recursive = true;
    };

    systemd.user.services.waybar = {
      Unit = {
        Description = "Waybar status bar";
        Documentation = "https://github.com/Alexays/Waybar/wiki";
        PartOf = [ "sway-session.target" ];
        After = [ "sway-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Service = {
        ExecStart = "${pkgs.waybar}/bin/waybar";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install.WantedBy = [ "sway-session.target" ];
    };
  };
}
