{ pkgs, ... }:

{
  programs.alacritty = {
    enable = true;

    settings = {
      window = {
        title = "Terminal";

        padding = { y = 10; x=10;};
        dimensions = {
          lines = 75;
          columns = 100;
        };
      };

      shell = { program = "${pkgs.fish}/bin/fish"; };
    };
  };
}
