#!/bin/zsh
# Packages the existing app with a drag-to-Applications install shortcut.
set -euo pipefail
cd "$(dirname "$0")/.."

APP=build/Keepy.app
[[ -d "$APP" ]] || { echo "Run ./build.sh first." >&2; exit 1; }
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")
STAGING=$(mktemp -d "${TMPDIR:-/tmp}/keepy-dmg.XXXXXX")
trap 'rm -rf "$STAGING"' EXIT
ditto "$APP" "$STAGING/Keepy.app"
ln -s /Applications "$STAGING/Applications"
cat > "$STAGING/Install.txt" <<'TXT'
Keepy — macOS 15 or later

Drag Keepy.app onto Applications, then eject this disk image.

This release is ad-hoc signed and is not notarized by Apple. macOS may
block the first launch. If you trust this download, attempt to open the
app, then use System Settings > Privacy & Security > Open Anyway.
TXT
OUTPUT="build/Keepy-${VERSION}.dmg"
hdiutil create -volname Keepy -srcfolder "$STAGING" -format UDZO -ov "$OUTPUT"
hdiutil verify "$OUTPUT"
(cd build && shasum -a 256 "${OUTPUT:t}" > "${OUTPUT:t}.sha256")
echo "Created $OUTPUT"
