{
  config,
  extendedLib,
  options,
  pkgs,
  ...
}:

with extendedLib;
let
  cfg = config.modules.desktop.polybar;
in
{
  options.modules.desktop.polybar = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ ];

    services.polybar = {
      enable = true;
      package = pkgs.polybarFull;
      script = ''
        (polybar padding)&
        (polybar workspaces)&
        (polybar clock)&
        (polybar tray)&
      '';
    };

    home.configFile."polybar" = {
      source = ../../configs/polybar;
      recursive = true;
    };
  };
}
