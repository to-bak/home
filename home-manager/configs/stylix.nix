{ pkgs, stylix, environment, ... }:
{
  stylix.enable = true;
  stylix.override.base00 = "0c0f0c";
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/shadesmear-dark.yaml";
  stylix.image = ./forest.png;
}
