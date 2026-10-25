#!/bin/bash
set -euo pipefail

BBDX_SHA=61a3f6e0ff2d14d58f6f357beb4176fcd401a558
WBW_SHA=a6d6443a54dc731e5784cf9a0fec77f378a126f9

DEPS="git cmake gcc gcc-c++ extra-cmake-modules kwin-devel
kf6-kwindowsystem-devel kf6-knotifications-devel kf6-kio-devel kf6-kcrash-devel
kf6-ki18n-devel kf6-kguiaddons-devel kf6-kglobalaccel-devel kf6-kcmutils-devel
kf6-kconfigwidgets-devel kf6-kdeclarative-devel kdecoration-devel libepoxy-devel
qt6-qtbase-devel qt6-qtbase-private-devel qt6-qtdeclarative-devel
plasma-workspace-devel libplasma-devel wayland-devel libdrm-devel"

# remember what the base image already had, so cleanup can't remove base content
: > /tmp/preinstalled
for p in $DEPS; do rpm -q "$p" >/dev/null 2>&1 && echo "$p" >> /tmp/preinstalled; done

dnf install -y --setopt=install_weak_deps=False $DEPS

# --- exact-KWin guard: the effects only load if built for this exact version ---
KWIN_V=$(rpm -q --qf '%{VERSION}' kwin 2>/dev/null || true)
DEVEL_V=$(rpm -q --qf '%{VERSION}' kwin-devel 2>/dev/null || true)
echo "kwin=${KWIN_V}  kwin-devel=${DEVEL_V}"
if [ -n "$KWIN_V" ] && [ "$KWIN_V" != "$DEVEL_V" ]; then
    echo "FATAL: kwin-devel ($DEVEL_V) != kwin ($KWIN_V)." >&2
    echo "Effects built here would show as 'Unsupported' in KWin." >&2
    exit 1
fi

build_effect() {
    local name=$1 url=$2 sha=$3
    git clone --quiet "$url" "/tmp/$name"
    git -C "/tmp/$name" checkout --quiet "$sha"
    cmake -B "/tmp/$name/build" -S "/tmp/$name" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DKDE_INSTALL_LIBDIR=lib64
    cmake --build "/tmp/$name/build" -j"$(nproc)"
    cmake --install "/tmp/$name/build"
}

build_effect bbdx https://github.com/GoldenBilly/kwin-effects-better-blur-dx-wobbly "$BBDX_SHA"
build_effect wbw  https://github.com/GoldenBilly/BetterWobblyWindows "$WBW_SHA"

# where did they actually land?
find /usr -name '*better_blur_dx_wobbly*' -o -name '*better_wobblywindows*' | sort

rm -rf /tmp/bbdx /tmp/wbw

# remove only what we added — never touch base-image packages
for p in $DEPS; do grep -qx "$p" /tmp/preinstalled 2>/dev/null || dnf remove -y "$p" || true; done
dnf clean all
rm -f /tmp/preinstalled
