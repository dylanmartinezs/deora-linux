#!/usr/bin/env bash
set -euxo pipefail

export CAELESTIA_INSTALL_KIND=package

git clone --depth 1 --recurse-submodules \
  https://github.com/ladybug-me/caelestia-kde.git /tmp/ckde

# The effect must be built BEFORE devel packages are stripped.
cd /tmp/ckde
cmake -G Ninja -B kwin-effects/workspace-tracker/build \
  -S kwin-effects/workspace-tracker \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/usr
cmake --build kwin-effects/workspace-tracker/build -j"$(nproc)"
cmake --install kwin-effects/workspace-tracker/build

# Shell, in "package" layout. Mirrors the flags in scripts/08-build-shell.sh
# with $HOME/.local replaced by /usr and Fedora's lib64 QML dir.
cd /tmp/ckde/shell
cmake -G Ninja -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCAELESTIA_CACHE_DEPS=ON \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DINSTALL_BINDIR=bin \
  -DINSTALL_DATADIR=lib/caelestia \
  -DINSTALL_QSCONFDIR=/etc/xdg/quickshell/caelestia \
  -DINSTALL_LIBDIR=lib/caelestia \
  -DINSTALL_QMLDIR=lib64/qt6/qml
cmake --build build -j"$(nproc)"
cmake --install build

# Session environment — the packaged paths from install-kind.sh.
cat > /etc/environment.d/50-caelestia.conf <<'EOF'
QML2_IMPORT_PATH=/usr/lib64/qt6/qml:/etc/xdg/quickshell/caelestia
QML_IMPORT_PATH=/usr/lib64/qt6/qml:/etc/xdg/quickshell/caelestia
CAELESTIA_LIB_DIR=/usr/lib/caelestia
CAELESTIA_BIN_DIR=/usr/bin
CAELESTIA_SHELL_CONFIG=/etc/xdg/quickshell/caelestia/shell.qml
EOF

# Sanity gate: fail the build rather than ship a shell that can't load.
test -f /usr/lib64/qt6/qml/Caelestia/qmldir
test -f /etc/xdg/quickshell/caelestia/shell.qml
ls /usr/lib64/qt6/plugins/kwin/effects/plugins/ | grep -q workspace_tracker

# Keep the bundle: first-login scripts source lib/ from here, and because
# that path is under /usr, install_is_packaged() returns "package" there too.
install -d /usr/share/caelestia-kde
cp -a scripts installer assets /usr/share/caelestia-kde/ 2>/dev/null || \
  cp -a scripts installer /usr/share/caelestia-kde/

rm -rf /tmp/ckde
