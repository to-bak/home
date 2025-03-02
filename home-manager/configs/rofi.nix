{ pkgs, ... }:

{
  programs.rofi = {
    enable = true;
    extraConfig = {
      kb-accept-entry = "Control+m,Return,KP_Enter";
      kb-remove-to-eol = "";
      kb-row-down = "Control+j";
      kb-row-up = "Control+k";
      kb-mode-complete = "";
      kb-remove-char-back = "BackSpace,Shift+BackSpace";
      kb-mode-next = "Control+l";
      kb-mode-previous = "Control+h";
    };
  };
}
