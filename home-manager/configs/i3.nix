{ pkgs, lib, ... }:

{
  xsession.windowManager.i3 = {
    enable = true;
    package = pkgs.i3-gaps;

    config = rec {
      modifier = "Mod4";
      bars = [ ];
      window.border = 0;

      gaps = {
        smartGaps = true;
        inner = 5;
        outer = 5;
      };

      keybindings = lib.mkOptionDefault {
        "XF86AudioMute" = "exec amixer -D pulse sset Master toggle";
        "XF86AudioLowerVolume" = "exec amixer -D pulse sset Master 4%-";
        "XF86AudioRaiseVolume" = "exec amixer -D pulse sset Master 4%+";
        "XF86MonBrightnessDown" = "exec brightnessctl set 4%-";
        "XF86MonBrightnessUp" = "exec brightnessctl set 4%+";
        "${modifier}+Return" = "exec ${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel ${pkgs.alacritty}/bin/alacritty";
        "${modifier}+d" = "exec ${pkgs.rofi}/bin/rofi -show drun -theme ~/.dotfiles/rofi-themes/theme1/launcher.sh";
        "${modifier}+Shift+d" = "exec ${pkgs.rofi}/bin/rofi -show window";
        "${modifier}+Shift+x" = "exec i3lock -c 000000";

        # Focus
        "${modifier}+h" = "focus left";
        "${modifier}+j" = "focus down";
        "${modifier}+k" = "focus up";
        "${modifier}+l" = "focus right";
        "${modifier}+Ctrl+h" = "move workspace to output left";
        "${modifier}+Ctrl+l" = "move workspace to output right";

        # Move
        "${modifier}+Shift+h" = "move left";
        "${modifier}+Shift+j" = "move down";
        "${modifier}+Shift+k" = "move up";
        "${modifier}+Shift+l" = "move right";

        "${modifier}+ae" = "split h";

      };

      modes = lib.mkOptionDefault {
        resize = {
          "j" = "resize grow height 10 px or 10 ppt";
          "l" = "resize shrink width 10 px or 10 ppt";
          "h" = "resize grow width 10 px or 10 ppt";
          "k" = "resize shrink height 10 px or 10 ppt";
        };
      };

      startup = [
        {
          command = "exec i3-msg workspace 1";
          always = true;
          notification = false;
        }
        {
          command = "systemctl --user restart polybar.service";
          always = true;
          notification = false;
        }
        {
          command = "${pkgs.feh}/bin/feh --bg-scale $HOME/.dotfiles/wallpapers/forest.png";
          always = true;
          notification = false;
        }
        {
          command = "${pkgs.picom}/bin/picom --transparent-clipping -b";
          always = true;
          notification = false;
        }
        {
          command = "${pkgs.autorandr}/bin/autorandr -c";
          always = false;
          notification = false;
        }
        {
          command = "${pkgs.networkmanagerapplet}/bin/nm-applet --sm-disable";
          always = false;
          notification = false;
        }
        {
          command = "${pkgs.flameshot}/bin/flameshot";
          always = false;
          notification = false;
        }
      ];
    };
  };
}
