#!/usr/bin/env bash
# Cross-compile darkfi-mobile-ffi for iOS and generate Swift bindings.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUST="$ROOT/rust"
MODULES="$ROOT/modules/Sources/DarkfiCore"
XCFRAMEWORK="$MODULES/DarkfiCore.xcframework"
export CARGO_HOME="$ROOT/.cargo-home"

echo "Installing required Rust targets for iOS..."
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios

echo "Building for iOS targets..."

cd "$RUST"
cargo build --release --target aarch64-apple-ios -p darkfi-mobile-ffi
cargo build --release --target aarch64-apple-ios-sim -p darkfi-mobile-ffi
cargo build --release --target x86_64-apple-ios -p darkfi-mobile-ffi

# Combine simulator architectures
lipo -create -output target/universal-sim-libdarkfi_mobile_ffi.a \
    target/aarch64-apple-ios-sim/release/libdarkfi_mobile_ffi.a \
    target/x86_64-apple-ios/release/libdarkfi_mobile_ffi.a

# Create XCFramework
mkdir -p "$MODULES"
rm -rf "$XCFRAMEWORK"

# Regenerate Swift/FFI glue from the UDL (writes DarkfiMobileFfi.* per uniffi.toml).
cargo run --bin uniffi-bindgen generate \
    darkfi-mobile-ffi/src/darkfi_mobile_ffi.udl \
    --language swift \
    --crate darkfi_mobile_ffi \
    --out-dir "$MODULES" \
    --no-format

# Package the canonical FFI headers into the xcframework bundle.
rm -rf "$ROOT/rust/target/Headers"
mkdir -p "$ROOT/rust/target/Headers"
cp "$MODULES/DarkfiMobileFfiFFI.h" "$ROOT/rust/target/Headers/"
cp "$MODULES/DarkfiMobileFfiFFI.modulemap" "$ROOT/rust/target/Headers/module.modulemap"

xcodebuild -create-xcframework \
    -library target/aarch64-apple-ios/release/libdarkfi_mobile_ffi.a \
    -headers target/Headers \
    -library target/universal-sim-libdarkfi_mobile_ffi.a \
    -headers target/Headers \
    -output "$XCFRAMEWORK"

echo "Build complete. XCFramework generated in $MODULES"
