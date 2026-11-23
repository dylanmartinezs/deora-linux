#!/usr/bin/env bash
set -uo pipefail

missing=()
for p in espanso-wayland sunshine; do
    rpm -q "$p" >/dev/null 2>&1 || missing+=("$p")
done

if [ ${#missing[@]} -eq 0 ]; then
    echo "verify-packages: OK (espanso-wayland, sunshine)"
    exit 0
fi

{
    echo "FATAL: packages failed to install: ${missing[*]}"
    echo "--- enabled repos ---"
    dnf5 repolist --enabled 2>/dev/null | awk 'NR>1 {print $1}' | tr '\n' ' '
    echo
    for p in "${missing[@]}"; do
        echo "--- $p ---"
        dnf5 -q repoquery --available "$p" 2>/dev/null | head -3 || echo "(not in any enabled repo)"
    done
} >&2

exit 1
