#!/bin/bash
# Pre-publishing checks for iOS Wallet

set -e

echo "Running Pre-Publishing Checks..."

FAILED=0

# 1. Debug log scan
echo "[1/4] Checking for debug logs (print, NSLog)..."
if git grep -qE "(^|[[:space:]])(print|println|NSLog)\(" -- "modules/Sources/"; then
    echo "❌ Found debug logging statements! These must be removed or gated."
    FAILED=1
else
    echo "✅ No stray debug logs found."
fi

# 2. Sensitive terms near logs or telemetry
echo "[2/4] Checking for sensitive terms near logs..."
if git grep -qE -C 3 "seed|mnemonic|private key|private_key|spending key|viewing key|secret|password|pin|memo|txid" -- "modules/Sources/" | grep -iE -q "print|log|os_log"; then
    echo "❌ Found sensitive terms near logging statements!"
    FAILED=1
else
    echo "✅ No sensitive terms found near logs."
fi

# 3. User-facing placeholder text
echo "[3/4] Checking for placeholders (TODO, FIXME, dummy, sample)..."
if git grep -qE "TODO|FIXME|dummy|sample|lorem ipsum" -- "modules/Sources/Features/"; then
    echo "❌ Found placeholders in UI feature code!"
    FAILED=1
else
    echo "✅ No placeholders found in UI code."
fi

# 4. Non-production endpoints
echo "[4/4] Checking for non-production endpoints in production config..."
if git grep -qE "localhost|127\.0\.0\.1|staging" -- "modules/Sources/" ":!*Tests*"; then
    echo "⚠️ Found local network endpoints in source code (verify these aren't shipped in release)."
fi

if [ $FAILED -eq 1 ]; then
    echo "❌ Pre-publishing checks failed."
    exit 1
else
    echo "🎉 All pre-publishing checks passed!"
    exit 0
fi
