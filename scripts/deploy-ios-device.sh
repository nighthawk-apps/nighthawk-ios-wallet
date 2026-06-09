#!/usr/bin/env bash
# Clean, rebuild native FFI + iOS app, install and launch on a connected iPhone.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEME="${SCHEME:-stealth-testnet}"
DERIVED_DATA="${DERIVED_DATA:-$ROOT/build/DerivedData}"
BUNDLE_ID="com.nighthawkapps.wallet.ios"
DEVICE_ID="${DEVICE_ID:-}"

echo "==> Cleaning DerivedData and Rust artifacts"
rm -rf "$DERIVED_DATA"
(cd "$ROOT/rust" && cargo clean)

echo "==> Building darkfi-mobile-ffi for iOS"
"$ROOT/scripts/build-darkfi-mobile-ffi-ios.sh"

echo "==> Resolving destination"
if [[ -z "$DEVICE_ID" ]]; then
  DEVICE_ID="$(xcrun xctrace list devices 2>/dev/null | awk -F'[()]' '/^== Devices ==$/{found=1;next} found && /iPhone/ && !/Simulator/ && !/Offline/ {print $(NF-1); exit}')"
fi

if [[ -z "$DEVICE_ID" ]]; then
  echo "No connected iPhone found. Plug in your device, unlock it, tap Trust, then rerun." >&2
  echo "Or set DEVICE_ID explicitly, e.g. DEVICE_ID=00008130-0002083902F8001C $0" >&2
  exit 1
fi

echo "Using device: $DEVICE_ID"

DESTINATION="id=$DEVICE_ID"

echo "==> Building $SCHEME for device"
xcodebuild \
  -project "$ROOT/stealth.xcodeproj" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA" \
  -skipMacroValidation \
  -allowProvisioningUpdates \
  clean build

APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphoneos/${SCHEME}.app"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Expected app bundle at $APP_PATH" >&2
  exit 1
fi

echo "==> Installing on device"
xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"

echo "==> Launching $BUNDLE_ID"
xcrun devicectl device process launch --device "$DEVICE_ID" "$BUNDLE_ID"

echo "Done. $SCHEME is running on the device."
