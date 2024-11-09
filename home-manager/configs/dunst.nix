{ pkgs, ... }:
let
  theme = import ../theme.nix;
in
{
  services.dunst = {
    enable = true;
    settings = {
      global = {
        font = "Monospace 10";
        origin = "top-right";
        transparency = 10;
        frame_color = theme.borderColor;
       frame_width = 2;
        width = 400;
        padding = 15;
        timeout = 1200;
        horizontal_padding = 15;
        offset = "30x50";
        background = theme.backgroundColor;
        foreground = theme.foregroundColor;
      };
    };

  };
}
