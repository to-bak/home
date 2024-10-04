# Home

Install [nix](https://nixos.org/download.html)
```sh
sh <(curl -L https://nixos.org/nix/install) --daemon
```

Populate `$HOME/variables.nix` with following structure:
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

Run the bootstrap script
```sh
nix run github:to-bak/home?dir=home-manager#bootstrap \
    --extra-experimental-features nix-command \
    --extra-experimental-features flakes

```
(The `$HOME/variables.nix` file will be removed, and moved into `$HOME/.dotfiles/home-manager/variables.nix`)

[Locale issues on non-NixOS](https://nixos.wiki/wiki/Locales)
```
export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive
```
