# dotfiles
NIX flake / Emacs home setup.

## Setup
1. download nix: https://nixos.org/download/#download-nix
2. create file `home-manager/variables.nix`, and populate it:
```
{
  ### GITHUB
  # github ghp key
  github_ghp = "...";

  # git username
  github_user = "...";

  # git email
  github_email = "...";

  # path to local git_config, i.e. ~/.gitconfig
  git_config = "...";

  ### SYSTEM
  username = "..."; #echo $USER
  homeDir = "..."; #echo $HOME


  ### NIX
  # must be equal to state version of our current nix state_version.
  stateVersion = "...";

  ### MISC
  # path to background image.
  background = "...";
}
```
3. create following symlinks (some are optional)
```
nix -> $HOME/.config/nix
.emacs.d -> $HOME/.emacs.d
.profile -> $HOME/.profile
home-manager -> $HOME/.config/home-manager
```

4. search for `TODOs` in nix files, and address.

5. run `home-manager switch`
