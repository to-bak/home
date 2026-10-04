{
  config,
  extendedLib,
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
    home.packages = with pkgs; [ 
      i3
      arandr
      autorandr
      networkmanagerapplet
      brightnessctl
      pulsemixer
      feh
    ];

    programs.i3status = {
      enable = true;
      general = {
        output_format = "i3bar";
        interval = 5;
      };
      modules."tztime local" = {
        settings.format = "%I:%M %p | %d-%m";
      };
    };

    home.configFile."i3" = {
      source = ../../configs/i3;
      recursive = true;
    };

    home.file.".local/share/applications/i3.desktop" = {
      source = ../../configs/desktop_entries/i3.desktop;
    };

    home.file.".profile" = {
      source = ../../configs/x11/.profile;
    };

    home.file.".config/autorandr/postswitch" = {
      source = ../../configs/autorandr/postswitch;
    };
  };
}
