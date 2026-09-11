{ config, extendedLib, options, pkgs, ... }:

with extendedLib;
let cfg = config.modules.services.dunst;
in {
  options.modules.services.dunst = with types; { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ dunst ];

    home.configFile."dunst" = { source = ../../configs/dunst; };

    systemd.user.services.dunst = {
      Unit = {
        Description = "Dunst notification daemon";
        PartOf = [ "sway-session.target" ];
        After = [ "sway-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Service = {
        ExecStart = "${pkgs.dunst}/bin/dunst";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "sway-session.target" ];
    };
  };
}
