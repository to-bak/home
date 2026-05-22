{
  config,
  extendedLib,
  options,
  pkgs,
  ...
}:

with extendedLib;
let
  cfg = config.modules.services.dunst;
in
{
  options.modules.services.dunst = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      dunst
    ];

    home.configFile."dunst" = {
      source = ../../configs/dunst;
    };
  };
}
