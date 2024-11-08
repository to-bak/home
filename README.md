# Home

Install [nix](https://nixos.org/download.html)
```sh
sh <(curl -L https://nixos.org/nix/install) --daemon
```
Create $HOME/.gitconfig
```sh
[user]
   name = your name
   email = your email
```
Run the bootstrap script (first time for preparation)
```sh
nix run github:to-bak/home?dir=home-manager#bootstrap --extra-experimental-features "nix-command flakes"
```

Populate `$HOME/.flake-env/environment.nix` with following structure:
```
{
  github_ghp = "...";
  github_user = "...";
  github_email = "...";
  git_config = "...";
  username = "...";
  homeDir = "...";
  stateVersion = "22.11";
}
```

Run the bootstrap script (second time for installation)
```sh
nix run github:to-bak/home?dir=home-manager#bootstrap --extra-experimental-features "nix-command flakes"
```
(The `$HOME/variables.nix` file will be removed, and moved into `$HOME/.dotfiles/home-manager/variables.nix`)

[Locale issues on non-NixOS](https://nixos.wiki/wiki/Locales)
```
export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive
```
