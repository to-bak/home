{ pkgs, stylix, environment, ... }:
{
  stylix.enable = true;
  stylix.override.base00 = "0c0f0c";
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/shadesmear-dark.yaml";
  stylix.image = ./forest.png;

  stylix.fonts = {
    monospace = {
      package = pkgs.nerd-fonts.jetbrains-mono;
      name = "JetBrainsMono Nerd Font Mono";
    };
    sansSerif = {
      package = pkgs.dejavu_fonts;
      name = "DejaVu Sans";
    };
    serif = {
      package = pkgs.dejavu_fonts;
      name = "DejaVu Serfid";
    };
  };
}
