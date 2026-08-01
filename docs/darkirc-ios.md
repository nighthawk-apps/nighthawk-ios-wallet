# DarkIRC on iOS — in-process architecture

iOS runs the DarkIRC daemon **in-process** via the Rust FFI layer, unlike Android which runs a separate `darkirc_exec` subprocess. This document explains the architecture and differences.

## Architecture overview

```
┌─────────────────────────────────────────────────────────┐
│  ChatView.swift (SwiftUI)                               │
│  TCA Chat.State → message list, channels, DMs           │
└───────────────────────────┬─────────────────────────────┘
                            │ TCA Actions
┌───────────────────────────▼─────────────────────────────┐
│  Chat.swift (TCA Reducer)                               │
│  .startDarkirc / .sendMessage / .didReceiveMessage      │
│  Subscribes to AsyncStream<ChatMessage>                 │
└───────────────────────────┬─────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────┐
│  DarkircDaemon.swift (Swift bridge)                     │
│  - ChatEventRelay: DarkircEventCallback                 │
│  - Yields messages into AsyncStream.Continuation        │
│  - Calls start_darkirc(path, callback)                  │
└───────────────────────────┬─────────────────────────────┘
                            │ UniFFI callback
┌───────────────────────────▼─────────────────────────────┐
│  rust/darkfi-mobile-ffi/src/darkirc_daemon.rs           │
│  - Spawns darkirc event loop on smol::Executor          │
│  - EventGraph P2P sync + message decode                 │
│  - Invokes callback.on_message() for each IRC message   │
└─────────────────────────────────────────────────────────┘
```

## How it works

### Starting the daemon

1. `Chat.swift` dispatches `.startDarkirc` action on appear.
2. `DarkircDaemon.swift` creates a `ChatEventRelay` (conforming to UniFFI `DarkircEventCallback` protocol).
3. Calls `start_darkirc(datastore_path, use_tor, callback)` — this spawns the Rust darkirc event loop on a dedicated thread via `smol::Executor`.
4. The Rust daemon connects to P2P seeds, starts DAG sync, and begins listening for EventGraph messages.

#### Transport selection (`use_tor`)

`use_tor` chooses the P2P transport, using the seed sets from upstream `bin/darkirc/darkirc_config.toml`:

- **`false` (clearnet):** dials the `tcp+tls://lilith{0,1}.dark.fi:25551` seeds.
- **`true` (Tor):** dials the `tor://…onion:25552` seeds through darkfi's **native** Tor transport — an in-process `arti` client (enabled by the `p2p-tor` cargo feature). All peer connections discovered via the seeds stay inside Tor because the daemon's only active network profile is `tor`. The arti directory cache/state is persisted under `{datastore}/p2p/arti-*`.

Because the daemon reports `running` (and the UI flips to "Connected (Tor)") only after a real onion handshake + DAG sync completes, the Tor indicator is honest — it is unreachable unless traffic is genuinely Tor-routed.

### Receiving messages

1. When a P2P message arrives, the Rust daemon decodes it and calls `callback.on_message(channel, nick, message, timestamp_ms)`.
2. `ChatEventRelay.onMessage()` yields the message into an `AsyncStream.Continuation`.
3. The TCA reducer subscribes to this `AsyncStream` and dispatches `.didReceiveMessage` actions.
4. `ChatView.swift` updates via TCA state bindings.

### Sending messages

1. User types message and taps Send.
2. TCA reducer dispatches to `send_chat_message(channel, nick, message)` (UniFFI) — same signature as Android.
3. Rust builds an `Event` carrying a `Privmsg { version, msg_type, channel, nick, msg }` (byte-for-byte upstream `darkirc` layout), inserts the header into the Header DAG then the event into the DAG (keyed by the genesis timestamp), and broadcasts it via `EventPut(event, vec![])` (empty RLN blob).

### Stopping the daemon

1. `stop_darkirc()` — signals the Rust event loop to shut down.
2. P2P connections are closed, DAG sync stops.

## iOS vs Android comparison

| Aspect | iOS | Android |
|--------|-----|---------|
| **Daemon model** | In-process (same memory space) | Subprocess (`darkirc_exec` binary) |
| **Communication** | UniFFI callback bridge | IRC TCP socket to `127.0.0.1:6667` |
| **Lifecycle** | Tied to app process | Foreground service (survives app backgrounding) |
| **P2P/DAG** | Native Rust in-process | Native Rust in subprocess |
| **Tor** | Native darkfi transport (in-process arti, `p2p-tor`, `tor://` seeds) | Guardian tor-android SOCKS |
| **Memory** | Shares app heap | Separate process memory |
| **Background execution** | Limited by iOS (suspended when backgrounded) | Foreground service keeps running |

## Advantages of in-process model (iOS)

- **No process management**: No need to manage `exec()`, file permissions, or foreground service notifications.
- **Direct callback**: Messages arrive via function call, not TCP socket parsing.
- **Simpler Tor**: Arti runs in the same process; no SOCKS proxy coordination needed.
- **DM crypto**: `chacha_encrypt_dm` / `chacha_decrypt_dm` run in-process with direct access to key material.

## Limitations

- **Background execution**: iOS suspends the app (and darkirc) when backgrounded. Messages are missed until the app is foregrounded.
- **Memory pressure**: The darkirc daemon + EventGraph + P2P connections consume memory in the app's allocation.
- **First sync**: P2P/DAG sync can take several minutes; the UI shows a loading state during this period.
- **No IRC client**: Unlike Android (which uses a Kotlin IRC client against the daemon's TCP listener), iOS bypasses IRC entirely — messages flow through the callback bridge.

## Configuration

The darkirc daemon uses upstream defaults for P2P seeds:

- **Clearnet (`tcp+tls`)**: `lilith0.dark.fi:25551`, `lilith1.dark.fi:25551`
- **Default channels**: `#dev`, `#random`, `#lunardao` (matching upstream `autojoin`)
- **Datastore**: `{app_support}/darkirc/` — EventGraph state, P2P identity

## DM (E2E encrypted direct messages)

DMs use the same upstream protocol as Android:

1. **Key generation**: `generate_dm_keypair()` → `DmKeypair { secret_b58, public_b58 }` (iOS-specific UniFFI; Android uses CLI keygen).
2. **Contact management**: `DarkircContactManager` + `DarkircCryptoStore` persist contacts with their ChaCha public keys.
3. **Encryption**: `chacha_encrypt_dm(my_secret, their_public, plaintext)` before send.
4. **Decryption**: `chacha_decrypt_dm(my_secret, their_public, ciphertext_b58)` on receive.
5. **UI**: `NewDmConversationView` for adding contacts; `DarkircDmPubkeyParser` for extracting keys from public channel messages.

## Related docs

- [`darkfi-integration.md`](darkfi-integration.md) — Full integration architecture
- [`app-features.md`](app-features.md) — Feature catalog (Chat section)
- [`Darkfi_iOS_Architecture.md`](Darkfi_iOS_Architecture.md) — TCA architecture walkthrough
