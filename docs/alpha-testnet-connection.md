# DarkFi alpha testnet — iOS connection guide

This documents how Nighthawk iOS connects to the **DarkFi alpha testnet**, based on the vendored tree in `third_party/darkfi/` and [The DarkFi Book — Running a Node](https://dark.fi/book/testnet/node.html).

## Architecture (two layers)

| Layer | Daemon | What it does | Default testnet port |
|-------|--------|--------------|----------------------|
| **Chain / P2P** | `darkfid` | Syncs blocks from the network; serves JSON-RPC to wallets | P2P **18340** (clearnet `tcp+tls`), RPC **18345** |
| **Wallet** | `drk` (in-app via UniFFI) | Local wallet; scans blocks via `darkfid` JSON-RPC | Connects to **18345** |

Nighthawk embeds **`drk`** via UniFFI. Unlike Android, iOS does **not** currently bundle `darkfid` — you must run `darkfid` externally (on your Mac, a server, or via `adb`-style port forwarding).

## Quick start

### 1. Run darkfid on your Mac

From [dark.fi/book/testnet/node.html](https://dark.fi/book/testnet/node.html):

1. Build: `make darkfid drk` on upstream `master`.
2. First run creates configs under `~/.config/darkfi/` (`darkfid_config.toml`, `drk_config.toml`).
3. Set `network = "testnet"` in both configs.
4. Initialize wallet: `./drk wallet initialize`, `./drk wallet keygen`.
5. Run `./darkfid` — syncs via P2P seeds until `Blockchain synced!`.

### 2. Connect iOS (Simulator)

The iOS Simulator shares your Mac's network — the app can connect directly to `127.0.0.1:18345`:

1. Open Nighthawk on Simulator.
2. **Settings → Change Server** → enter `tcp://127.0.0.1:18345`.
3. The wallet should begin syncing.

### 3. Connect iOS (Physical Device)

**Option A: Same WiFi network**

1. Find your Mac's local IP (e.g. `192.168.1.100`).
2. Edit `darkfid_config.toml`: set `rpc_listen = "tcp://0.0.0.0:18345"` (test only; prefer TLS for non-local networks).
3. In Nighthawk: **Settings → Change Server** → `tcp://192.168.1.100:18345`.

**Option B: USB + proxy (if available)**

iOS does not have `adb reverse` equivalent. Use a network proxy tool or SSH tunnel:

```bash
# SSH tunnel from device to Mac (requires jailbreak or proxy app)
# Or use iproxy from libimobiledevice:
iproxy 18345 18345
```

## Testnet ports (upstream defaults)

From `bin/darkfid/darkfid_config.toml` and `bin/drk/drk_config.toml`:

| Service | URL / port |
|---------|------------|
| Wallet → **darkfid JSON-RPC** | `tcp://127.0.0.1:18345` |
| darkfid **management** RPC | `tcp://127.0.0.1:18346` |
| darkfid **P2P** (clearnet) | `tcp+tls://…:18340` |
| darkirc P2P (chat — separate) | `tcp+tls://lilith0.dark.fi:25551`, `lilith1.dark.fi:25551` |

## P2P seed nodes (darkfid sync)

`darkfid` discovers peers via **lilith** seeds:

**Clearnet (`tcp+tls`, port 18340):**

- `tcp+tls://lilith0.dark.fi:18340`
- `tcp+tls://lilith1.dark.fi:18340`

**Tor (port 18341):** onion addresses in `darkfid_config.toml`.

## Tor (optional)

iOS uses **Arti** (in-process Rust Tor) via `start_arti_proxy(socks_port)`. When enabled:
- All wallet JSON-RPC traffic routes through the in-process Tor SOCKS proxy.
- darkirc P2P connections also route through Tor.
- No external Tor app or SOCKS configuration needed.

Toggle: **Settings → Tor Network**.

## Wallet sync in the app

After bootstrap, UniFFI starts a background loop mirroring upstream **`subscribe_blocks`** with retry (`rust/darkfi-mobile-ffi/src/sync.rs`). The TCA reducer receives `SynchronizerState` updates and refreshes the UI.

## Related docs

- [`darkfi-integration.md`](darkfi-integration.md) — Build, FFI, endpoint configuration
- [`implementation-plan.md`](implementation-plan.md) — P3-2: testnet build configuration
