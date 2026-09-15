# Nighthawk Mesh — encrypted EventGraph hop (BLE)

Nearby phones can carry **DarkIRC EventGraph** traffic when Tor/clearnet P2P is slow or unavailable. Mesh is **not** a second chat protocol: the UI still only reads `start_darkirc` / `DarkircEventCallback`. If DarkIRC is not running, mesh does not invent messages.

This pass is **EventGraph-only**. SoftAP internet sharing, BLE lightwalletd control, unsigned gateway announce/caps, and UnifOMR bulk over radio are **disabled**.

## What a sniffer sees

BLE advertisements carry a Nighthawk-only GATT UUID plus a rotating 8-byte link id (`blake3(secret‖epoch)[0..8]`). After neighbor handshake, payloads are `NoiseEnc` ciphertext. An observer does not see plaintext `NH_DAG_EVENT` / `NH_DAG_SYNC`, IRC `channel\nnick\nbody`, announce caps, or LWD JSON.

A decrypted neighbor is an EventGraph peer (same observer model as DarkIRC p2p). Public `#` channels remain plaintext **inside** `Event.content`. DMs stay saltbox **inside** `Privmsg` before `Event::new`.

## Wire (Rust `darkfi-mobile-ffi` mesh engine)

Keep `rust/darkfi-mobile-ffi/src/mesh/` **lockstep** with the Android copy. Relays decrypt, cache, and **re-seal** to other Ready neighbors. Inner kinds: `EventPut` (`0x20`) and GCS `DagSync` (`0x21`). Sequence is authenticated inside ciphertext. Payload cap 64 KiB; cache 256 events / 256 KiB.

Daemon: after insert, gossip Event+blob onto mesh; inbound `header_dag_insert` then `ingest_mesh_event` (do not Tor-broadcast mesh-ingested events).

## iOS radio / OS

- `NighthawkMeshController` starts the mesh engine **before** radio.
- Ingest only Noise HS/Enc, fragment, ping/pong after DAG consider.
- `NHBLELinkLayer`: drop characteristic `.read`; `didReceiveRead` → `.readNotPermitted`.
- Unicast by mesh-id; service-data session hint; `neighbor_up` on connect.
- `MeshEngineBridge` uses `dlsym` for `nh_mesh_neighbor_up` / `nh_mesh_neighbor_down` / `nh_mesh_peer_id` (missing symbols on an older `.a` are OK).
- Chat/Mesh settings hide share-wifi; `setGatewayOptIn` forced **false**.
- Do not log Bluetooth addresses.

## Rebuild native lib (mesh C ABI, no UniFFI regen)

```bash
SKIP_UNIFFI_BINDGEN=1 ./scripts/build-darkfi-mobile-ffi-ios.sh
# disk-tight: SIM_ONLY=1 or DEVICE_ONLY=1
```

Do **not** regenerate UniFFI Swift unless `darkfi_mobile_ffi.udl` changed. Do not run a second host `cargo test` tree while Android NDK `target/` is still on disk.

**Native artifacts (this pass):** `DarkfiCore.xcframework` has device (`ios-arm64`) and simulator slices with `nh_mesh_neighbor_up` / `down`.

XCTest: `stealthTests/ChatTests/MeshWireCodecTests.swift` (plaintext DAG ignored, oversized NoiseEnc).

## Out of scope this pass

- BLE LWD control / SoftAP / UnifOMR bulk / share-internet
- Public identifiers on air
- Mobile RLN proofs
- Inventing chat when DarkIRC is stopped
