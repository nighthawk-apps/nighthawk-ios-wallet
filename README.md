# Nighthawk Wallet (DarkFi Edition) — iOS

Privacy-preserving wallet (work-in-progress) by [Nighthawk Apps](https://nighthawkapps.com). This tree ships as a **native iOS app** on the DarkFi network (DRK). The app integrates a native DarkFi wallet API via **UniFFI** (`rust/darkfi-mobile-ffi` → generated Swift + `DarkfiWalletHandle`) for chain sync, broadcast, and chat.

## Contents

- [Download](#download)
- [Quick start](#quick-start)
- [Prerequisites](#prerequisites)
- [Build](#build)
- [Wallet & recovery phrase](#wallet--recovery-phrase-22-words)
- [Chat (DarkIRC)](#chat-darkirc--eventgraph)
- [Architecture](#architecture)
- [DAO Hub](#dao-hub)
- [Privacy & security](#privacy--security)
- [Verification](#verification)
- [Known issues](#known-issues)
- [Contributing & support](#contributing--support)
- [Disclosure policy](#disclosure-policy)
- [Disclaimers](#disclaimers)

---

## Download

<a href="https://apps.apple.com/us/app/nighthawk-wallet/id1524708337" style="display: inline-block; overflow: hidden; border-radius: 13px; width: 250px; height: 83px;"><img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-US" alt="Download Nighthawk on the App Store" style="border-radius: 13px; width: 250px; height: 83px;"></a>

---

## Repository layout

Path dependencies and sibling Nighthawk repos use these **directory names**:

```text
parent/
  darkfi/                 # optional upstream clone; app vendors into third_party/darkfi
  darkfi-lightwalletd/    # gRPC lightwalletd (local sync target)
  darkfi-mobile-ffi/      # optional sibling symlink of rust/darkfi-mobile-ffi for desktop/other clients
  nighthawk-ios-wallet/   # this repo
  nighthawk-android-wallet/
  nighthawk-desktop/
  moonshine/
```

Vendored DarkFi lives at `third_party/darkfi/` (gitignored). Other clients can consume the
UniFFI crate from `rust/darkfi-mobile-ffi`, or via a sibling checkout named `darkfi-mobile-ffi`.

## Quick start

From the repository root (first-time or after native code changes):

```bash
# 1) Pin upstream DarkFi into third_party/darkfi
./scripts/vendor-darkfi.sh

# 2) Rust iOS targets (once per machine)
rustup target add aarch64-apple-ios aarch64-apple-ios-sim

# 3) UniFFI wallet native lib (REQUIRED — XCFramework .a binaries are gitignored)
./scripts/build-darkfi-mobile-ffi-ios.sh
# Faster simulator-only (NOT for TestFlight/device Archive):
#   SIM_ONLY=1 ./scripts/build-darkfi-mobile-ffi-ios.sh

# 4) Open Xcode
open stealth.xcodeproj
# Scheme: stealth-testnet (default) or stealth-mainnet
# Destination: simulator or device → ⌘B / ⌘R
```

> **TestFlight / Archive:** `DarkfiCore.xcframework` static libraries (`*.a`) are **not** in git (see `.gitignore`). A clean clone cannot link until you run the full `./scripts/build-darkfi-mobile-ffi-ios.sh` (device + simulator). Never Archive with `SIM_ONLY=1`. Re-run after Rust/UDL changes so UniFFI Swift checksums match the binary.

**Physical device from Terminal** (run in Terminal.app so codesign can access Keychain):

```bash
./scripts/deploy-ios-device.sh
# Optional: SCHEME=stealth-mainnet DEVICE_ID=<udid> ./scripts/deploy-ios-device.sh
```

**Chat:** open the **Chat** tab — DarkIRC runs **in-process** via UniFFI. **Tor is on by default** (embedded Arti SOCKS); the splash screen shows “Tor bootstrapping…” while Arti comes up. First DAG sync can take several minutes.

**Optional standalone darkirc:** `./scripts/build-darkirc-ios.sh` → `stealth/Resources/darkirc_exec` (not required for default chat).

**Disk:** `rust/target/` and `build/DerivedData/` grow large; `cargo clean` in `rust/` and removing DerivedData frees space.

**Remote HTTPS lightwalletd:** set `LIGHTWALLET_TLS_PIN_SHA256` in the scheme/xcconfig (64 hex chars). See [Privacy & security](#privacy--security).

Architecture deep-dive: [Darkfi iOS Architecture](docs/Darkfi_iOS_Architecture.md).

---

## Prerequisites

| Requirement | Notes |
|-------------|--------|
| **macOS + Xcode 15+** | iOS 17+ SDK (`IPHONEOS_DEPLOYMENT_TARGET=17.0`) |
| **Rust + Cargo** | [rustup](https://rustup.rs/) stable |
| **Rust iOS targets** | `aarch64-apple-ios`, `aarch64-apple-ios-sim` |
| **SwiftGen & SwiftLint** | See [Tooling](#tooling-swiftgen--swiftlint) |
| **Code signing** | Apple Development cert; `DEVELOPMENT_TEAM` in the Xcode project |
| **Vendored DarkFi** | `./scripts/vendor-darkfi.sh` (pins `docs/upstream/darkfi-revision.txt`) |

Uses project-local `CARGO_HOME=.cargo-home` (same as FFI build scripts).

---

## Build

### Scripts

All helpers live in [`scripts/`](scripts/).

| Script | Purpose |
|--------|---------|
| [`build-darkfi-mobile-ffi-ios.sh`](scripts/build-darkfi-mobile-ffi-ios.sh) | **Required.** Cross-compiles FFI for device + simulator, UniFFI bindgen, packages `DarkfiCore.xcframework`. `SIM_ONLY=1` skips device slice. |
| [`build-darkirc-ios.sh`](scripts/build-darkirc-ios.sh) | **Optional.** Standalone `darkirc_exec` (not used by default chat). |
| [`deploy-ios-device.sh`](scripts/deploy-ios-device.sh) | Clean rebuild, install, launch on a connected iPhone (`stealth-testnet` by default). |

| Variable | Default | Description |
|----------|---------|-------------|
| `SCHEME` | `stealth-testnet` | Also `stealth-mainnet` |
| `DEVICE_ID` | first connected iPhone | UDID from `xcrun xctrace list devices` |
| `DERIVED_DATA` | `build/DerivedData` | Xcode derived data path |
| `SIM_ONLY` | `0` | `1` = simulator-only FFI |
| `IPHONEOS_DEPLOYMENT_TARGET` | `17.0` | Must match app minimum |

### UniFFI native library

```bash
./scripts/build-darkfi-mobile-ffi-ios.sh
```

Produces `libdarkfi_mobile_ffi.a` (device + sim), regenerates `darkfi_mobile_ffi.swift` / headers, refreshes `DarkfiCore.xcframework`. The `.a` files stay local (gitignored); headers/Swift/Info.plist are committed. Re-run when Rust or the UDL changes, and **always** before TestFlight Archive.

Details: [`rust/darkfi-mobile-ffi/`](rust/darkfi-mobile-ffi/).  
Feature catalog: [`docs/app-features.md`](docs/app-features.md) · Plan: [`docs/implementation-plan.md`](docs/implementation-plan.md).

### iOS app

**Xcode:** open `stealth.xcodeproj` → scheme **`stealth-testnet`** or **`stealth-mainnet`** → ⌘B / ⌘R.

**Simulator (CLI):**

```bash
xcodebuild -project stealth.xcodeproj \
  -scheme stealth-testnet \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath build/DerivedData \
  -skipMacroValidation \
  build
```

**Physical device (CLI):** unlock the iPhone, trust the Mac, then `./scripts/deploy-ios-device.sh` or:

```bash
xcodebuild -project stealth.xcodeproj \
  -scheme stealth-testnet \
  -destination 'id=<DEVICE_UDID>' \
  -derivedDataPath build/DerivedData \
  -skipMacroValidation \
  -allowProvisioningUpdates \
  build
```

If `codesign` hangs from an IDE-embedded shell, run from **Terminal.app** or Xcode and approve Keychain access.

### Tooling (SwiftGen & SwiftLint)

**SwiftGen**

```bash
brew install swiftgen
ln -s /opt/homebrew/bin/swiftgen /usr/local/bin
```

**SwiftLint** — project expects a recent Homebrew install (or the official `.pkg`). Symlink if needed:

```bash
ln -s /opt/homebrew/bin/swiftlint /usr/local/bin
```

Both run automatically on build. Style guide: [SWIFTLINT.md](SWIFTLINT.md).

---

## Wallet & recovery phrase (22 words)

DarkFi wallets use a **22-word English recovery phrase** (not BIP39 24-word). Generation/validation live in Rust FFI (`generateDarkfiMnemonic` / `validateDarkfiMnemonic`). Restore also accepts **12 words** for legacy import.

### Create

1. Welcome → **Create wallet** — 22-word phrase stored in Keychain.
2. **Backup (required)** — view all words, check confirmation, Continue. Overlay blocks progress until checked (Android parity).
3. **Home** — SDK initializes only after backup (`isUserBackupComplete`). No skip path.

If the app is killed mid-backup, the next launch returns to the recovery phrase screen.

### Restore

Welcome → **Restore** → paste/type **22-word** phrase. On success, backup is treated complete.

### Settings → Backup your wallet

Re-displays the stored phrase (with confirmation). Does not reset the onboarding flag.

```bash
./scripts/build-darkfi-mobile-ffi-ios.sh   # after mnemonic logic changes
```

---

## Chat (DarkIRC / EventGraph)

In-process DarkIRC via UniFFI — messages through `DarkircEventCallback` → Swift `AsyncStream`. No bundled `darkirc` subprocess required. See [DarkIRC on iOS](docs/darkirc-ios.md).

| Capability | Behavior |
|------------|----------|
| Transport | EventGraph P2P via `DarkfiCore.xcframework` |
| Tor | `start_darkirc(..., useTor: true)` → arti / onion seeds |
| Standalone Arti SOCKS | `start_arti_proxy()` for wallet/LWD HTTP clients |
| Public channels | `#dev`, `#media`, `#hackers`, `#memes`, `#philosophy`, `#markets`, `#math`, `#random`, `#lunardao` |
| E2E DMs | `chacha_encrypt_dm` / `chacha_decrypt_dm` |
| Status | `darkirc_status()` polling |
| DAG history | First P2P connect can take several minutes |

```bash
./scripts/build-darkfi-mobile-ffi-ios.sh
cd rust && cargo test -p darkfi-mobile-ffi --lib darkirc && cd ..
```

---

## Architecture

- **UI:** SwiftUI + [TCA](https://github.com/pointfreeco/swift-composable-architecture). `Home.swift` scopes tabs: **Chat → Wallet → Transfer → Settings** (opens on Chat).
- **Theme:** Stealth (default dark).
- **Settings:** Chat (identity, Tor, DMs), Change server, Security (PIN), Fiat, About.
- **Wallet SDK:** `SDKSynchronizerLive` / `WalletHandleManager` wrapping `DarkfiWalletHandle`; Combine streams to TCA.
- **Balance:** single confirmed/spendable DRK tally.
- **Native:** UniFFI staticlib → `DarkfiCore.xcframework`. Rebuild after `rust/darkfi-mobile-ffi` changes.
- **Lightwalletd:** default `tcp://127.0.0.1:9067`; remote HTTPS needs `LIGHTWALLET_TLS_PIN_SHA256`.

### UniFFI & native bridge

| Piece | Role |
|-------|------|
| **`rust/darkfi-mobile-ffi`** | UniFFI `staticlib` + UDL; `p2p-tor` for chat |
| **Generated Swift** | `DarkfiMobileFfi.swift` + `DarkfiMobileFfiFFI.h` |
| **`DarkfiCore.xcframework`** | Binary target via SwiftPM |
| **`DarkfiWalletHandle`** | Init, balance, sync, transfer, history, DAO, addresses |
| **`start_darkirc`** | In-process chat daemon |
| **Mnemonic** | `generate_darkfi_mnemonic` / `validate_darkfi_mnemonic` (12 or 22 words) |
| **`DarkircEventCallback`** | Chat → Swift relay |
| **Arti Tor** | Chat `useTor`; wallet HTTP via `start_arti_proxy` |
| **DM crypto** | `generate_dm_keypair`, ChaCha encrypt/decrypt |

---

## DAO Hub

Read-only governance via UniFFI:

- `list_daos()` / `list_proposals(dao_name?)` / `get_proposal(proposal_bulla_b58)`

UI: Transfer tab and Settings → **DAO Hub**.

---

## Privacy & security

Talks only to **`darkfi-lightwalletd`** (never production `darkfid`). Sibling: [`darkfi-lightwalletd`](../darkfi-lightwalletd) · TLS pin: [`docs/TLS_PINNING.md`](../darkfi-lightwalletd/docs/TLS_PINNING.md).

### TLS pin (remote HTTPS)

```bash
openssl x509 -in lightwalletd.crt -outform DER | openssl dgst -sha256 -hex
```

1. Xcode / xcconfig: `LIGHTWALLET_TLS_PIN_SHA256 = <64hex>`
2. Info.plist `LightwalletTlsPinSha256` → `$(LIGHTWALLET_TLS_PIN_SHA256)`
3. Runtime override: UserDefaults `lightwallet_tls_pin_sha256`
4. Loopback may omit pin; remote HTTPS **fail closed** without it

### Arti Tor

Settings → Tor starts in-process Arti via UniFFI. Rebuild after UDL changes:

```bash
SIM_ONLY=1 ./scripts/build-darkfi-mobile-ffi-ios.sh   # simulator
./scripts/build-darkfi-mobile-ffi-ios.sh               # device + simulator
```

Lightwallet can dial SOCKS5 the same way as Android.

### Sync & network

| # | Feature | Status |
|---|---------|--------|
| 1 | No direct darkfid | ✅ |
| 2 | Block range padding | ✅ |
| 3 | Polling jitter ±30% | ✅ |
| 4 | TLS pin (S8) | ✅ |
| 5 | Cleartext loopback only | ✅ |
| 6 | OMR-first + backoff (S15) | ✅ |
| 7 | In-process Arti Tor | ✅ |
| 8 | SOCKS5 lightwallet dial | ✅ |

### Data-at-rest & logging

| # | Feature | Status |
|---|---------|--------|
| 9 | Keychain wallet pass | ✅ |
| 10 | Keychain seed / chat secrets | ✅ |
| 11 | Encrypted memo (RAM) | ✅ |
| 12 | Log redaction | ✅ |

### UnifOMR (scheme 0x05)

- Requires **darkfi-lightwalletd** with `fhe-omr`
- Crypto parity with Android / moonshine / LWD (`n=1024`)
- Sync fail-closed if clue PK registration fails; send via LWD `SendTransaction` only
- **Trial-decrypt fallback (default on):** when UnifOMR returns no matches (or large gaps), the wallet supplemental trial-decrypts compact blocks so you can receive from non-UnifOMR wallets such as upstream `drk`. Toggle **Strict UnifOMR sync** under Advanced settings to disable this (UnifOMR-only, more private / faster when counterparties also use UnifOMR).
- Default local: `tcp://127.0.0.1:9067` (Change Server)
- Limits: [`docs/unifomr_mvp_limits.md`](docs/unifomr_mvp_limits.md)

| # | Feature | Status |
|---|---------|--------|
| 13 | UnifOMR only (`0x05`; no PerfOMR) | ✅ |
| 14 | Multi-pubkey (cap 16) | ✅ |
| 15 | BFV query LRU | ✅ |
| 16 | Hard-fail digest | ✅ |
| 17 | Tip completeness | ✅ |
| 18 | Nullifiers all blocks | ✅ |
| 19 | SendTransaction + clue | ✅ |
| 20 | Domain-separated KDF | ✅ |
| 21 | LWD-only (`darkfid_rpc_url` optional) | ✅ |
| 22 | Reorg callback | ✅ |
| 23 | Scheme → network (`STEALTH_*`) | ✅ |
| 24 | `chain_name` network guard | ✅ |

### What the server learns

| Sync mode | Learns | Does not learn |
|-----------|--------|----------------|
| **UnifOMR** | Encrypted digest + PIR window | Notes, spend keys |
| **Trial / gap** | Padded / gap ranges | Which notes decrypt |
| **Direct darkfid** ⚠️ | Everything | *(leave `darkfid_rpc_url` unset)* |

Code: `rust/darkfi-mobile-ffi/src/{sync,lightwallet_client,omr,unifomr,tor,transactions}.rs` · `DarkfiFfiSafe.swift` · `LightwalletTlsPin.swift`  
Checklist: [`docs/verification-checklist.md`](docs/verification-checklist.md).

---

## Verification

| Step | Command |
|------|---------|
| Rust check | `cd rust && cargo check -p darkfi-mobile-ffi` |
| FFI + XCFramework | `./scripts/build-darkfi-mobile-ffi-ios.sh` |
| Simulator build | `xcodebuild -project stealth.xcodeproj -scheme stealth-testnet -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -skipMacroValidation build` |
| Swift tests | `xcodebuild test … -only-testing:stealthTests` |
| SwiftLint | `swiftlint lint` |
| Device deploy | `./scripts/deploy-ios-device.sh` |

---

## Known issues

1. First P2P/DAG sync for in-process DarkIRC can take several minutes.
2. Tor is **on by default**; Arti bootstrap can take 10–60s (splash shows “Tor bootstrapping…”). Rebuild the XCFramework after UDL/Tor/FFI changes — `*.a` files are gitignored.
3. DRK fiat may show “unavailable” until pricing endpoints support DRK.
4. Default scheme is **`stealth-testnet`**; use **`stealth-mainnet`** for mainnet. Mainnet remote HTTPS LWD requires `LightwalletTlsPinSha256` in Info.plist.
5. `SIM_ONLY=1` FFI builds omit the device slice — use a full script run before TestFlight / devices.

---

## Related projects

| Sibling directory | Role |
|-------------------|------|
| `../darkfi-lightwalletd` | Compact-block / UnifOMR gRPC server |
| `../darkfi-mobile-ffi` | Optional sibling name for the UniFFI crate (`rust/darkfi-mobile-ffi`) |
| `../nighthawk-android-wallet` | Android wallet |
| `../nighthawk-desktop` | Desktop wallet (Tauri) |
| `../moonshine` | CLI light wallet |

## Contributing & support

- [Contributing Guidelines](CONTRIBUTING.md) · [AI Contributing Guide](CONTRIBUTING_AI.md) · [Code of Conduct](CONDUCT.md)
- Install SwiftLint / SwiftGen locally; they run on build
- Security: `nighthawkwallet@protonmail.com` (see [Disclosure policy](#disclosure-policy))
- Issues: GitHub issues on this repository
- Support: [DM @NighthawkWallet on X](https://x.com/nighthawkwallet)

### License

MIT (see [`LICENSE`](LICENSE)). Upstream Electric Coin Company / Zashi attribution is retained in
license headers where applicable.

---

## Disclosure policy

Do not disclose bugs or vulnerabilities on public forums before coordinated disclosure and sufficient time for a fix. Do not exploit vulnerabilities.

### Reporting

Email `nighthawkwallet@protonmail.com` with:

- Short summary of potential impact (if known)
- Steps to reproduce / how an exploit may be formed
- Optional name for credit
- Contact details
- Optional PGP fingerprint for encrypted replies

### Encrypting disclosures

Prefer encryption. PGP fingerprint: `8c07e1261c5d9330287f4ec35aff0fd018b01972`

---

## Disclaimers

- Funding/on-ramp and third-party exchange shortcuts were removed; acquire DRK through channels you trust.
- Chat connects to DarkIRC via in-process Rust daemon; Arti/Tor runs in-app when enabled.
- Fiat hints depend on public APIs and may be unavailable.
- Traffic analysis can leak some privacy, as with other cryptocurrency wallets.
- Accurate display of chain data depends on the connected lightwalletd / darkfid stack.
