{ config, pkgs, lib, environment, ... }:

{
  imports = [
    ./direnv.nix
    ./alacritty.nix
    ./compton.nix
    ./i3.nix
    ./polybar.nix
    ./rofi.nix
    ./fish.nix
    ./fzf.nix
    ./dunst.nix
  ];

  programs = {
    home-manager.enable = true;
    command-not-found.enable = true;
    ssh.enable = true;
    git = {
      enable = true;
      userName = environment.github_user;
      userEmail = environment.github_email;
      extraConfig = {
      # TODO provide git-credential-libsecret via native OS
      credential.helper = "${
          pkgs.git.override { withLibsecret = true; }
        }/bin/git-credential-libsecret";
      };
      includes = [
        {path = environment.git_config;}
      ];
      signing.key = environment.github_ghp;
    };
  };

  xsession.enable = true;

}
