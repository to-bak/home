{ config, lib, pkgs, ... }:
let
  theme = import ../theme.nix;
in
{
  services.polybar = {
    enable = true;
    package = pkgs.polybarFull;
    config = {
      "bar/main" = {
        background = "#901a1a1a";
        foreground = "#ffffff";
        modules-left = "i3";
        modules-center = "mpd";
        modules-right = "battery date";
        border-left-size = 25;
        border-left-color = "#901a1a1a";
        border-right-size = 25;
        border-right-color = "#901a1a1a";
        border-top-size = 0;
        border-top-color = "#901a1a1a";
        border-bottom-size = 0;
        border-bottom-color = "#901a1a1a";
        font-0 = "lemon:pixelsize=14;1";
        tray-position = "right";
      };
      "module/battery" = {
        type = "internal/battery";
      };
      "module/date" =
        let
          calnotify = pkgs.writeShellScript "calnotify.sh" ''
            day="$(${pkgs.coreutils}/bin/date +'%-d ' | ${pkgs.gnused}/bin/sed 's/\b[0-9]\b/ &/g')"
            cal="$(${pkgs.utillinux}/bin/cal | ${pkgs.gnused}/bin/sed -e 's/^/ /g' -e 's/$/ /g' -e "s/$day/\<span color=\'#ffffff\'\>\<b\>$day\<\/b\>\<\/span\>/" -e '1d')"
            top="$(${pkgs.utillinux}/bin/cal | ${pkgs.gnused}/bin/sed '1!d')"
            ${pkgs.libnotify}/bin/notify-send "$top" "$cal"
          '';
        in
        {
          type = "internal/date";
          date = "%I:%M %p    %a %b %d";
          label = "%{A1:${calnotify}:}%date%%{A}";
          format = "<label>";
          label-padding = 5;
        };
      "module/i3" = {
        type = "internal/i3";
        label-unfocused-foreground = "#ffffff";
        label-focused-foreground = "#111111";
  label-focused-background = theme.borderColor;
        label-urgent-foreground = "#ffffff";
        label-unfocused-padding = 1;
        label-focused-padding = 1;
        label-urgent-padding = 1;
      };
      "module/mpd" = {
        type = "internal/mpd";
        label-song = "%{A1:${pkgs.mpc_cli}/bin/mpc toggle:}%artist% - %title% %{A}";
        icon-play = " (paused)";
        icon-play-foreground = "#ffffff";
        icon-pause = "";
        format-online = "<label-song><toggle>";
      };
    };
    script = ''
      polybar main &
    '';
  };

}
