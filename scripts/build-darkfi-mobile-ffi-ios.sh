#!/usr/bin/env bash
# Cross-compile shared blackhawk UniFFI core for iOS and generate Swift bindings.
# Canonical crate: ../blackhawk (or BLACKHAWK_ROOT override).
set -euo pipefail

# Same crate as the Android script, outside the DarkFi toolchain file.
# Nightly after 2026-11-11 cannot compile branches 0.4.6.
export RUSTUP_TOOLCHAIN="${RUSTUP_TOOLCHAIN:-stable}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BLACKHAWK_ROOT="${BLACKHAWK_ROOT:-$(cd "$ROOT/../blackhawk" && pwd)}"
FFI_SRC="$BLACKHAWK_ROOT/crates/blackhawk"
MODULES="$ROOT/modules/Sources/DarkfiCore"
XCFRAMEWORK="$MODULES/DarkfiCore.xcframework"
export CARGO_HOME="$ROOT/.cargo-home"
# Keep artifacts under the iOS tree.
export CARGO_TARGET_DIR="$ROOT/rust/target"

IOS_DEPLOY="${IPHONEOS_DEPLOYMENT_TARGET:-17.0}"

echo "Building shared blackhawk for iOS from $FFI_SRC ..."

SIM_ONLY="${SIM_ONLY:-0}"
DEVICE_ONLY="${DEVICE_ONLY:-0}"
if [ "$SIM_ONLY" = "1" ] && [ "$DEVICE_ONLY" = "1" ]; then
  echo "SIM_ONLY and DEVICE_ONLY are mutually exclusive" >&2
  exit 1
fi

cd "$BLACKHAWK_ROOT"

# --lib: skip localnet_tx (required-features = ["localnet"]).
if [ "$DEVICE_ONLY" != "1" ]; then
  IPHONEOS_DEPLOYMENT_TARGET="$IOS_DEPLOY" \
    cargo build --release --lib --target aarch64-apple-ios-sim -p blackhawk
  cp "$CARGO_TARGET_DIR/aarch64-apple-ios-sim/release/libblackhawk.a" \
    "$CARGO_TARGET_DIR/universal-sim-libblackhawk.a"
fi

if [ "$SIM_ONLY" != "1" ]; then
  IPHONEOS_DEPLOYMENT_TARGET="$IOS_DEPLOY" \
    cargo build --release --lib --target aarch64-apple-ios -p blackhawk
fi

mkdir -p "$MODULES"
rm -rf "$XCFRAMEWORK"

BINDGEN_OUT="$(mktemp -d)"
cargo run -p blackhawk --bin uniffi-bindgen -- generate \
    "$FFI_SRC/src/blackhawk.udl" \
    --language swift \
    --crate blackhawk \
    --config "$FFI_SRC/uniffi.toml" \
    --metadata-no-deps \
    --out-dir "$BINDGEN_OUT" \
    --no-format
SWIFT_SRC="$BINDGEN_OUT/blackhawk.swift"
HDR_SRC="$BINDGEN_OUT/blackhawkFFI.h"
MMAP_SRC="$BINDGEN_OUT/blackhawkFFI.modulemap"
cp "$SWIFT_SRC" "$MODULES/blackhawk.swift"
cp "$HDR_SRC" "$MODULES/blackhawkFFI.h"
if [ -f "$MMAP_SRC" ]; then
  cp "$MMAP_SRC" "$MODULES/blackhawkFFI.modulemap"
fi
rm -rf "$BINDGEN_OUT"

rm -rf "$CARGO_TARGET_DIR/Headers"
mkdir -p "$CARGO_TARGET_DIR/Headers"
cp "$MODULES/blackhawkFFI.h" "$CARGO_TARGET_DIR/Headers/"
cp "$MODULES/blackhawkFFI.modulemap" "$CARGO_TARGET_DIR/Headers/module.modulemap"

if [ "$SIM_ONLY" = "1" ]; then
    xcodebuild -create-xcframework \
        -library "$CARGO_TARGET_DIR/universal-sim-libblackhawk.a" \
        -headers "$CARGO_TARGET_DIR/Headers" \
        -output "$XCFRAMEWORK"
elif [ "$DEVICE_ONLY" = "1" ]; then
    xcodebuild -create-xcframework \
        -library "$CARGO_TARGET_DIR/aarch64-apple-ios/release/libblackhawk.a" \
        -headers "$CARGO_TARGET_DIR/Headers" \
        -output "$XCFRAMEWORK"
else
    xcodebuild -create-xcframework \
        -library "$CARGO_TARGET_DIR/aarch64-apple-ios/release/libblackhawk.a" \
        -headers "$CARGO_TARGET_DIR/Headers" \
        -library "$CARGO_TARGET_DIR/universal-sim-libblackhawk.a" \
        -headers "$CARGO_TARGET_DIR/Headers" \
        -output "$XCFRAMEWORK"
fi

echo "Wrote $XCFRAMEWORK"
