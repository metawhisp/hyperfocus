#!/usr/bin/env bash
# release.sh — build, Developer-ID sign, notarize and package Hyperfocus for distribution.
#
# One-time setup (stores your app-specific password in the keychain — this script never sees it):
#   xcrun notarytool store-credentials hyperfocus-notary \
#       --apple-id andrewdyuzhov@gmail.com --team-id 6D6948Z4MW
#   (create an app-specific password at https://account.apple.com → Sign-In & Security → App-Specific Passwords)
#
# Then just run:  ./scripts/release.sh
set -euo pipefail
cd "$(dirname "$0")/.."

IDENTITY="Developer ID Application: Andrey Dyuzhov (6D6948Z4MW)"
TEAM_ID="6D6948Z4MW"
PROFILE="hyperfocus-notary"
ENT="Hyperfocus/Resources/Hyperfocus.entitlements"
DERIVED="build/release"
APP="$DERIVED/Build/Products/Release/Hyperfocus.app"
DIST="build/dist"
DMG="$DIST/Hyperfocus.dmg"

echo "▸ [1/6] Generating project + universal Release build (arm64 + x86_64)…"
xcodegen >/dev/null
xcodebuild -project Hyperfocus.xcodeproj -scheme Hyperfocus -configuration Release \
  -derivedDataPath "$DERIVED" ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=NO clean build >/dev/null
echo "  built: $APP"
lipo -archs "$APP/Contents/MacOS/Hyperfocus"

echo "▸ [2/6] Signing with Developer ID + hardened runtime + secure timestamp…"
codesign --force --options runtime --timestamp --entitlements "$ENT" \
  --sign "$IDENTITY" "$APP"
codesign --verify --strict --verbose=2 "$APP"
echo "  signed OK"

echo "▸ [3/6] Zipping for notarization…"
mkdir -p "$DIST"
ZIP="$DIST/Hyperfocus-notarize.zip"
ditto -c -k --keepParent "$APP" "$ZIP"

if ! xcrun notarytool history --keychain-profile "$PROFILE" >/dev/null 2>&1; then
  echo ""
  echo "✋ Notary profile '$PROFILE' not found. Run this ONCE (it prompts for your"
  echo "   app-specific password — this script never sees it), then re-run release.sh:"
  echo ""
  echo "   xcrun notarytool store-credentials $PROFILE \\"
  echo "       --apple-id andrewdyuzhov@gmail.com --team-id $TEAM_ID"
  echo ""
  echo "   (Signed app is ready at: $APP — build/sign steps are done.)"
  exit 2
fi

echo "▸ [4/6] Submitting to Apple notary service (waits for the verdict)…"
xcrun notarytool submit "$ZIP" --keychain-profile "$PROFILE" --wait

echo "▸ [5/6] Stapling the ticket onto the app…"
xcrun stapler staple "$APP"
spctl -a -vvv --type execute "$APP"

echo "▸ [6/7] Building the drag-install DMG (notarize the DMG itself, then staple)…"
rm -f "$DMG"
STAGE="$(mktemp -d)"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Hyperfocus" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"
# The DMG must be notarized too or `stapler staple` on it fails (only the app was submitted above).
xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$DMG"

echo "▸ [7/7] Signing the update + regenerating the Sparkle appcast (docs/appcast.xml)…"
# EdDSA signature comes from the key in the login keychain (created once via generate_keys);
# versions are read from the DMG itself. The enclosure URL pins the versioned GitHub asset.
VERSION=$(defaults read "$PWD/$APP/Contents/Info.plist" CFBundleShortVersionString)
GEN_APPCAST=$(find "$DERIVED/SourcePackages/artifacts" -type f -name generate_appcast -path "*/bin/*" | head -1)
if [ -z "$GEN_APPCAST" ]; then
  echo "✋ generate_appcast not found under $DERIVED/SourcePackages — resolve SPM packages first." >&2
  exit 3
fi
"$GEN_APPCAST" --download-url-prefix "https://github.com/metawhisp/hyperfocus/releases/download/v${VERSION}/" \
  -o docs/appcast.xml "$DIST"
echo "   appcast → docs/appcast.xml (deploy the site to publish the update)"

echo ""
echo "✅ Done. Distributable, notarized: $DMG"
echo "   Opens on any macOS 15+ Mac (Apple Silicon + Intel) with a double-click."
echo "   Next: gh release create v${VERSION} $DMG  +  deploy docs/ (appcast)."
