# Fable 5.1 security audit — Nighthawk iOS (app + FFI)

**Audit date:** 2026-09-20  
**Model:** Claude Fable 5.1  
**Review date:** 2026-09-21  
**Shipped:** TestFlight `3.00.015` build 15; FFI `darkfi-mobile-ffi` 0.2.1 (synced from Android)  

Full auditor transcripts:

- [`fable-5.1-audit-ios-app-source.md`](fable-5.1-audit-ios-app-source.md) — subagent `7c87a752`
- [`fable-5.1-audit-ffi-wallet-darkirc-source.md`](fable-5.1-audit-ffi-wallet-darkirc-source.md) — subagent `ceca61f2`
- [`fable-5.1-audit-unifomr-sync-source.md`](fable-5.1-audit-unifomr-sync-source.md) — subagent `dbde00de`

---

## iOS app MUST-FIX

| ID | Finding | Status | Evidence |
|----|---------|--------|----------|
| I1.1 | Peer reverse DNS | **FIXED** | `PeerHostDisplay` ignores `reverseLookup`; tests XCTFail if invoked |
| I1.2 | Keychain AfterFirstUnlock (iCloud-syncable) | **FIXED** | `WhenUnlockedThisDeviceOnly`; Simulator-only `AfterFirstUnlockThisDeviceOnly` |
| I1.3 | `Documents/ios_wallet_address.txt` | **FIXED** | Write removed (grep clean) |
| I1.4 | Locale decimal amounts | **FIXED** | `DrkAmount.fromDecimalString` + tests |
| I1.5 | Splash biometrics hang | **FIXED** | Splash Retry path / L10n retry |
| I1.6 | Broad DB wipe on connection errors | **FIXED** | `SDKSynchronizerLive` only wipe on new/restore; no wipe on `connectionfailed` |
| I1.7 | Tx direction from `"Broadcasted"` | **FIXED** | FFI derives `is_sent` from net atomic < 0, persisting correctly once mined/confirmed |
| I1.8 | Tor-for-wallet toggle doesn’t re-prepare | **FIXED** | `TorNetwork.swift` calls `prepareWith(..., .existingWallet)` on toggle |
| I1.9 | ChangeServer rejects schemes | **FIXED** | Parses scheme/port; validates HTTPS custom servers |
| I1.10 | Address validation stub always true | **FIXED** | `DarkfiAddressFormat.isValid` via `DerivationToolLiveKey` |
| I1.11 | Hardcoded ngrok for both schemes | **DEFERRED** | Testnet Studio endpoint intentional |
| I1.12 | Chat `isOutgoing` nick-spoofable / silent Tor-off | **FIXED** | `isOutgoing` flag delivered directly from FFI daemon to `ChatEventRelay`; `showClearnetTransportWarning` alerts on Tor-off |

## FFI MUST-FIX (shared with Android)

Same crate as Android — see Android `fable-5.1-security-audit.md` FFI tables. iOS tree was synced from Android before TestFlight 14; release profile `opt-level=3`.

## SHOULD-FIX (deferred)

Import birthday parsing; Zcash leftover filenames; N memo FFI calls in tx map; DAO pasteboard; export seed PDF; Package.swift floating pin — see source audit.
