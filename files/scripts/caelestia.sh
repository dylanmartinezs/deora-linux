#!/usr/bin/env bash
set -euxo pipefail

git clone --depth 1 --recurse-submodules \
  https://github.com/ladybug-me/caelestia-kde.git /tmp/ckde
cd /tmp/ckde

# --- 1. KWin workspace-tracker effect ---
# Lives in shell/kwin-effects/, installs to /usr/lib64/qt6/plugins/kwin/effects/plugins
cmake -G Ninja -B shell/kwin-effects/workspace-tracker/build \
  -S shell/kwin-effects/workspace-tracker \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr
cmake --build shell/kwin-effects/workspace-tracker/build -j"$(nproc)"
cmake --install shell/kwin-effects/workspace-tracker/build

# --- 2. Shell QML tree + C++ QML plugin ---
# Same flags as scripts/08-build-shell.sh, with $HOME/.local -> /usr
cd /tmp/ckde/shell
cmake -G Ninja -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCAELESTIA_CACHE_DEPS=ON \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DINSTALL_BINDIR=bin \
  -DINSTALL_DATADIR=lib/caelestia \
  -DINSTALL_QSCONFDIR=/etc/xdg/quickshell/caelestia \
  -DINSTALL_LIBDIR=lib/caelestia \
  -DINSTALL_QMLDIR=lib/qt6/qml
cmake --build build -j"$(nproc)"
cmake --install build

# --- 3. Session environment ---
# Matches install_qml_import_path()'s packaged branch: /usr/lib/qt6/qml + /etc/xdg/quickshell/caelestia
install -d /etc/environment.d
cat > /etc/environment.d/50-caelestia.conf <<'EOF'
QML2_IMPORT_PATH=/usr/lib/qt6/qml:/etc/xdg/quickshell/caelestia
QML_IMPORT_PATH=/usr/lib/qt6/qml:/etc/xdg/quickshell/caelestia
CAELESTIA_LIB_DIR=/usr/lib/caelestia
CAELESTIA_BIN_DIR=/usr/bin
CAELESTIA_SHELL_CONFIG=/etc/xdg/quickshell/caelestia/shell.qml
EOF

# --- 4. Gates: fail the build instead of shipping a shell that can't load ---
for m in Caelestia Caelestia/Components Caelestia/Config Caelestia/Settings \
         Caelestia/Models Caelestia/Services Caelestia/Services/QuickShare \
         Caelestia/Blobs Caelestia/Images Caelestia/Layouts M3Shapes; do
  test -f "/usr/lib/qt6/qml/$m/qmldir"
  compgen -G "/usr/lib/qt6/qml/$m/*.so" >/dev/null
done

test -f /etc/xdg/quickshell/caelestia/shell.qml
ls /usr/lib64/qt6/plugins/kwin/effects/plugins/ | grep -q workspace_tracker

# --- 5. Keep the bundle for first-login steps ---
install -d /usr/share/caelestia-kde
cp -a scripts installer src assets /usr/share/caelestia-kde/

rm -rf /tmp/ckde
