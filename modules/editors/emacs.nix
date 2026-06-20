{ config, pkgs, pkgs-emacs, extendedLib, ... }:

with extendedLib;
let
  cfg = config.modules.editors.emacs;
in
{
  options.modules.editors.emacs = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    programs.emacs = {
      enable = true;
      package = pkgs-emacs.emacs.override { withNativeCompilation = true; };
      extraPackages = epkgs: [ epkgs.vterm ];
    };

    home.packages = with pkgs; [
      cmake
      libvterm
    ];

    home.file = {
      ".emacs.d" = {
        source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/home-manager/.emacs.d";
      };
    };
  };
}
