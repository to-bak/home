{ pkgs, ... }:
{
    programs.fish = {
      enable = true;
      plugins = [{
        name = "z";
        src = pkgs.fetchFromGitHub {
          owner = "jethrokuan";
          repo  = "z";
          rev   = "e0e1b9dfdba362f8ab1ae8c1afc7ccf62b89f7eb";
          sha256 = "0dbnir6jbwjpjalz14snzd3cgdysgcs3raznsijd6savad3qhijc";
        }; 
      }];
      interactiveShellInit = ''
      # Fish configuration
      set fish_color_user --bold brgreen
      set fish_greeting ""
      # Fix up nix-env & friends for Nix 2.0
      # export NIX_REMOTE=daemon
    '';
    };
}
