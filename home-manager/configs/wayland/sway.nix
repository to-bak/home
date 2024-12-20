{ pkgs, lib, ... }:

let
  modifier = "Mod4";
  terminal =
        "${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel ${pkgs.alacritty}/bin/alacritty";
in
{
  wayland.windowManager.sway = {
    enable = true;
    systemd.enable = true;

    config = {
      terminal = terminal;

      focus = {
        followMouse = "always";
        newWindow = "smart";
      };

      modifier = modifier;

      window = {
        hideEdgeBorders = "smart";
        border = 0;
      };

      gaps = {
        top = 1;
        bottom = 1;
        horizontal = 5;
        vertical = 5;
        inner = 5;
        outer = 5;
        left = 5;
        right = 5;
        smartBorders = "on";
        smartGaps = true;
      };

      keybindings = lib.mkOptionDefault {
        "${modifier}+Return" = "exec ${terminal}";
        "${modifier}+Shift+r" = "reload";
        "${modifier}+Shift+q" = "exit";
        "${modifier}+ae" = "splith";
        "${modifier}+v" = "splitv";
        "${modifier}+s" = "layout stacking";
        "${modifier}+w" = "layout tabbed";
        "${modifier}+f" = "fullscreen";
        "${modifier}+Shift+space" = "floating toggle";
        "${modifier}+space" = "focus mode_toggle";

        "${modifier}+Shift+1" = "move container to workspace number 1";
        "${modifier}+Shift+2" = "move container to workspace number 2";
        "${modifier}+Shift+3" = "move container to workspace number 3";
        "${modifier}+Shift+4" = "move container to workspace number 4";
        "${modifier}+Shift+5" = "move container to workspace number 5";
        "${modifier}+Shift+6" = "move container to workspace number 6";
        "${modifier}+Shift+7" = "move container to workspace number 7";
        "${modifier}+Shift+8" = "move container to workspace number 8";
        "${modifier}+Shift+9" = "move container to workspace number 9";
        "${modifier}+Shift+0" = "move container to workspace number 10";

        "${modifier}+h" = "focus left";
        "${modifier}+j" = "focus down";
        "${modifier}+k" = "focus up";
        "${modifier}+l" = "focus right";

        "${modifier}+Ctrl+h" = "move workspace to output left";
        "${modifier}+Ctrl+j" = "move workspace to output down";
        "${modifier}+Ctrl+k" = "move workspace to output up";
        "${modifier}+Ctrl+l" = "move workspace to output right";

        "${modifier}+Shift+h" = "move left";
        "${modifier}+Shift+j" = "move down";
        "${modifier}+Shift+k" = "move up";
        "${modifier}+Shift+l" = "move right";
      };
    };

    extraConfig = ''
      set $opacity_focused 0.94
      set $opacity_unfocused 0.9
      for_window [class=".*"] opacity $opacity_unfocused
      for_window [app_id=".*"] opacity $opacity_unfocused
      for_window [class="__focused__"] opacity $opacity_focused
    '';

    # modes = {
    #   resize = {
    #     h = "resize shrink width 10 px";
    #     j = "resize grow height 10 px";
    #     k = "resize shrink height 10 px";
    #     l = "resize grow width 10 px";
    #     Escape = "mode default";
    #     Return = "mode default";
    #   };
    # };
  };
}
