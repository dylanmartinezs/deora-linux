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

rm -rf /tmp/ckde
