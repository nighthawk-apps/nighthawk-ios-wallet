# Instant Sync Strategy — Nighthawk iOS

> **Last updated**: 2026-09-07
>
> This document describes the instant sync changes planned across all Nighthawk
> platforms. The iOS repo **mirrors** the `darkfi-mobile-ffi` Rust crate from
> the Android repo. All core sync changes are developed in Android and synced
> here.

## Philosophy

Port DarkFi contracts + wire formats. Keep UniFFI + LWD. Do **not** port the
official GUI or its `darkfid` JSON-RPC scanner. Official `scan_blocks` into
Nighthawk would be a regression.

## Platform Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                    darkfi-mobile-ffi (Rust)                        │
│  proto/lightwallet.proto · sync.rs · lightwallet_client.rs         │
│  omr.rs · unifomr.rs · bootstrap.rs · birthday.rs                 │
│  NEW: checkpoint.rs · sync_pipeline.rs · zkas_cache.rs             │
├────────────┬────────────┬──────────────┬──────────────────────────┤
│  Android   │    iOS     │   Desktop    │      Moonshine           │
│  UniFFI    │  UniFFI    │  Cargo dep   │  Own sync.rs/client.rs   │
│  (Kotlin)  │  (Swift)   │  (Tauri)     │  (standalone Rust CLI)   │
└────────────┴────────────┴──────────────┴──────────────────────────┘
```

## iOS Impact

**All changes auto-propagate** by syncing the `rust/darkfi-mobile-ffi/` crate
from the Android repo. No iOS-specific Swift changes are needed — the Swift UI
layer talks to the Rust FFI via UniFFI which exposes the same
`DarkfiWalletHandle` interface.

### Files to Sync from Android

| File | Action |
|------|--------|
| `rust/darkfi-mobile-ffi/proto/lightwallet.proto` | Copy from Android |
| `rust/darkfi-mobile-ffi/src/sync.rs` | Copy from Android |
| `rust/darkfi-mobile-ffi/src/lightwallet_client.rs` | Copy from Android |
| `rust/darkfi-mobile-ffi/src/lightwallet_sync.rs` | Copy from Android |
| `rust/darkfi-mobile-ffi/src/bootstrap.rs` | Copy from Android |
| `rust/darkfi-mobile-ffi/src/transactions.rs` | Copy from Android |
| `rust/darkfi-mobile-ffi/src/checkpoint.rs` | NEW — copy from Android |
| `rust/darkfi-mobile-ffi/src/sync_pipeline.rs` | NEW — copy from Android |
| `rust/darkfi-mobile-ffi/src/zkas_cache.rs` | NEW — copy from Android |
| `rust/darkfi-mobile-ffi/src/darkfi_mobile_ffi.udl` | Copy from Android |

## Changes Summary

| # | Change | Impact on iOS |
|---|--------|---------------|
| 1a | Historical `GetTreeState` with authentication | Auto via FFI sync |
| 1b | Concurrent gRPC — remove global lock | Auto via FFI sync |
| 1c | Checkpoint / snapshot instant restore | Auto via FFI sync |
| 1d | OMR/PIR metering | Auto via FFI sync |
| 2a | Birthday enforcement | Auto via FFI sync |
| 2b | Pipeline OMR prefetch | Auto via FFI sync |
| 2c | OMR-first audit | Auto via FFI sync |
| 2d | ZkAS / proving key cache | Auto via FFI sync |
| 2e | Proto version lockstep | Auto via FFI sync |

## Execution Order

Same as Android. After each step is completed and tested in Android:
1. Sync `rust/darkfi-mobile-ffi/` directory
2. `cargo build` for iOS targets (aarch64-apple-ios, aarch64-apple-ios-sim)
3. Run Xcode tests

## `scan_blocks` Rejection

Same as Android — `drk::rpc::scan_blocks` is not used in the mobile FFI.

## See Also

- [docs/Darkfi_iOS_Architecture.md](Darkfi_iOS_Architecture.md) — iOS-specific architecture
- [docs/security-threat-model.md](security-threat-model.md) — privacy model
- [docs/verification-checklist.md](verification-checklist.md) — verification checklist
