# Nighthawk DarkFi — iOS application feature catalog

Canonical list of **iOS** capabilities for the DarkFi wallet app. Use this document alongside the [Android feature catalog](https://github.com/nighthawk-apps/nighthawk-android-wallet/blob/main/docs/app-features.md) to track cross-platform parity.

**Legend**

| Symbol | Meaning |
|--------|---------|
| ✅ | Implemented and usable (may need native lib or testnet node) |
| 🟡 | Partial / stub / UI-only / requires external daemon |
| ❌ | Not implemented |
| 🔒 | Zcash had it; DarkFi equivalent differs (see notes) |
| 🚀 | iOS-only feature (ahead of Android) |

---

## 1. Onboarding & wallet core

| Feature | iOS | Android | Notes |
|---------|-----|---------|-------|
| Create new wallet (BIP39-style mnemonic) | ✅ | ✅ | DarkFi uses **22-word** upstream mnemonic via UniFFI `generateDarkfiMnemonic` |
| Restore from seed phrase | ✅ | ✅ | Import path in onboarding (`ImportWallet` feature) |
| Wallet encrypted at rest | ✅ | ✅ | Keychain + `wallet.db` (native `drk`) |
| PIN / app lock | ✅ | ✅ | Security feature in Settings |
| Backup reminder / seed backup flow | ✅ | ✅ | `ExportSeed` / `RecoveryPhraseDisplay` features |
| Birthday height (faster restore) | 🟡 | 🟡 | `birthday_height` in `DrkBootstrapConfig` |
| Multiple accounts in one app | ❌ | ❌ | Single wallet today |
| View / copy receive address | ✅ | ✅ | `Receive` feature + QR |
| Generate new address | ✅ | ✅ | `generateNewAddress()` UniFFI |
| Address formats (`drk…`) | ✅ | ✅ | Confidential / public receive encodings |

---

## 2. Balance & sync

| Feature | iOS | Android | Notes |
|---------|-----|---------|-------|
| Confirmed balance (DRK) | ✅ | ✅ | `confirmedBalanceAtomic` via `WalletHandleManager` |
| Transparent vs shielded split | 🔒 | 🔒 | **N/A** — DarkFi transfers are private; single balance |
| Fiat conversion display | 🟡 | 🟡 | Fiat currency setting exists; rate source project-specific |
| Sync progress (% / blocks) | ✅ | ✅ | `syncSnapshot()` → `DrkSyncSnapshot` |
| Pull-to-refresh / rescan | ✅ | ✅ | `refreshNow()` |
| Embedded `darkfid` fullnode | ❌ | 🟡 | Android has optional foreground service; iOS not implemented |
| Remote `darkfid` JSON-RPC | ✅ | ✅ | Via `DrkBootstrapConfig.darkfid_endpoint_url` |
| Endpoint presets / change server | ✅ | ✅ | `ChangeServer` feature in Settings |
| Tor for wallet RPC | 🚀 | ✅ | iOS uses **Arti in-process** (`start_arti_proxy`); Android uses tor-android |
| Keep screen on while syncing | ❌ | ✅ | Not implemented on iOS |

---

## 3. Send & receive

| Feature | iOS | Android | Notes |
|---------|-----|---------|-------|
| Send DRK (native build + broadcast) | ✅ | ✅ | `buildTransfer` + `broadcastTransfer` via UniFFI |
| Send without native lib | 🟡 | 🟡 | Graceful degrade / error message |
| Fee estimate before send | ✅ | ✅ | `estimateTransferFee` |
| Send confirmation dialog | ✅ | ✅ | Amount, recipient, fee, memo |
| Payment memo (private, encrypted note) | ✅ | ✅ | Up to 512 UTF-8 bytes; UniFFI + send field |
| Memo on transaction details | ✅ | ✅ | `transactionPaymentMemo` on history rows |
| QR scan recipient / amount | ✅ | ✅ | `SendFlow` feature |
| Receive QR display | ✅ | ✅ | `Receive` feature |
| Request specific amount (payment URI) | 🟡 | 🟡 | Deep link support; full "request" UX varies |
| Multi-token / custom assets send | 🟡 | ✅ | UDL has `list_token_balances`; UI may need token picker verification |
| ZIP-321 / unified address | 🔒 | 🔒 | Use DarkFi `drk` addresses instead |
| Shielding / deshielding | 🔒 | 🔒 | **N/A** on DarkFi |

---

## 4. Transaction history & details

| Feature | iOS | Android | Notes |
|---------|-----|---------|-------|
| Transaction list | ✅ | ✅ | `listTransactions()` via UniFFI |
| Transaction details screen | ✅ | ✅ | `TransactionDetail` feature; fee, height, status, memo |
| Recipient address on tx | ✅ | ✅ | `transactionRecipient` UniFFI |
| Mined / pending status | ✅ | ✅ | Status string from `DrkTransactionRecord` |
| Contract call breakdown | ✅ | ✅ | `contract_summary` on history rows |
| Fee + net value in history | ✅ | ✅ | `fee_atomic` + `net_value_atomic` on `DrkTransactionRecord` |
| Export tx / block explorer link | 🟡 | 🟡 | Explorer integration project-specific |

---

## 5. DarkIRC chat (P2P)

| Feature | iOS | Android | Notes |
|---------|-----|---------|-------|
| Public IRC channels | ✅ | ✅ | iOS: in-process; Android: Kotlin IRC client |
| Embedded `darkirc` | 🚀 | ✅ | iOS: **native in-process** via UniFFI callback; Android: subprocess `darkirc_exec` |
| Tor for chat / P2P | 🚀 | ✅ | iOS: Arti in-process; Android: tor-android SOCKS |
| Connection status | ✅ | ✅ | `darkirc_status()` polling |
| Chat settings navigation | ✅ | ✅ | Settings → Chat Settings (stack push) |
| Chat settings | ✅ | ✅ | DAG hours, fast mode, E2E channels/contacts persisted |
| E2E encrypted DMs | ✅ | ✅ | ChaCha via UniFFI; `DarkircCryptoStore` |
| DM key generation | 🚀 | 🟡 | iOS: native `generate_dm_keypair()`; Android: CLI keygen |
| DM contact management | ✅ | ✅ | `DarkircContactManager` + `NewDmConversationView` |
| DM pubkey parser | ✅ | ✅ | `DarkircDmPubkeyParser` |
| DAG history | ✅ | ✅ | EventGraph replays on connect |

---

## 6. Settings & security

| Feature | iOS | Android | Notes |
|---------|-----|---------|-------|
| Settings hub | ✅ | ✅ | Tab bar navigation |
| Tor network | ✅ | ✅ | Settings → **Tor Network**; real Arti FFI + apply reload |
| Change server (darkfid endpoint) | ✅ | ✅ | `ChangeServer` feature |
| Security (PIN) | ✅ | ✅ | `Security` feature |
| Fiat currency | ✅ | ✅ | `Fiat` feature |
| Backup wallet | ✅ | ✅ | `ExportSeed` feature |
| About / version | ✅ | ✅ | `About` feature |
| Advanced settings | ✅ | ✅ | `Advanced` feature |
| Chat settings | ✅ | ✅ | Settings → **Chat Settings**; prefs + DM keys + reconnect |
| Notifications | ✅ | 🟡 | `Notifications` feature |
| Wipe / reset wallet data | ✅ | ✅ | Rescan in settings |

---

## 7. Network & daemons

| Feature | iOS | Android | Notes |
|---------|-----|---------|-------|
| Mainnet configuration | ✅ | ✅ | Default `DrkBootstrapConfig` |
| Testnet configuration | 🟡 | ✅ | Android has distinct `darkfitestnet` flavor; iOS needs scheme/config |
| Upstream-aligned RPC ports | ✅ | ✅ | 8345 / 18345 |
| Embedded darkfid P2P seeds | ❌ | ✅ | iOS does not bundle darkfid |
| Embedded darkirc P2P seeds | ✅ | ✅ | In-process darkirc uses upstream defaults |
| Stratum / mining UI | ❌ | ❌ | Desktop `darkfid` + xmrig |
| DAO / contract admin UI | 🟡 | 🟡 | Read-only **DAO Hub** (Settings + Transfer tab entry) |

---

## 8. Native / FFI stack

| Component | iOS | Android equivalent |
|-----------|-----|--------------------|
| `libdarkfi_mobile_ffi.a` | ✅ (static lib) | `libdarkfi_mobile_ffi.so` per ABI |
| UniFFI `DarkfiWalletHandle` | ✅ | Same UDL → Kotlin |
| Stub synchronizer fallback | ✅ | `StubDarkfiSynchronizer` |
| SQLCipher-linked `drk` | ✅ | Same Rust crate |
| Payment memo FFI | ✅ | Same `payment_memo` APIs |
| Arti Tor proxy | 🚀 | ❌ (uses tor-android) |
| DM keypair generation | 🚀 | ❌ (CLI keygen) |
| In-process darkirc | 🚀 | ❌ (subprocess) |
| DAO FFI (list/proposals/detail) | ✅ | Same UDL |

---

## 9. Zcash → DarkFi mapping (quick reference)

| Zcash (Nighthawk legacy) | DarkFi (this app) |
|--------------------------|-------------------|
| ZEC transparent + shielded pools | Single private DRK balance |
| Unified address / uview | `drk` deposit address |
| Memo field (512 bytes) | `MoneyNote::memo` (encrypted) + optional local store for sent |
| Lightwalletd | `darkfid` JSON-RPC |
| Tor via librustzcash | Arti in-process (iOS) |
| ZIP-321 | Payment URI `drk:address?amount=&memo=` |
| Orchard / Sapling | Money contract `TransferV1` |
| — | DarkIRC chat (new) |
| — | DAO / custom tokens (chain; app UI read-only) |

---

## 10. Verification checklist (cross-platform)

When implementing each screen, tick against this list:

1. Same **network** semantics (mainnet vs testnet build/config).
2. Same **endpoint ports** and mismatch guard.
3. **Memo** send + tx detail parity.
4. **Tor** toggle behavior (wallet RPC + chat).
5. **Chat** in-process daemon (iOS) vs subprocess (Android) — same user experience.
6. **Native library** load failure messaging (no silent wrong balances).
7. Document any intentional **omission** (e.g. no embedded darkfid on iOS).

---

## Maintenance

- Update this file when a feature moves from 🟡 → ✅ or new screens ship.
- Link PRs to task IDs in [`implementation-plan.md`](implementation-plan.md).
- iOS-specific build steps: root [`README.md`](../README.md).
