{ pkgs, ... }:

{
  programs.rofi = {
    enable = true;   
    extraConfig = {
      kb-accept-entry = "Control+m,Return,KP_Enter";
      kb-remove-to-eol = "";
      kb-row-down = "Control+j";
      kb-row-up = "Control+k";
    };
  };
}
