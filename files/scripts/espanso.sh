#!/usr/bin/env bash
set -euo pipefail

# Bazzite disables terra and all third-party repos by default (ublue-os/bazzite#2580).
# The repo FILE still exists, so a `-f /etc/yum.repos.d/terra.repo` test passes
# while the repo is off - and dnf5 then reports only "No match for argument".
# Persist the enable so the shipped image matches a working build.
if ! dnf5 repolist --enabled --quiet 2>/dev/null | awk '{print $1}' | grep -qx terra; then
    echo "espanso: terra is disabled in the base - enabling it persistently" >&2
    dnf5 config-manager setopt terra.enabled=1
fi

# terra-source pulls 285 KiB of SRPM metadata per build for nothing
dnf5 config-manager setopt terra-source.enabled=0 || true

# skip_if_unavailable=False: an unreachable or GPG-failing repo must abort and
# name itself, instead of being silently dropped and surfacing as "No match"
dnf5 install -y --refresh \
    --enablerepo=terra \
    --setopt='*.skip_if_unavailable=False' \
    espanso-wayland

rpm -q espanso-wayland
b="$(readlink -f "$(command -v espanso)")"
setcap 'cap_dac_override+p' "$b"
getcap "$b"
