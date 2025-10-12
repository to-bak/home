{ config, pkgs, extendedLib, ... }:

with extendedLib;
let 
   cfg = config.modules.desktop.rofi;
in
{
  options.modules.desktop.rofi = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
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

    home.file = {
      ".config/rofi" = {
        source = ../../configs/rofi;
          recursive = true;
      };
    };
  };
}
