#!/bin/sh
set -eu

sway_version=1.11
wlroots_version=0.19.3
package_version=1.11-1ubuntu24.04local3
install_prefix=/opt/sway-native
apt_lock_timeout=300

if [ ! -r /etc/os-release ]; then
  printf '%s\n' "Cannot identify this operating system." >&2
  exit 1
fi

. /etc/os-release
if [ "${ID:-}" != ubuntu ] || [ "${VERSION_ID:-}" != 24.04 ]; then
  printf '%s\n' "This installer supports Ubuntu 24.04 only." >&2
  exit 1
fi

if [ "$(dpkg-query -W -f='${Version}' sway-native 2>/dev/null || true)" = "$package_version" ]; then
  printf '%s\n' "sway-native $package_version is already installed."
  exit 0
fi

sudo apt-get -o DPkg::Lock::Timeout="$apt_lock_timeout" install -y \
  build-essential \
  ca-certificates \
  curl \
  hwdata \
  libcap-dev \
  libcairo2-dev \
  libdisplay-info-dev \
  libdrm-dev \
  libegl-dev \
  libevdev-dev \
  libexpat1-dev \
  libffi-dev \
  libgbm-dev \
  libgles2-mesa-dev \
  libjson-c-dev \
  libliftoff-dev \
  libmtdev-dev \
  libpam0g-dev \
  libpango1.0-dev \
  libpcre2-dev \
  libseat-dev \
  libsystemd-dev \
  libudev-dev \
  libxcb-composite0-dev \
  libxcb-ewmh-dev \
  libxcb-icccm4-dev \
  libxcb-present-dev \
  libxcb-render0-dev \
  libxcb-render-util0-dev \
  libxcb-res0-dev \
  libxcb-xfixes0-dev \
  libxcb-xinput-dev \
  libxcb1-dev \
  libxkbcommon-dev \
  meson \
  ninja-build \
  patch \
  pkg-config \
  scdoc \
  swaybg \
  wayland-protocols \
  xwayland

work_dir=$(mktemp -d)
stage_dir="$work_dir/package"
source_dir="$work_dir/sources"
archive_dir="$work_dir/archives"
deb="$work_dir/sway-native_${package_version}_$(dpkg --print-architecture).deb"
trap 'rm -rf "$work_dir"' EXIT

mkdir -p "$stage_dir$install_prefix" "$source_dir" "$archive_dir"

fetch_source() {
  name=$1
  url=$2
  checksum=$3
  archive="$archive_dir/$name"

  curl --fail --location --retry 3 --output "$archive" "$url"
  printf '%s  %s\n' "$checksum" "$archive" | sha256sum --check --status
  tar -xf "$archive" -C "$source_dir"
}

fetch_source wayland.tar.xz \
  https://gitlab.freedesktop.org/wayland/wayland/-/releases/1.23.1/downloads/wayland-1.23.1.tar.xz \
  864fb2a8399e2d0ec39d56e9d9b753c093775beadc6022ce81f441929a81e5ed
fetch_source pixman.tar.gz \
  https://cairographics.org/releases/pixman-0.44.2.tar.gz \
  6349061ce1a338ab6952b92194d1b0377472244208d47ff25bef86fc71973466
fetch_source libinput.tar.gz \
  https://gitlab.freedesktop.org/libinput/libinput/-/archive/1.26.2/libinput-1.26.2.tar.gz \
  5c1c4150f217fea1db2d1fd88e2607b2f1928cfde65c34da65a9f24dcfd69464
fetch_source wlroots.tar.gz \
  "https://gitlab.freedesktop.org/wlroots/wlroots/-/archive/$wlroots_version/wlroots-$wlroots_version.tar.gz" \
  a6ff89b64ea15e424d1b0db4a22145fccf5ec2ff2e7b8af0fa35e2ac8975986f
fetch_source sway.tar.gz \
  "https://github.com/swaywm/sway/releases/download/$sway_version/sway-$sway_version.tar.gz" \
  0e37a55b7c3379230e97e1ad982542b75016a0c7d6676198604e557f9b373dae

export PATH="$stage_dir$install_prefix/bin:$PATH"
export PKG_CONFIG_PATH="$stage_dir$install_prefix/lib/pkgconfig:$stage_dir$install_prefix/share/pkgconfig"
export LD_LIBRARY_PATH="$stage_dir$install_prefix/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

prepare_staged_pkgconfig() {
  find "$stage_dir$install_prefix" -name '*.pc' -type f -exec \
    sed -i "s|^prefix=$install_prefix\$|prefix=$stage_dir$install_prefix|" {} +
}

build_meson_project() {
  project=$1
  shift

  meson setup "$work_dir/build-$project" "$source_dir/$project" \
    --prefix="$install_prefix" \
    --libdir=lib \
    --buildtype=release \
    --wrap-mode=nofallback \
    "-Dc_link_args=-Wl,-rpath,$install_prefix/lib" \
    "$@"
  meson compile -C "$work_dir/build-$project"
  DESTDIR="$stage_dir" meson install -C "$work_dir/build-$project"
  prepare_staged_pkgconfig
}

build_meson_project wayland-1.23.1 \
  -Ddocumentation=false \
  -Ddtd_validation=false \
  -Dtests=false

build_meson_project pixman-0.44.2 \
  -Ddemos=disabled \
  -Dgtk=disabled \
  -Dlibpng=disabled \
  -Dopenmp=disabled \
  -Dtests=disabled

build_meson_project libinput-1.26.2 \
  -Ddebug-gui=false \
  -Ddocumentation=false \
  -Dlibwacom=false \
  -Dtests=false

# Proprietary NVIDIA's implicit synchronization can expose unfinished GLES
# rendering during wlroots' cross-GPU copy. Keep upstream behavior by default
# and let the hybrid-GPU launcher opt into the stronger synchronization.
patch -d "$source_dir/wlroots-$wlroots_version" -p1 <<'PATCH'
--- a/render/gles2/pass.c
+++ b/render/gles2/pass.c
@@ -57,7 +57,11 @@ static bool render_pass_submit(struct wlr_render_pass *wlr_pass) {
 			goto out;
 		}
 	} else {
-		glFlush();
+		if (getenv("WLR_NVIDIA_FORCE_GLES2_FINISH") != NULL) {
+			glFinish();
+		} else {
+			glFlush();
+		}
 	}
 
 	ok = true;
PATCH

build_meson_project "wlroots-$wlroots_version" \
  -Dbackends=drm,libinput \
  -Dcolor-management=disabled \
  -Dexamples=false \
  -Drenderers=gles2 \
  -Dxwayland=enabled

build_meson_project "sway-$sway_version" \
  -Ddefault-wallpaper=false \
  -Dgdk-pixbuf=disabled \
  -Dman-pages=enabled \
  -Dsd-bus-provider=libsystemd \
  -Dswaybar=false \
  -Dtray=disabled

# Restore relocatable metadata after using the staged paths during the build.
find "$stage_dir$install_prefix" -name '*.pc' -type f -exec \
  sed -i "s|^prefix=$stage_dir$install_prefix\$|prefix=$install_prefix|" {} +

mkdir -p "$stage_dir/DEBIAN" "$stage_dir/usr/local/bin"
for binary in sway swaymsg swaynag; do
  ln -s "$install_prefix/bin/$binary" "$stage_dir/usr/local/bin/$binary"
done

cat >"$stage_dir/DEBIAN/control" <<EOF
Package: sway-native
Version: $package_version
Architecture: $(dpkg --print-architecture)
Maintainer: Local administrator <root@localhost>
Provides: sway
Conflicts: sway
Replaces: sway
Depends: libc6, libcairo2, libcap2, libdisplay-info1, libdrm2, libegl1, libevdev2, libffi8, libgbm1, libgles2, libjson-c5, libmtdev1t64, libpam0g, libpango-1.0-0, libpangocairo-1.0-0, libpcre2-8-0, libseat1, libsystemd0, libudev1, libxcb1, libxcb-composite0, libxcb-icccm4, libxcb-render0, libxcb-render-util0, libxcb-res0, libxcb-xfixes0, libxcb-xinput0, swaybg, xwayland
Section: x11
Priority: optional
Description: Sway $sway_version for Ubuntu 24.04
 Native Sway and wlroots stack isolated under $install_prefix.
EOF

dpkg-deb --root-owner-group --build "$stage_dir" "$deb"
sudo apt-get -o DPkg::Lock::Timeout="$apt_lock_timeout" install -y "$deb"

/usr/local/bin/sway --version
