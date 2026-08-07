#!/usr/bin/env bash
# Cross-compile darkfi-mobile-ffi for iOS and generate Swift bindings.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUST="$ROOT/rust"
MODULES="$ROOT/modules/Sources/DarkfiCore"
XCFRAMEWORK="$MODULES/DarkfiCore.xcframework"
export CARGO_HOME="$ROOT/.cargo-home"

# Pin the iOS deployment target ONLY for cross-compiles (not host tools like
# uniffi-bindgen / aws-lc-sys build scripts). Leaking IPHONEOS_DEPLOYMENT_TARGET
# into host CC causes aws-lc-sys "COMPILER BUG DETECTED" / incompatible-sysroot.
IOS_DEPLOY="${IPHONEOS_DEPLOYMENT_TARGET:-17.0}"

echo "Installing required Rust targets for iOS..."
# rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios

if [[ ! -d "$ROOT/third_party/darkfi/bin/drk" ]]; then
  echo "Expected vendored DarkFi — run ./scripts/vendor-darkfi.sh first." >&2
  exit 1
fi
"$ROOT/scripts/compile-darkfi-zkas-proofs.sh"

echo "Building for iOS targets..."

# Allow building only the simulator slice for a faster local iteration:
#   SIM_ONLY=1 ./scripts/build-darkfi-mobile-ffi-ios.sh
# Device-only (physical iPhone deploy; skips simulator jemalloc/host work):
#   DEVICE_ONLY=1 ./scripts/build-darkfi-mobile-ffi-ios.sh
#
# IMPORTANT — XCFramework binaries (*.a) are gitignored (~500MB). A fresh clone
# does NOT contain libdarkfi_mobile_ffi.a. You MUST run this script (full build,
# not SIM_ONLY) before Archive / TestFlight / device deploy, or linking fails /
# you ship a stale framework. Headers + Swift glue are tracked; the .a files are not.
SIM_ONLY="${SIM_ONLY:-0}"
DEVICE_ONLY="${DEVICE_ONLY:-0}"
if [ "$SIM_ONLY" = "1" ] && [ "$DEVICE_ONLY" = "1" ]; then
  echo "SIM_ONLY and DEVICE_ONLY are mutually exclusive" >&2
  exit 1
fi
if [ "$SIM_ONLY" = "1" ]; then
  echo "WARNING: SIM_ONLY=1 — device slice omitted. Do NOT Archive/TestFlight this XCFramework." >&2
fi

cd "$RUST"

# Simulator slice (Apple-silicon simulator).
if [ "$DEVICE_ONLY" != "1" ]; then
  IPHONEOS_DEPLOYMENT_TARGET="$IOS_DEPLOY" \
    cargo build --release --target aarch64-apple-ios-sim -p darkfi-mobile-ffi
  cp target/aarch64-apple-ios-sim/release/libdarkfi_mobile_ffi.a target/universal-sim-libdarkfi_mobile_ffi.a
fi

# Device slice (real iPhone/iPad, arm64). Required to run on a physical device.
if [ "$SIM_ONLY" != "1" ]; then
    IPHONEOS_DEPLOYMENT_TARGET="$IOS_DEPLOY" \
      cargo build --release --target aarch64-apple-ios -p darkfi-mobile-ffi
fi

# Create XCFramework
mkdir -p "$MODULES"
rm -rf "$XCFRAMEWORK"

# Regenerate Swift/FFI glue from the UDL (UniFFI 0.32 emits PascalCase names).
# Host build — do NOT export IPHONEOS_DEPLOYMENT_TARGET here.
cargo run --bin uniffi-bindgen generate \
    darkfi-mobile-ffi/src/darkfi_mobile_ffi.udl \
    --language swift \
    --crate darkfi_mobile_ffi \
    --out-dir "$MODULES" \
    --no-format

# Normalize UniFFI 0.32 PascalCase outputs to the snake_case names Xcode expects.
if [[ -f "$MODULES/DarkfiMobileFfi.swift" ]]; then
  sed 's/DarkfiMobileFfiFFI/darkfi_mobile_ffiFFI/g' "$MODULES/DarkfiMobileFfi.swift" \
    > "$MODULES/darkfi_mobile_ffi.swift"
  rm -f "$MODULES/DarkfiMobileFfi.swift"
elif [[ -f "$MODULES/darkfi_mobile_ffi.swift" ]]; then
  sed -i '' 's/DarkfiMobileFfiFFI/darkfi_mobile_ffiFFI/g' "$MODULES/darkfi_mobile_ffi.swift"
fi
if [[ -f "$MODULES/DarkfiMobileFfiFFI.h" ]]; then
  sed 's/DarkfiMobileFfiFFI/darkfi_mobile_ffiFFI/g' "$MODULES/DarkfiMobileFfiFFI.h" \
    > "$MODULES/darkfi_mobile_ffiFFI.h"
  rm -f "$MODULES/DarkfiMobileFfiFFI.h"
fi
if [[ -f "$MODULES/DarkfiMobileFfiFFI.modulemap" ]]; then
  sed 's/DarkfiMobileFfiFFI/darkfi_mobile_ffiFFI/g' "$MODULES/DarkfiMobileFfiFFI.modulemap" \
    > "$MODULES/darkfi_mobile_ffiFFI.modulemap"
  rm -f "$MODULES/DarkfiMobileFfiFFI.modulemap"
fi

# Package the canonical FFI headers into the xcframework bundle.
rm -rf "$ROOT/rust/target/Headers"
mkdir -p "$ROOT/rust/target/Headers"
cp "$MODULES/darkfi_mobile_ffiFFI.h" "$ROOT/rust/target/Headers/"
cp "$MODULES/darkfi_mobile_ffiFFI.modulemap" "$ROOT/rust/target/Headers/module.modulemap"

if [ "$SIM_ONLY" = "1" ]; then
    xcodebuild -create-xcframework \
        -library target/universal-sim-libdarkfi_mobile_ffi.a \
        -headers target/Headers \
        -output "$XCFRAMEWORK"
elif [ "$DEVICE_ONLY" = "1" ]; then
    xcodebuild -create-xcframework \
        -library target/aarch64-apple-ios/release/libdarkfi_mobile_ffi.a \
        -headers target/Headers \
        -output "$XCFRAMEWORK"
else
    xcodebuild -create-xcframework \
        -library target/aarch64-apple-ios/release/libdarkfi_mobile_ffi.a \
        -headers target/Headers \
        -library target/universal-sim-libdarkfi_mobile_ffi.a \
        -headers target/Headers \
        -output "$XCFRAMEWORK"
fi

# Fail closed if expected slices are missing (common after SIM_ONLY or interrupted builds).
if [ "$SIM_ONLY" != "1" ] && [ ! -f "$XCFRAMEWORK/ios-arm64/libdarkfi_mobile_ffi.a" ]; then
  echo "ERROR: device slice missing at $XCFRAMEWORK/ios-arm64/libdarkfi_mobile_ffi.a" >&2
  exit 1
fi
if [ "$DEVICE_ONLY" != "1" ] && [ ! -f "$XCFRAMEWORK/ios-arm64-simulator/universal-sim-libdarkfi_mobile_ffi.a" ] \
  && [ ! -f "$XCFRAMEWORK/ios-arm64-simulator/libdarkfi_mobile_ffi.a" ]; then
  # xcodebuild may name the sim library differently; accept any .a under the sim slice.
  if ! compgen -G "$XCFRAMEWORK/ios-arm64-simulator/*.a" >/dev/null; then
    echo "ERROR: simulator slice missing under $XCFRAMEWORK/ios-arm64-simulator/" >&2
    exit 1
  fi
fi

echo "Build complete. XCFramework generated in $MODULES"
echo "Reminder: *.a files are gitignored — rebuild before every TestFlight Archive."
