#!/usr/bin/env bash
set -euxo pipefail

git clone --depth 1 --recurse-submodules \
  https://github.com/ladybug-me/caelestia-kde.git /tmp/ckde
cd /tmp/ckde

# --- 1. KWin workspace-tracker effect (already proven to work) ---
cmake -G Ninja -B shell/kwin-effects/workspace-tracker/build \
  -S shell/kwin-effects/workspace-tracker \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr
cmake --build shell/kwin-effects/workspace-tracker/build -j"$(nproc)"
cmake --install shell/kwin-effects/workspace-tracker/build

# --- 2. Shell: upstream defaults, prefix "/" gives the packaged layout ---
cd /tmp/ckde/shell
cmake -G Ninja -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/ \
  -DCAELESTIA_PACKAGE=ON \
  -DREQUIRE_CAVA=ON \
  -DDISTRIBUTOR="bazzite-dx-caelestia"
cmake --build build -j"$(nproc)"
cmake --install build

# --- fonts: /usr/share/fonts is scanned by fontconfig; /etc/xdg is not ---
FONT_SHA=10ecc14790612ca8fd164e3f4ffe9c16fc50d5b7
install -d /usr/share/fonts/caelestia

# Google Sans Flex — committed in the bundle CMake installs
install -m644 /etc/xdg/quickshell/caelestia/assets/google-sans-flex/*.ttf \
               /usr/share/fonts/caelestia/

# Material Symbols Rounded — ligature icons; woff2 will NOT work here
curl -fL --retry 3 --retry-delay 5 \
  -o /usr/share/fonts/caelestia/MaterialSymbolsRounded.ttf \
  "https://raw.githubusercontent.com/google/material-design-icons/${FONT_SHA}/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf"

# 200-with-an-HTML-page guard: curl -f can't catch that
file /usr/share/fonts/caelestia/MaterialSymbolsRounded.ttf | grep -q 'TrueType'

fc-cache -f /usr/share/fonts/caelestia

fc-match "Material Symbols Rounded" | grep -qi 'MaterialSymbolsRounded'
fc-match "Google Sans Flex"         | grep -qi 'GoogleSansFlex'

# --- 3. Session environment ---
install -d /etc/environment.d
cat > /etc/environment.d/50-caelestia.conf <<'EOF'
QML2_IMPORT_PATH=/usr/lib/qt6/qml:/etc/xdg/quickshell/caelestia
QML_IMPORT_PATH=/usr/lib/qt6/qml:/etc/xdg/quickshell/caelestia
CAELESTIA_LIB_DIR=/usr/lib/caelestia
CAELESTIA_BIN_DIR=/usr/bin
CAELESTIA_SHELL_CONFIG=/etc/xdg/quickshell/caelestia/shell.qml
EOF

# --- 4. Gates ---
test -f /etc/xdg/quickshell/caelestia/shell.qml
test -f /usr/lib/qt6/qml/Caelestia/qmldir
compgen -G "/usr/lib/qt6/qml/Caelestia/*.so" >/dev/null
test -x /usr/bin/caelestia
ls /usr/lib64/qt6/plugins/kwin/effects/plugins/ | grep -q workspace_tracker
test -d /usr/share/sddm/themes/caelestia        # proves CAELESTIA_PACKAGE took effect

if [ ! -x /usr/bin/qdbus6 ]; then
    if [ -x /usr/bin/qdbus-qt6 ]; then
        ln -sf /usr/bin/qdbus-qt6 /usr/bin/qdbus6
    else
        echo "FATAL: qdbus-qt6 not found - add qt6-qttools to the recipe" >&2
        exit 1
    fi
fi
test -x /usr/bin/qdbus6

rm -rf /tmp/ckde

install -d /etc/sddm.conf.d
cat > /etc/sddm.conf.d/zzz-caelestia.conf <<'EOF'
[Theme]
Current=caelestia
QtVersion=6
EOF
