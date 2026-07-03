#!/usr/bin/env bash
# install-dev.sh — build the app and install ONE canonical copy to /Applications with a STABLE
# Developer-ID signature. Because the identity never changes across rebuilds, macOS keeps the
# camera / screen-recording permission instead of treating every build as a new app
# ("access in a previous version"). Run this instead of launching straight from DerivedData.
set -euo pipefail
cd "$(dirname "$0")/.."

IDENTITY="Developer ID Application: Andrey Dyuzhov (6D6948Z4MW)"
ENT="Hyperfocus/Resources/Hyperfocus.entitlements"
DERIVED="build/dev"
APP="$DERIVED/Build/Products/Debug/Hyperfocus.app"
DEST="/Applications/Hyperfocus.app"

echo "▸ building Debug…"
xcodegen >/dev/null
xcodebuild -project Hyperfocus.xcodeproj -scheme Hyperfocus -configuration Debug \
  -derivedDataPath "$DERIVED" build >/dev/null

echo "▸ signing with a stable Developer ID identity (keeps TCC permission across rebuilds)…"
codesign --force --entitlements "$ENT" --sign "$IDENTITY" "$APP"
codesign --verify --strict "$APP"

echo "▸ installing to $DEST…"
pkill -x Hyperfocus 2>/dev/null || true
sleep 1
rm -rf "$DEST"
cp -R "$APP" "$DEST"
echo "  done — launch /Applications/Hyperfocus.app (this is the canonical version)."
