# DarkFi iOS integration architecture

This describes how the iOS app connects to DarkFi while keeping UI patterns from the Nighthawk codebase.

## Layers

```
┌─────────────────────────────────────────────────────────┐
│  SwiftUI + TCA (Views, Reducers, State)                 │
│  Home → Wallet / Transfer / Chat / Settings             │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│  Swift SDK Layer                                        │
│  - SDKSynchronizerLive (WalletHandleManager)            │
│  - Chat.swift (DarkircDaemon bridge)                    │
│  - DarkircContactManager, DarkircCryptoStore            │
│  - DaoHub.swift                                         │
└───────────────────────────┬─────────────────────────────┘
                            │ UniFFI generated Swift bindings
┌───────────────────────────▼─────────────────────────────┐
│  `rust/darkfi-mobile-ffi` — `staticlib` (arm64 / sim)   │
│  UDL-defined API (`darkfi_mobile_ffi.udl`)              │
│  - DarkfiWalletHandle (wallet ops)                      │
│  - darkirc lifecycle (in-process daemon)                 │
│  - Mesh C ABI (`nh_mesh_*`) — encrypted EventGraph hop   │
│  - Arti Tor proxy (in-process)                          │
│  - ChaCha DM crypto                                     │
│  - DAO read APIs                                        │
└─────────────────────────────────────────────────────────┘
```

## Swift SDK layer

### Responsibilities

- **Wallet session lifecycle**: `WalletHandleManager` (in `SDKSynchronizerLive.swift`) wraps `DarkfiWalletHandle` as a singleton. Creates a Combine `CurrentValueSubject<SynchronizerState, Never>` that continuously updates the iOS UI whenever block height or confirmed balance changes.
- **Sync abstraction**: TCA reducers subscribe to `SynchronizerState` via `.listenForSynchronizerUpdates`. As new blocks sync, `Home.swift` receives `.synchronizerStateChanged(SynchronizerState)` and updates `walletInfo.totalBalance` and `walletInfo.latestMinedHeight`.
- **Persistence**: Wallet seed + config stored via iOS Keychain and app-private storage. Older wallet data from Zcash forks is **not** imported — users onboard or restore from a backed-up phrase.
- **Mnemonics**: 22-word DarkFi mnemonic via UniFFI `generateDarkfiMnemonic`; validation via `validateDarkfiMnemonic`.

### Chat / DarkIRC

`Chat.swift` (TCA reducer) manages the darkirc daemon lifecycle via UniFFI. **Chat UI must not parse mesh frames.** Nearby BLE is [Nighthawk Mesh](nighthawk-mesh.md): encrypted EventGraph hop only (share-internet off).

| Topic | DarkFi source | iOS implementation |
|-------|----------------|-------------------:|
| Daemon lifecycle | `bin/darkirc` | **In-process** via `start_darkirc(datastore_path, callback)` |
| Message delivery | EventGraph | UniFFI `DarkircEventCallback.onMessage()` → Swift `AsyncStream` |
| Nearby hop | (desktop p2p) | BLE mesh C ABI; `header_dag_insert` + `ingest_mesh_event` |
| Channel presets | `darkirc_config.toml` `autojoin` | Hardcoded defaults in Chat reducer |
| Tor | `arti-client` | In-process `start_arti_proxy(socks_port)` + chat `useTor` |
| E2E DMs | ChaCha20 per-contact | `chacha_encrypt_dm` / `chacha_decrypt_dm` + `generate_dm_keypair` |
| DM contacts | `[contact."label"]` TOML | `DarkircContactManager` + `DarkircCryptoStore` (encrypted) |

Android uses the **same** in-process UniFFI daemon. Optional `darkirc_exec` on Android is a legacy IRC subprocess, not the Chat tab path.

### DAO Hub

`DaoHub.swift` exposes read-only DAO governance:

- `list_daos()` → `DrkDaoSummary` array
- `list_proposals(dao_name?)` → `DrkDaoProposalSummary` array
- `get_proposal(proposal_bulla_b58)` → `DrkDaoProposalDetail`

UI: `DaoHubView.swift` renders DAO list → detail → proposal detail.

## Rust UniFFI crate (`rust/darkfi-mobile-ffi`)

### Current state

- UniFFI `staticlib` named **`darkfi_mobile_ffi`** — builds as `.a` for iOS targets.
- UDL at `src/darkfi_mobile_ffi.udl` defines the full API surface.
- Linked against the upstream `darkfi` workspace (vendored in `third_party/darkfi/`).
- **Workspace patches** in `rust/Cargo.toml`: `halo2_proofs`, `halo2_gadgets` (parazyd fork v050), `url` (darkrenaissance fork).

### Source files

| File | Purpose |
|------|---------|
| `lib.rs` | Main entry: `DarkfiWalletHandle`, `bridge_version`, `bridge_ping`, mnemonics |
| `bootstrap.rs` | `DrkBootstrapConfig` → `Drk::new` + wallet/money init |
| `sync.rs` | `refresh_now`, `sync_snapshot`, background `subscribe_blocks` |
| `transactions.rs` | `build_transfer`, `broadcast_transfer`, `list_transactions`, `estimate_transfer_fee` |
| `tx_inspect.rs` | `transaction_payment_memo`, `transaction_recipient`, contract summary |
| `tokens.rs` | `list_token_balances` |
| `memo.rs` | Payment memo helpers |
| `mnemonic.rs` | 22-word mnemonic generation/validation |
| `birthday.rs` | Birthday height handling |
| `dao.rs` | `list_daos`, `list_proposals`, `get_proposal` |
| `darkirc_daemon.rs` | In-process darkirc lifecycle + callback + mesh gossip/ingest |
| `mesh/` | Neighbor Noise, EventPut/DagSync, C ABI |
| `tor.rs` | Arti Tor proxy: `start_arti_proxy`, `stop_arti_proxy`, `is_arti_running` |

### Platform notes (not UniFFI exclusives)

| Feature | UDL / ABI | Notes |
|---------|-----------|-------|
| **Arti Tor** | `start_arti_proxy` | In-process on iOS; Android uses Guardian tor-android for SOCKS |
| **DM keypair gen** | `generate_dm_keypair()` | Same UniFFI on Android |
| **In-process darkirc** | `start_darkirc` | Same on Android |
| **Mesh neighbors** | C ABI `nh_mesh_*` | Not UniFFI; rebuild with `SKIP_UNIFFI_BINDGEN=1` |

## Endpoint configuration

`DrkBootstrapConfig.darkfid_endpoint_url` mirrors upstream **darkfid JSON-RPC** defaults from [`bin/drk/drk_config.toml`](https://github.com/darkrenaissance/darkfi/blob/master/bin/drk/drk_config.toml):

| Network | darkfid TCP port |
|---------|------------------|
| mainnet | 8345 |
| testnet | 18345 |

The `ChangeServer` feature in Settings allows users to configure custom endpoints.

## Upstream parity status

This table closes the audit loop against the pinned `third_party/darkfi/` revision.

| Area | Status | Notes |
|------|--------|-------|
| **`darkfid` JSON-RPC (wallet → node)** | **Aligned** | Rust `Drk` connects via `darkfid_endpoint_url` |
| **`drk` wallet operations** | **Aligned** | Balance, scan, keys, signing all via UniFFI `DarkfiWalletHandle` |
| **`drk` endpoint ports** | **Aligned** | 8345 / 18345 match `drk_config.toml` |
| **`darkirc` in-process** | **Aligned** | EventGraph + P2P via UniFFI; Android same |
| **`darkirc` channel presets** | **Aligned** | `#dev`, `#random`, `#lunardao` match upstream `autojoin` |
| **Nighthawk Mesh** | **EventGraph hop** | Encrypted BLE; LWD/SoftAP **off** |
| **Arti Tor** | **iOS in-process** | Android uses tor-android SOCKS |
| **Embedded `darkfid`** | **Not implemented** | Android has optional foreground service |

## Known limitations (explicit)

- **Embedded `darkfid`** not implemented — users must connect to an external `darkfid` node.
- **Testnet build variant** not yet as clean as Android's Gradle flavor system — needs Xcode scheme/config setup.
- **Keep screen on** during sync not implemented.
- DRK fiat conversion may show "unavailable" until pricing endpoints support DRK.

## References

- DarkFi tree: [darkrenaissance/darkfi](https://github.com/darkrenaissance/darkfi) — vendored in `third_party/darkfi/`
- **[Feature catalog](app-features.md)** — iOS vs Android feature matrix
- **[Implementation plan](implementation-plan.md)** — P0–P4 task list
- **[Nighthawk Mesh](nighthawk-mesh.md)** — Encrypted EventGraph hop over BLE
- **[Architecture](Darkfi_iOS_Architecture.md)** — TCA patterns and wallet walkthrough
- UniFFI: [mozilla/uniffi-rs](https://github.com/mozilla/uniffi-rs)
