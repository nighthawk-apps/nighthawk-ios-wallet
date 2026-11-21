#!/usr/bin/env bash
# Cross-compile shared darkfi-mobile-ffi for iOS and generate Swift bindings.
# Canonical crate: ../nighthawk-android-wallet/rust/darkfi-mobile-ffi
# (also linked from /Users/anon/GitHub/darkfi-mobile-ffi).
set -euo pipefail

# Same crate as the Android script, outside the DarkFi toolchain file.
# Nightly after 2026-11-11 cannot compile branches 0.4.6.
export RUSTUP_TOOLCHAIN="${RUSTUP_TOOLCHAIN:-stable}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AND_RUST="$(cd "$ROOT/../nighthawk-android-wallet/rust" && pwd)"
FFI_SRC="$AND_RUST/darkfi-mobile-ffi"
MODULES="$ROOT/modules/Sources/DarkfiCore"
XCFRAMEWORK="$MODULES/DarkfiCore.xcframework"
export CARGO_HOME="$ROOT/.cargo-home"
# Keep artifacts under the iOS tree.
export CARGO_TARGET_DIR="$ROOT/rust/target"

IOS_DEPLOY="${IPHONEOS_DEPLOYMENT_TARGET:-17.0}"

echo "Building shared darkfi-mobile-ffi for iOS from $FFI_SRC ..."

SIM_ONLY="${SIM_ONLY:-0}"
DEVICE_ONLY="${DEVICE_ONLY:-0}"
if [ "$SIM_ONLY" = "1" ] && [ "$DEVICE_ONLY" = "1" ]; then
  echo "SIM_ONLY and DEVICE_ONLY are mutually exclusive" >&2
  exit 1
fi

cd "$AND_RUST"

# --lib: skip localnet_tx (required-features = ["localnet"]).
if [ "$DEVICE_ONLY" != "1" ]; then
  IPHONEOS_DEPLOYMENT_TARGET="$IOS_DEPLOY" \
    cargo build --release --lib --target aarch64-apple-ios-sim -p darkfi-mobile-ffi
  cp "$CARGO_TARGET_DIR/aarch64-apple-ios-sim/release/libdarkfi_mobile_ffi.a" \
    "$CARGO_TARGET_DIR/universal-sim-libdarkfi_mobile_ffi.a"
fi

if [ "$SIM_ONLY" != "1" ]; then
  IPHONEOS_DEPLOYMENT_TARGET="$IOS_DEPLOY" \
    cargo build --release --lib --target aarch64-apple-ios -p darkfi-mobile-ffi
fi

mkdir -p "$MODULES"
rm -rf "$XCFRAMEWORK"

BINDGEN_OUT="$(mktemp -d)"
cargo run --bin uniffi-bindgen -- generate \
    "$FFI_SRC/src/darkfi_mobile_ffi.udl" \
    --language swift \
    --crate darkfi_mobile_ffi \
    --out-dir "$BINDGEN_OUT" \
    --no-format
# UniFFI 0.32 emits darkfi_mobile_ffi.swift (+ FFI.h / modulemap). Older
# toolchains used DarkfiMobileFfi.swift — accept either.
SWIFT_SRC="$BINDGEN_OUT/darkfi_mobile_ffi.swift"
if [ ! -f "$SWIFT_SRC" ]; then
  SWIFT_SRC="$BINDGEN_OUT/DarkfiMobileFfi.swift"
fi
HDR_SRC="$BINDGEN_OUT/darkfi_mobile_ffiFFI.h"
if [ ! -f "$HDR_SRC" ]; then
  HDR_SRC="$BINDGEN_OUT/DarkfiMobileFfiFFI.h"
fi
sed 's/DarkfiMobileFfiFFI/darkfi_mobile_ffiFFI/g' "$SWIFT_SRC" \
    > "$MODULES/darkfi_mobile_ffi.swift"
cp "$HDR_SRC" "$MODULES/darkfi_mobile_ffiFFI.h"
# modulemap may already be present from a prior bindgen layout
if [ -f "$BINDGEN_OUT/darkfi_mobile_ffiFFI.modulemap" ]; then
  cp "$BINDGEN_OUT/darkfi_mobile_ffiFFI.modulemap" "$MODULES/darkfi_mobile_ffiFFI.modulemap"
fi
rm -rf "$BINDGEN_OUT"

rm -rf "$CARGO_TARGET_DIR/Headers"
mkdir -p "$CARGO_TARGET_DIR/Headers"
cp "$MODULES/darkfi_mobile_ffiFFI.h" "$CARGO_TARGET_DIR/Headers/"
cp "$MODULES/darkfi_mobile_ffiFFI.modulemap" "$CARGO_TARGET_DIR/Headers/module.modulemap"

if [ "$SIM_ONLY" = "1" ]; then
    xcodebuild -create-xcframework \
        -library "$CARGO_TARGET_DIR/universal-sim-libdarkfi_mobile_ffi.a" \
        -headers "$CARGO_TARGET_DIR/Headers" \
        -output "$XCFRAMEWORK"
elif [ "$DEVICE_ONLY" = "1" ]; then
    xcodebuild -create-xcframework \
        -library "$CARGO_TARGET_DIR/aarch64-apple-ios/release/libdarkfi_mobile_ffi.a" \
        -headers "$CARGO_TARGET_DIR/Headers" \
        -output "$XCFRAMEWORK"
else
    xcodebuild -create-xcframework \
        -library "$CARGO_TARGET_DIR/aarch64-apple-ios/release/libdarkfi_mobile_ffi.a" \
        -headers "$CARGO_TARGET_DIR/Headers" \
        -library "$CARGO_TARGET_DIR/universal-sim-libdarkfi_mobile_ffi.a" \
        -headers "$CARGO_TARGET_DIR/Headers" \
        -output "$XCFRAMEWORK"
fi

echo "Wrote $XCFRAMEWORK"
