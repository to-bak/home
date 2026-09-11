#!/bin/sh
set -eu

apt_lock_timeout=300

sudo apt-get -o DPkg::Lock::Timeout="$apt_lock_timeout" update
sudo apt-get -o DPkg::Lock::Timeout="$apt_lock_timeout" install -y \
  policykit-1-gnome \
  swaylock \
  xdg-desktop-portal \
  xdg-desktop-portal-gtk \
  xdg-desktop-portal-wlr

launcher=$(mktemp)
session=$(mktemp)
trap 'rm -f "$launcher" "$session"' EXIT

cat >"$launcher" <<'EOF'
#!/bin/sh

if [ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
elif [ -r /etc/profile.d/nix.sh ]; then
  . /etc/profile.d/nix.sh
fi

if [ -r "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi

export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"

systemctl --user import-environment PATH
if command -v dbus-update-activation-environment >/dev/null 2>&1; then
  dbus-update-activation-environment --systemd PATH
fi

exec "$HOME/.nix-profile/bin/sway"
EOF

cat >"$session" <<'EOF'
[Desktop Entry]
Name=Sway (Home Manager)
Comment=A tiling Wayland compositor managed by Home Manager
Exec=/usr/local/bin/home-manager-sway
Type=Application
DesktopNames=sway
EOF

sudo install -m 0755 "$launcher" /usr/local/bin/home-manager-sway
sudo install -m 0644 "$session" /usr/share/wayland-sessions/home-manager-sway.desktop

printf '%s\n' "Sway's GDM session and Ubuntu integrations are installed."
