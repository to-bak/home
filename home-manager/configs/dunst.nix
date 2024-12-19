{ pkgs, ... }:
let
  theme = import ../theme.nix;
in
{
  services.dunst = {
    enable = true;
    iconTheme.package = pkgs.adwaita-icon-theme;
    iconTheme.name = "Adwaita";
    settings = {
      global = {
        origin = "top-right";
        transparency = 10;
        frame_width = 1;
        width = 400;
        padding = 15;
        timeout = 1200;
        horizontal_padding = 15;
        offset = "30x20";
        corner_radius = 10;
      };
    };

  };
}
