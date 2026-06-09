#!/usr/bin/env bash
# Cross-compile darkirc for iOS arm64 and bundle the binary.
# The binary is placed into stealth/Resources/ for inclusion in the app bundle.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DARKFI="$ROOT/third_party/darkfi"
OUTPUT_DIR="$ROOT/stealth/Resources"
export CARGO_HOME="$ROOT/.cargo-home"

echo "=== Building darkirc for iOS (aarch64-apple-ios) ==="

# Ensure Rust target is installed
rustup target add aarch64-apple-ios

# Build darkirc binary for iOS
# Note: darkirc has crate-type = ["cdylib"] in lib mode, but we want the binary
cd "$DARKFI"

# Set iOS SDK sysroot
IOS_SDK=$(xcrun --sdk iphoneos --show-sdk-path)
export SDKROOT="$IOS_SDK"
export CARGO_TARGET_AARCH64_APPLE_IOS_LINKER="$(xcrun --sdk iphoneos --find clang)"
export CC_aarch64_apple_ios="$(xcrun --sdk iphoneos --find clang)"
export AR_aarch64_apple_ios="$(xcrun --sdk iphoneos --find ar)"
export CFLAGS_aarch64_apple_ios="-isysroot $IOS_SDK -arch arm64 -mios-version-min=16.0"

cargo build --release --target aarch64-apple-ios --bin darkirc \
    --manifest-path "$DARKFI/bin/darkirc/Cargo.toml"

# Copy binary to app resources
mkdir -p "$OUTPUT_DIR"
cp "$DARKFI/target/aarch64-apple-ios/release/darkirc" "$OUTPUT_DIR/darkirc_exec"
chmod +x "$OUTPUT_DIR/darkirc_exec"

echo "=== darkirc binary placed at: $OUTPUT_DIR/darkirc_exec ==="
echo "=== Add it to the Xcode project 'Copy Bundle Resources' phase ==="
