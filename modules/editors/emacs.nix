{ config, pkgs, pkgs-emacs, extendedLib, ... }:

with extendedLib;
let
  cfg = config.modules.editors.emacs;
  emacsPackage = pkgs-emacs.emacs31.override { withNativeCompilation = true; };
  treesitGrammars = let epkgs = pkgs-emacs.emacsPackagesFor emacsPackage;
  in epkgs.treesit-grammars.with-all-grammars;
in {
  options.modules.editors.emacs = { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    programs.emacs = {
      enable = true;
      package = emacsPackage;
      extraPackages = epkgs: [
        epkgs.vterm
        # Native grammar libraries used by Emacs's built-in treesit package.
        # Lisp packages continue to be managed by straight.el.
        treesitGrammars
      ];
      # Nixpkgs links grammars into a package-specific lib directory which is
      # not one of Emacs's default dynamic-library search locations.
      extraConfig = ''
        (add-to-list 'treesit-extra-load-path "${treesitGrammars}/lib")
      '';
    };

    services.emacs = {
      enable = true;
      client.enable = true;
      startWithUserSession = true;
    };

    home.packages = with pkgs; [
      cmake
      libvterm
      xclip
      xdotool
      xorg.xprop
      xorg.xwininfo
    ];

    home.file = {
      ".emacs.d" = {
        source = config.lib.file.mkOutOfStoreSymlink
          "${config.home.homeDirectory}/.config/home-manager/.emacs.d";
      };
    };
  };
}
