{
  config,
  extendedLib,
  options,
  pkgs,
  ...
}:

with extendedLib;
let
  cfg = config.modules.desktop.i3;
in
{
  options.modules.desktop.i3 = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ ];

    home.configFile."i3" = {
      source = ../../configs/i3;
      recursive = true;
    };
  };
}
