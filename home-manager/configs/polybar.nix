{ config, lib, pkgs, stylix, ... }:
with config.lib.stylix.colors;
let
  height = "24pt";
  border-size = "2pt";
  transparent-color = "#00000000";
  bottom = true;

  inherit (config.lib.formats.rasi) mkLiteral;

  # base0 = background
  background = "99${base00}";
  foreground = "${base04}";
  alert = "${base08}";
  disabled = "${base01}";
  grey = "${base03}";

  fn-create-polybar = width : offset-x : modules-left : {
    width = width;
    offset-x = offset-x;
    height = height;
    radius = 5;
    background = background;
    foreground = foreground;
    border-size = border-size;
    border-color = transparent-color;
    padding-left = 1;
    padding-right = 1;
    font-0 = "JetBrainsMono Nerd Font:weight=bold:size=10;2";
    font-1 = "Symbols Nerd Font Mono:size=10;2";
    modules-left = modules-left;
    bottom = bottom;
    enable-ipc = true;
    cursor-click = "pointer";
    override-redirect = true;
  };
in
{
  services.polybar = {
    enable = true;
    package = pkgs.polybarFull;
    config = {
      "bar/workspaces" = fn-create-polybar "12%" "44%" "xworkspaces";
      "bar/clock" = fn-create-polybar "7.8%" "2.4%" "date";
      "bar/tray" = fn-create-polybar "7.8%" "90.4%" "tray";

      # since above bars have override-redirect = true,
      # we want to create an invisible padding bar.
      "bar/padding" = {
        width = "100%";
        height = height;
        wm-restack = "i3";
        border-size = border-size;
        border-color = transparent-color;
        override-redirect = false;
        bottom = bottom;
        background = transparent-color;
        modules-left = "dummy";
      };

      "module/xworkspaces" = {
        type = "internal/xworkspaces";
        label-active = "%name%";
        label-active-background = background;
        label-active-foreground = foreground;
        label-active-underline= foreground;
        label-active-padding = "1";
        label-occupied = "%name%";
        label-occupied-padding = "1";
        label-urgent = "%name%";
        label-urgent-background = alert;
        label-urgent-padding = "1";
        label-empty = "%name%";
        label-empty-foreground = disabled;
        label-empty-padding = "1";
      };

      "module/date" = {
        type = "internal/date";
        interval = 1;
        date = "%I:%M %p|%d-%m";
        label = "%date%";
        label-foreground = foreground;
      };

      "module/tray" = {
        type = "internal/tray";
      };

      "module/dummy" = {
        type = "custom/text";
        content = " ";
      };

    };
    script = ''
      (polybar padding)&
      (polybar workspaces)&
      (polybar clock)&
      (polybar tray)&
    '';
  };

}
