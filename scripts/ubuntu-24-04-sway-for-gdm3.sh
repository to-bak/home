#!/bin/sh
set -eu

apt_lock_timeout=300
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

#sudo apt-get -o DPkg::Lock::Timeout="$apt_lock_timeout" update
sudo apt-get -o DPkg::Lock::Timeout="$apt_lock_timeout" install -y \
  policykit-1-gnome \
  swaylock \
  xdg-desktop-portal \
  xdg-desktop-portal-gtk \
  xdg-desktop-portal-wlr

"$script_dir/install-sway-native-ubuntu-24-04.sh"

launcher=$(mktemp)
session=$(mktemp)
trap 'rm -f "$launcher" "$session"' EXIT

cat >"$launcher" <<'EOF'
#!/bin/sh

if [ -r "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi

export PATH="/usr/local/bin:$HOME/.nix-profile/bin:$PATH"
export MOZ_ENABLE_WAYLAND=1
export NIXOS_OZONE_WL=1
export QT_QPA_PLATFORM="wayland;xcb"
export SDL_VIDEODRIVER=wayland,x11
export XDG_CURRENT_DESKTOP=sway
export XDG_SESSION_DESKTOP=sway
export XDG_SESSION_TYPE=wayland

intel_card=
nvidia_card=
for card_path in /sys/class/drm/card?; do
  [ -L "$card_path/device/driver" ] || continue
  card="/dev/dri/${card_path##*/}"
  case "$(basename "$(readlink -f "$card_path/device/driver")")" in
    i915) intel_card=$card ;;
    nvidia) nvidia_card=$card ;;
  esac
done

if [ -n "$intel_card" ] && [ -n "$nvidia_card" ]; then
  export WLR_DRM_DEVICES="$intel_card:$nvidia_card"
  export WLR_DRM_NO_MODIFIERS=1
  export WLR_NVIDIA_FORCE_GLES2_FINISH=1
  exec /usr/local/bin/sway --unsupported-gpu
fi

exec /usr/local/bin/sway
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
