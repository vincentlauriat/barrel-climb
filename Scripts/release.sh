#!/usr/bin/env bash
# Build a Release "Barrel Climb.app", Developer ID sign it with the Hardened Runtime,
# notarize it with Apple, staple the ticket, package it as a DMG, EdDSA-sign that DMG
# for Sparkle, and write the appcast the in-app updater reads.
#
# ┌────────────────────────────────────────────────────────────────────────────┐
# │ SPARKLE SIGNING KEY — DO NOT REGENERATE                                    │
# │                                                                            │
# │ Updates are EdDSA-signed with the private key held in the login keychain   │
# │ under the account "BarrelClimb" (generated 2026-09-15, used by sign_update  │
# │ below). Its public half is embedded in the app as SUPublicEDKey in          │
# │ project.yml:                                                               │
# │     ZHNhjzBxHMkQSm/fnMFJ0uQkwH7U7wymROlaOKg0kMA=                           │
# │                                                                            │
# │ NEVER run `generate_keys` again for this account and NEVER change          │
# │ SUPublicEDKey: every already-installed copy would reject all future        │
# │ updates and each user would have to re-download by hand. Back the key up   │
# │ once, somewhere safe, so it cannot be lost:                                │
# │     ./.sparkle-tools/bin/generate_keys -x backup.txt --account BarrelClimb  │
# │                                                                            │
# │ This account is specific to Barrel Climb. Other apps in the fleet have     │
# │ their own keys — never share one between apps.                             │
# └────────────────────────────────────────────────────────────────────────────┘
#
# Usage: ./Scripts/release.sh <version>       e.g. ./Scripts/release.sh 1.0.0
#
# Prerequisites (one-time, already in place on this Mac):
#   - "Developer ID Application: Vincent LAURIAT (KFLACS69T9)" in the login keychain.
#   - notarytool credentials under the shared keychain profile "AppliMacVincentGithub".
#     Check with: xcrun notarytool history --keychain-profile "AppliMacVincentGithub"
#     It is account-scoped, not per-project — do not create a new one per app.
#
# Overrides:
#   SIGNING_IDENTITY="Developer ID Application: …"  ./Scripts/release.sh 1.0.0
#   NOTARY_PROFILE="AppliMacVincentGithub"          ./Scripts/release.sh 1.0.0
#   SKIP_NOTARIZE=1                                 ./Scripts/release.sh 1.0.0   # dry run
#
# Outputs release/BarrelClimb-<version>.dmg and docs/appcast.xml. Does NOT publish:
# it prints the two commands that do.

set -euo pipefail

VERSION="${1:?Usage: ./Scripts/release.sh <version>   (e.g. ./Scripts/release.sh 1.0.0)}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="Barrel Climb"
DMG_BASENAME="BarrelClimb"
SPARKLE_ACCOUNT="BarrelClimb"
SPARKLE_VERSION="2.9.1"
REPO="vincentlauriat/barrel-climb"
FEED_HOST="https://vincentlauriat.github.io/barrel-climb"
MIN_MACOS="14.0"

SIGNING_IDENTITY="${SIGNING_IDENTITY:-Developer ID Application: Vincent LAURIAT (KFLACS69T9)}"
NOTARY_PROFILE="${NOTARY_PROFILE:-AppliMacVincentGithub}"

# ---------------------------------------------------------------- 1. sanity checks

if ! grep -q "MARKETING_VERSION: \"$VERSION\"" project.yml; then
  echo "✗ MARKETING_VERSION in project.yml does not match $VERSION" >&2
  grep "MARKETING_VERSION" project.yml | sed 's/^/    /' >&2
  echo "  Bump project.yml first, then re-run." >&2
  exit 1
fi

# Sparkle compares the appcast's <sparkle:version> against the installed app's
# CFBundleVersion. Shipping two different releases with the same build number leaves
# every existing install convinced it is already up to date.
if git rev-parse "v$VERSION" >/dev/null 2>&1; then
  echo "✗ Tag v$VERSION already exists. Bump the version before releasing again." >&2
  exit 1
fi

for tool in xcodegen xcodebuild hdiutil; do
  command -v "$tool" >/dev/null 2>&1 || { echo "✗ $tool not found" >&2; exit 1; }
done

# ---------------------------------------------------------------- 2. build

echo "→ xcodegen generate"
xcodegen generate >/dev/null

# CODE_SIGNING_ALLOWED=NO on purpose: Xcode's post-build lsregister stamps
# com.apple.provenance xattrs that make a later `codesign --force` fail with
# "resource fork, Finder information, or similar detritus not allowed". We sign by
# hand below, after a ditto that strips those xattrs.
echo "→ xcodebuild Release"
xcodebuild -project DonkeyKong.xcodeproj \
  -scheme DonkeyKong \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  -quiet build

APP="$ROOT/build/DerivedData/Build/Products/Release/$APP_NAME.app"
[ -d "$APP" ] || { echo "✗ Build did not produce $APP" >&2; exit 1; }

BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP/Contents/Info.plist")
echo "→ Built $APP_NAME $VERSION (CFBundleVersion $BUILD_NUMBER)"

# ---------------------------------------------------------------- 3. sign

STAGING_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGING_DIR"' EXIT
STAGING="$STAGING_DIR/$APP_NAME.app"
echo "→ Staging to $STAGING_DIR"
ditto --norsrc --noextattr --noacl "$APP" "$STAGING"

# Apple's timestamp server is intermittently flaky ("A timestamp was expected but was
# not found"), so every signature gets a few attempts before we give up.
codesign_ts() {
  local target="$1" attempt
  for attempt in 1 2 3 4 5; do
    if codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$target"; then
      return 0
    fi
    [ "$attempt" -lt 5 ] && { echo "  ↻ codesign failed ($attempt/5), retrying in 5s…"; sleep 5; }
  done
  echo "✗ codesign $target failed after 5 attempts" >&2
  return 1
}

# Nested code must be signed before the bundle that contains it.
SPARKLE_FW="$STAGING/Contents/Frameworks/Sparkle.framework"
if [ -d "$SPARKLE_FW" ]; then
  echo "→ Codesigning Sparkle.framework, deepest binaries first"
  SPARKLE_VER="$SPARKLE_FW/Versions/B"
  codesign_ts "$SPARKLE_VER/Autoupdate"
  codesign_ts "$SPARKLE_VER/XPCServices/Downloader.xpc"
  codesign_ts "$SPARKLE_VER/XPCServices/Installer.xpc"
  codesign_ts "$SPARKLE_VER/Updater.app"
  codesign_ts "$SPARKLE_FW"
else
  echo "✗ Sparkle.framework is not embedded — the updater would be dead on arrival" >&2
  exit 1
fi

echo "→ Codesigning the app with Developer ID + Hardened Runtime"
codesign_ts "$STAGING"
codesign --verify --strict --deep "$STAGING"

# ---------------------------------------------------------------- 4. package

RELEASE_DIR="$ROOT/release"
mkdir -p "$RELEASE_DIR"
DMG="$RELEASE_DIR/$DMG_BASENAME-$VERSION.dmg"
rm -f "$DMG"

LAYOUT="$STAGING_DIR/dmg"
mkdir -p "$LAYOUT"
ditto --norsrc --noextattr --noacl "$STAGING" "$LAYOUT/$APP_NAME.app"
ln -s /Applications "$LAYOUT/Applications"

echo "→ Creating $DMG"
hdiutil create -volname "$APP_NAME $VERSION" -srcfolder "$LAYOUT" \
  -fs HFS+ -format UDZO -imagekey zlib-level=9 -ov "$DMG" >/dev/null

# ---------------------------------------------------------------- 5. notarize

if [ "${SKIP_NOTARIZE:-0}" = "1" ]; then
  echo "⚠ SKIP_NOTARIZE=1 — dry run, the DMG is signed but NOT notarized. Do not ship it."
else
  echo "→ Submitting to Apple's notary service (2–5 min)"
  xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait

  echo "→ Stapling the ticket"
  xcrun stapler staple "$DMG"
  xcrun stapler validate "$DMG"

  # Independent check: do not trust the steps above having printed success.
  spctl -a -t open --context context:primary-signature -vv "$DMG"
fi

# ---------------------------------------------------------------- 6. appcast

SPARKLE_TOOLS="$ROOT/.sparkle-tools"
if [ ! -x "$SPARKLE_TOOLS/bin/sign_update" ]; then
  echo "→ Fetching Sparkle $SPARKLE_VERSION tools (one-time)"
  mkdir -p "$SPARKLE_TOOLS"
  curl -fsSL "https://github.com/sparkle-project/Sparkle/releases/download/$SPARKLE_VERSION/Sparkle-$SPARKLE_VERSION.tar.xz" \
    | tar -xJ -C "$SPARKLE_TOOLS"
fi

echo "→ EdDSA-signing the DMG"
# sign_update prints a ready-made attribute pair: sparkle:edSignature="…" length="…"
# so the <enclosure> below must not carry its own length attribute.
#
# The first time a given binary reads this keychain item, macOS puts up an
# authorization panel and sign_update blocks until someone clicks Always Allow. That
# panel never arrives in a headless run, and a silent hang is the worst outcome: the
# DMG is already built, signed, notarized and stapled by this point. Time it out and
# say what to do instead.
#
# macOS ships no `timeout`, so the watchdog is a background sleep that kills the signer.
sign_with_watchdog() {
  local out="$STAGING_DIR/sig.txt" pid
  "$SPARKLE_TOOLS/bin/sign_update" --account "$SPARKLE_ACCOUNT" "$DMG" >"$out" 2>/dev/null &
  pid=$!
  ( sleep 60; kill -0 "$pid" 2>/dev/null && kill "$pid" 2>/dev/null ) &
  local watchdog=$!
  wait "$pid"; local rc=$?
  kill "$watchdog" 2>/dev/null || true
  [ "$rc" -eq 0 ] || return "$rc"
  cat "$out"
}
if ! SPARKLE_SIG_LINE=$(sign_with_watchdog); then
  echo "" >&2
  echo "✗ sign_update could not read the '$SPARKLE_ACCOUNT' key from the login keychain." >&2
  echo "  macOS is almost certainly waiting on an authorization panel. Unlock the Mac," >&2
  echo "  re-run this script, and click 'Always Allow' when asked. The DMG below is" >&2
  echo "  finished and valid — only the appcast is missing." >&2
  echo "" >&2
  echo "  DMG: $DMG" >&2
  exit 2
fi

# The appcast is served by the same GitHub Pages site as the landing page, which is
# why it is written into docs/ rather than the repo root. SUFeedURL in project.yml
# must keep pointing at $FEED_HOST/appcast.xml.
APPCAST="$ROOT/docs/appcast.xml"
PUB_DATE=$(date -R)
echo "→ Writing $APPCAST (sparkle:version=$BUILD_NUMBER, shortVersionString=$VERSION)"
cat > "$APPCAST" <<APPCAST_XML
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Barrel Climb</title>
    <link>$FEED_HOST/appcast.xml</link>
    <description>Barrel Climb release feed</description>
    <language>en</language>
    <item>
      <title>v$VERSION</title>
      <pubDate>$PUB_DATE</pubDate>
      <sparkle:version>$BUILD_NUMBER</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>$MIN_MACOS</sparkle:minimumSystemVersion>
      <sparkle:releaseNotesLink>https://github.com/$REPO/releases/tag/v$VERSION</sparkle:releaseNotesLink>
      <enclosure
        url="https://github.com/$REPO/releases/download/v$VERSION/$DMG_BASENAME-$VERSION.dmg"
        type="application/octet-stream"
        $SPARKLE_SIG_LINE />
    </item>
  </channel>
</rss>
APPCAST_XML

xmllint --noout "$APPCAST" && echo "→ appcast.xml is well-formed"

# ---------------------------------------------------------------- 7. next steps

NOTES="$RELEASE_DIR/release-notes-$VERSION.md"
[ -f "$NOTES" ] || echo "⚠ No release notes at $NOTES — write them before publishing."

echo ""
echo "✅ $DMG ($(ls -lh "$DMG" | awk '{print $5}'))"
echo "✅ docs/appcast.xml written for v$VERSION"
echo ""
echo "To publish:"
echo "  1. gh release create v$VERSION \"$DMG\" --title \"v$VERSION\" --notes-file \"$NOTES\""
echo "  2. git add docs/appcast.xml && git commit -m 'docs: appcast for v$VERSION' && git push"
echo ""
echo "Order matters: the appcast points at the release asset, so publish the release first."
