{
  config,
  extendedLib,
  options,
  pkgs-stable,
  ...
}:

with extendedLib;
let
  cfg = config.modules.desktop.i3;
  pkgs = pkgs-stable;
in
{
  options.modules.desktop.i3 = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ 
      arandr
      autorandr
      networkmanagerapplet
      brightnessctl
      pulsemixer
      feh
    ];

    home.configFile."i3" = {
      source = ../../configs/i3;
      recursive = true;
    };
  };
}
