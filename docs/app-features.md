# Nighthawk DarkFi — iOS application feature catalog

Canonical list of **iOS** capabilities for the DarkFi wallet app. Use this document alongside the [Android feature catalog](https://github.com/nighthawk-apps/nighthawk-android-wallet/blob/nighthawk-dark/docs/app-features.md) to track cross-platform parity.

**Legend**

| Symbol | Meaning |
|--------|---------|
| ✅ | Implemented and usable (may need native lib or testnet node) |
| 🟡 | Partial / stub / UI-only / requires external daemon |
| ❌ | Not implemented |
| 🔒 | Zcash had it; DarkFi equivalent differs (see notes) |
| 🚀 | iOS-ahead feature (not a hard exclusive — Android may use a different implementation) |

**Light client path:** wallets → **`darkfi-lightwalletd` gRPC `:9067`** → `darkfid`. Default sync is padded trial decryption. Experimental UnifOMR is off unless Advanced settings turn it on.  
**Network privacy:** Nym mixnet by default on Android and iOS. Tor is in-process Arti on both.  
**Chat:** DarkIRC on both platforms is in-process UniFFI (`start_darkirc`). Optional Android `darkirc_exec` is a legacy subprocess.

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
| Tor for wallet RPC | ✅ | ✅ | Both use in-process Arti. The app default network is Nym |
| Keep screen on while syncing | ❌ | ✅ | Not implemented on iOS |

---

## 3. Send & receive

| Feature | iOS | Android | Notes |
|---------|-----|---------|-------|
| Send DRK (native build + broadcast) | ✅ | ✅ | `buildTransfer` + `broadcastTransfer` via UniFFI |
| Send without native lib | 🟡 | 🟡 | Graceful degrade / error message |
| Fee estimate before send | ✅ | ✅ | `estimateTransferFee` |
| Send confirmation dialog | ✅ | ✅ | Amount, recipient, fee, memo |
| Payment memo | ✅ | ✅ | Up to 255 UTF-8 bytes. Experimental UnifOMR carries it. The default send leaves `MoneyNote.memo` empty |
| Memo on transaction details | ✅ | ✅ | `transactionPaymentMemo` on history rows |
| QR scan recipient / amount | ✅ | ✅ | `SendFlow` feature |
| Receive QR display | ✅ | ✅ | `Receive` feature |
| Request specific amount (payment URI) | ✅ | ✅ | Request money builds `drk:address?amount=&memo=` with a base64 memo |
| Multi-token / custom assets send | ✅ | ✅ | Send-flow token picker. DRK is the default token |
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
| Public IRC channels | ✅ | ✅ | In-process UniFFI on both |
| Embedded `darkirc` | ✅ | ✅ | `start_darkirc` on both. Android `darkirc_exec` is legacy |
| Tor for chat / P2P | ✅ | ✅ | In-process Arti on both. Default transport is Nym |
| Connection status | ✅ | ✅ | `darkirc_status()` polling |
| Chat settings navigation | ✅ | ✅ | Settings → Chat Settings (stack push) |
| Chat settings | ✅ | ✅ | DAG hours, fast mode, E2E channels/contacts persisted |
| E2E encrypted DMs | ✅ | ✅ | ChaCha via UniFFI; `DarkircCryptoStore` |
| DM key generation | ✅ | ✅ | `generate_dm_keypair` UniFFI on both |
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
| Arti Tor proxy | ✅ | ✅ (in-process Arti; Nym is the default network) |
| DM keypair generation | ✅ | ✅ (`generate_dm_keypair`) |
| In-process darkirc | ✅ | ✅ (`start_darkirc`; `darkirc_exec` is legacy) |
| DAO FFI (list/proposals/detail) | ✅ | Same UDL |

---

## 9. Zcash → DarkFi mapping (quick reference)

| Zcash (Nighthawk legacy) | DarkFi (this app) |
|--------------------------|-------------------|
| ZEC transparent + shielded pools | Single private DRK balance |
| Unified address / uview | `drk` deposit address |
| Memo field (512 bytes) | Payment memo, max **255 UTF-8 bytes**. Default send leaves the on-chain note memo empty |
| Lightwalletd | `darkfi-lightwalletd` gRPC **:9067**. Default sync is trial decryption. UnifOMR is opt-in |
| Embedded Tor | In-process Arti on iOS and Android. The app default network is Nym |
| ZIP-321 | Payment URI `drk:address?amount=&memo=` with memo as standard base64 |
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
5. **Chat** in-process UniFFI on both platforms.
6. **Native library** load failure messaging (no silent wrong balances).
7. Document any intentional **omission** (e.g. no embedded darkfid on iOS).

---

## Maintenance

- Update this file when a feature moves from 🟡 → ✅ or new screens ship.
- Link PRs to task IDs in [`implementation-plan.md`](implementation-plan.md).
- iOS-specific build steps: root [`README.md`](../README.md).
