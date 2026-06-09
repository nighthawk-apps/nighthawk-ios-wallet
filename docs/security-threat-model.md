# Security threat model — iOS

Nighthawk iOS holds wallet seed material, chat crypto keys, and optional PIN gates. Primary assets:

| Asset | Storage | Threat |
|-------|---------|--------|
| Wallet seed | iOS Keychain (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`) | Backup extraction, jailbreak |
| Wallet PIN | Hashed in Keychain | Brute force |
| Chat identity / keys | `DarkircCryptoStore` (encrypted app-private) | App-private file access |
| DM channel secrets | `DarkircCryptoStore` (encrypted) | Key material exposure |
| In-process darkirc state | App memory + app-support dir | Memory dump, file access |
| Deep links (`drk:`) | URL scheme → Send prefill | Malicious URIs |

## Trust boundaries

- **Device**: iOS App Sandbox isolates app storage; jailbroken devices are out of scope for strong guarantees.
- **Network**: Wallet RPC to user-selected `darkfid` endpoints; optional Arti Tor for all network traffic.
- **P2P**: darkirc connects to upstream P2P seeds; EventGraph messages are public (channels) or E2E encrypted (DMs).
- **Public chat**: DM **public** keys may be posted to `#channels`; users should be warned before sharing keys.

## Controls

- **PIN**: Numeric PIN, hashed and stored in Keychain.
- **Keychain**: Wallet seed stored with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` — not available in backups.
- **App Transport Security**: iOS enforces TLS for HTTP connections by default.
- **In-process Tor**: Arti runs in the same process; no external SOCKS coordination or cleartext loopback.
- **DM encryption**: ChaCha20 via Rust (never in Swift/managed memory for crypto operations).
- **Deep link parsing**: `drk` scheme only, bounded address/memo, no sensitive debug logs.

## iOS vs Android security model

| Aspect | iOS | Android |
|--------|-----|---------|
| Seed storage | Keychain | EncryptedSharedPreferences |
| Chat keys | Encrypted app-private files | EncryptedSharedPreferences |
| DM secrets in config | In-memory only (no TOML on disk) | `darkirc_config.toml` (plaintext, app-UID restricted) |
| Tor | Arti in-process (no loopback proxy) | Guardian tor-android (SOCKS loopback) |
| Daemon isolation | Shared process | Separate subprocess |
| Background state | Suspended by iOS | Foreground service persists |
| Clipboard | iOS auto-clears after paste (14+) | Manual clear on background / 60s timeout |
| SecureScreen | `UIApplication.isIdleTimerDisabled` for screen lock prevention | `FLAG_SECURE` on sensitive windows |

## Residual risks

- In-process darkirc shares the app's address space — a Rust panic could crash the wallet.
- iOS does not have per-view `FLAG_SECURE` equivalent; screenshots of sensitive screens are not system-prevented (use app lifecycle hooks).
- Arti Tor startup adds ~10–15s latency to first connection; users may disable Tor for faster startup.
- `darkfid` endpoint is user-configurable — pointing at a malicious node could return incorrect balance/history.

## Related docs

- [Android security threat model](https://github.com/nighthawk-apps/nighthawk-android-wallet/blob/main/docs/security-threat-model.md)
- [`darkfi-integration.md`](darkfi-integration.md) — Integration architecture
- [`darkirc-ios.md`](darkirc-ios.md) — In-process darkirc details
