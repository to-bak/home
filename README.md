# Home

* Install [nix](https://nixos.org/download.html)
```sh
sh <(curl -L https://nixos.org/nix/install) --daemon
```

* Run the bootstrap script
```sh
nix run github:to-bak/home?dir=home-manager#bootstrap --extra-experimental-features "nix-command flakes"
```

* Install (flake-env)[https://github.com/to-bak/flake-env] and populate `$HOME/.flake-env/environment.nix` with following variables:

| Value        | Type   |
|--------------|--------|
| github_ghp   | string |
| github_user  | string |
| github_email | string |
| git_config   | string |
| username     | string |
| homeDir      | string |
| stateVersion | string |

(if in doubt, use stateVersion = "22.11").

* Profit.


## Known bugs

[Locale issues on non-NixOS](https://nixos.wiki/wiki/Locales)
```
export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive
```
