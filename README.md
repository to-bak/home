# Home

Install [nix](https://nixos.org/download.html)
```sh
sh <(curl -L https://nixos.org/nix/install) --daemon
```

Run the bootstrap script
```sh
nix run github:to-bak/home?dir=home-manager#bootstrap \
    --extra-experimental-features nix-command \
    --extra-experimental-features flakes

```

[Locale issues on non-NixOS](https://nixos.wiki/wiki/Locales)
```
export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive
```
