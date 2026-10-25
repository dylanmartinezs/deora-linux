#!/usr/bin/env bash
# files/scripts/espanso.sh
set -euxo pipefail

if [ -f /etc/yum.repos.d/terra.repo ]; then
    sed -i 's/^enabled=0/enabled=1/' /etc/yum.repos.d/terra.repo
fi

dnf5 install -y espanso-wayland

# Record what the RPM actually granted, so first login verifies instead of guesses.
mkdir -p /usr/share/caelestia-build
if command -v espanso >/dev/null; then
    getcap "$(command -v espanso)" || echo "no file capabilities set by RPM" \
      | tee /usr/share/caelestia-build/espanso-cap.txt
fi