# DarkFi iOS — implementation plan (P0–P4)

Master task list for closing gaps after the Zcash → DarkFi port. Each phase is ordered; complete **P0** before shipping mainnet builds. Track status in [`app-features.md`](app-features.md) and cross-platform parity against the [Android implementation plan](https://github.com/nighthawk-apps/nighthawk-android-wallet/blob/main/docs/implementation-plan.md).

## How to use this doc

| Column | Meaning |
|--------|---------|
| **ID** | Stable task reference (`P0-1`, `P1-2`, …) |
| **Status** | `done` / `in_progress` / `todo` |
| **Owner** | `ios` / `rust` / `docs` |

Update status when a task lands; Android column notes what the Kotlin app mirrors.

---

## P0 — Correctness / mainnet readiness

| ID | Task | Status | Notes |
|----|------|--------|-------|
| P0-1 | Build `libdarkfi_mobile_ffi.a` (arm64 + sim) | done | `./scripts/build-darkfi-mobile-ffi-ios.sh` |
| P0-2 | UniFFI Swift bindings generated from UDL | done | All wallet + chat + DAO + Tor APIs |
| P0-3 | `payment_memos` table migration | done | `Drk::ensure_payment_memos_table()` in Rust |
| P0-4 | Mainnet endpoint ports (8345 / 18345) | done | `DrkBootstrapConfig.darkfid_endpoint_url` |
| P0-5 | Arti Tor proxy lifecycle | done | `start_arti_proxy` / `stop_arti_proxy` / `is_arti_running` |
| P0-6 | In-process darkirc via UniFFI callback | done | `start_darkirc` + `DarkircEventCallback` |
| P0-7 | DM ChaCha E2E encryption | done | `chacha_encrypt_dm` / `chacha_decrypt_dm` + `generate_dm_keypair` |

**Exit criteria:** Mainnet build can send with memo; Arti Tor works in-process; embedded darkirc produces chat messages; DM E2E functional.

---

## P1 — Wallet UX

| ID | Task | Status | Android parity |
|----|------|--------|----------------|
| P1-1 | Multi-token balances (`list_token_balances`) | done | `list_token_balances` + `DrkTokenBalance` |
| P1-2 | Send screen token picker (not DRK-only) | todo | Dropdown when multiple tokens (Android done) |
| P1-3 | Contract call labels in tx details | done | `contract_summary` on `DrkTransactionRecord` |
| P1-4 | Recipient address on tx list | done | `transaction_recipient` UniFFI |
| P1-5 | Sync progress UI from `sync_snapshot` | done | `DrkSyncSnapshot` → progress display |
| P1-6 | Fee + net value in tx history | done | `fee_atomic` + `net_value_atomic` on record |
| P1-7 | Endpoint network/port guard | todo | Warn/block mismatched network↔port saves (Android done) |

**Exit criteria:** Home balance and history reflect real chain state; tx detail shows type, fee, memo, recipient when available.

---

## P2 — Smart contracts & advanced Money

| ID | Task | Status | Android parity |
|----|------|--------|----------------|
| P2-1 | DAO read-only hub (list DAOs, proposals, detail) | done | Same FFI + `DaoHub` / `DaoHubView` |
| P2-2 | DAO propose / vote / exec | todo | Android in_progress (M2 testnet) |
| P2-3 | Display minted tokens + aliases | todo | Custom assets |
| P2-4 | OTC swap flows | todo | Swap UI |

---

## P3 — Network & chat

| ID | Task | Status | Android parity |
|----|------|--------|----------------|
| P3-1 | Embedded darkfid (optional local fullnode) | todo | Android has foreground service; iOS needs background task |
| P3-2 | Testnet build configuration (Xcode scheme/config) | todo | Android has distinct `darkfitestnet` flavor |
| P3-3 | Chat settings: DAG hours, fast mode | done | `ChatSettings` prefs + Apply & reconnect |
| P3-4 | Chat E2E + DM queue hardening | in_progress | DM keys via UniFFI; encrypted channel/contact JSON persisted |
| P3-5 | Keep screen on while syncing | todo | UIApplication.shared.isIdleTimerDisabled |

---

## P4 — Quality & documentation

| ID | Task | Status | Android parity |
|----|------|--------|----------------|
| P4-1 | End-to-end send-with-memo test | todo | Needs testnet + native lib |
| P4-2 | Update `docs/darkfi-integration.md` parity matrix | done | Created with this plan |
| P4-3 | Update README to DarkFi format | done | Comprehensive rewrite |
| P4-4 | Create `docs/app-features.md` | done | iOS feature catalog |
| P4-5 | Create `docs/security-threat-model.md` | done | iOS security model |
| P4-6 | Create `docs/darkirc-ios.md` | done | iOS darkirc architecture |
| P4-7 | CI: build FFI + run tests | todo | GitHub Actions workflow |
| P4-8 | Settings sub-screen navigation (Chat, Tor, DAO) | done | App path stack + Transfer DAO Hub entry |

---

## Suggested execution order

1. **P1-2** — Token picker UI (multi-asset UX parity with Android).
2. **P1-7** — Endpoint guard (prevent network mismatch).
3. **P3-2** — Testnet Xcode scheme (developer productivity).
4. **P3-5** — Keep screen on (quick UIKit one-liner).
5. **P3-1** — Embedded darkfid (if product requires local fullnode).
6. **P2-2** — DAO flows (after testnet validation).
7. **P4-1, P4-7** — Testing and CI.

---

## Native build commands (local)

```bash
# Build FFI static library
./scripts/build-darkfi-mobile-ffi-ios.sh

# Build darkirc for iOS
./scripts/build-darkirc-ios.sh

# Verify Rust compiles
cd rust && cargo check -p darkfi-mobile-ffi
```

---

## Related documents

- [`app-features.md`](app-features.md) — Full feature matrix (iOS vs Android)
- [`darkfi-integration.md`](darkfi-integration.md) — Integration architecture
- [`Darkfi_iOS_Architecture.md`](Darkfi_iOS_Architecture.md) — Architecture & TCA patterns
- [`darkirc-ios.md`](darkirc-ios.md) — In-process DarkIRC architecture
- [`security-threat-model.md`](security-threat-model.md) — Security model
- [`alpha-testnet-connection.md`](alpha-testnet-connection.md) — Testnet connection guide
