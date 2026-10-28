#!/bin/bash
set -euo pipefail

# --- GodotHub (AppImage, latest release, staged for GearLever) ----------------
# Asset names embed the version, so the tag is resolved at build time.
# Resolution uses the /releases/latest redirect (no REST API quota); the API is
# only consulted for the sha256 digest, which is optional.
REPO=RykoTheDev/GodotHub
PIN="${GODOTHUB_VERSION:-}"        # set to e.g. 1.5.3 to freeze a build

if [ -n "$PIN" ]; then
    TAG="v${PIN#v}"
else
    TAG=$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
            "https://github.com/${REPO}/releases/latest" | sed 's#.*/tag/##')
fi

case "$TAG" in
    v[0-9]*.[0-9]*.[0-9]*) ;;
    *) echo "FATAL: could not resolve GodotHub tag (got '$TAG')" >&2; exit 1 ;;
esac
VER="${TAG#v}"

ASSET="GodotHub-${VER}-linux-amd64.AppImage"
URL="https://github.com/${REPO}/releases/download/${TAG}/${ASSET}"
echo "GodotHub: resolving ${TAG} -> ${ASSET}"

curl -fL --retry 3 --retry-delay 2 -o "/tmp/${ASSET}" "$URL"

# --- integrity: API digest if reachable, hard failure if it mismatches --------
DIGEST=$(curl -fsS "https://api.github.com/repos/${REPO}/releases/tags/${TAG}" 2>/dev/null \
    | jq -r --arg n "$ASSET" '.assets[] | select(.name==$n) | .digest // empty' 2>/dev/null || true)

if [ -n "$DIGEST" ]; then
    echo "${DIGEST#sha256:}  /tmp/${ASSET}" | sha256sum -c - || {
        echo "FATAL: ${ASSET} digest mismatch (advertised ${DIGEST})" >&2; exit 1; }
else
    echo "WARN: no digest available (API unavailable?) - falling back to format checks" >&2
    head -c4 "/tmp/${ASSET}" | od -An -tx1 | grep -q '7f 45 4c 46' \
        || { echo "FATAL: ${ASSET} is not an ELF binary" >&2; exit 1; }
    [ "$(stat -c%s "/tmp/${ASSET}")" -gt 50000000 ] \
        || { echo "FATAL: ${ASSET} is implausibly small" >&2; exit 1; }
fi

install -d /usr/share/godothub
install -m 755 "/tmp/${ASSET}" /usr/share/godothub/GodotHub.AppImage
echo "$VER" > /usr/share/godothub/version
rm -f "/tmp/${ASSET}"

echo "GodotHub staged: version ${VER}"
