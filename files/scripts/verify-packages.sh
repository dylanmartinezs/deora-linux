#!/usr/bin/env bash
set -uo pipefail

missing=()
for p in espanso-wayland sunshine; do
    rpm -q "$p" >/dev/null 2>&1 || missing+=("$p")
done

if [ ${#missing[@]} -gt 0 ]; then
    printf 'FATAL: packages failed to install: %s\n' "${missing[*]}" >&2
    for p in "${missing[@]}"; do
        dnf5 repoquery --available "$p" 2>&1 | head -3 >&2
    done
    exit 1
fi
echo "verify-packages: all expected packages present"
