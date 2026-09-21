# Nighthawk iOS DarkFi wallet — app-layer audit (3.00.014 / build 14)

Read-only. Repo `/Users/adi/GitHub/nighthawk-ios-wallet`, branch `main`, includes uncommitted changes to `ChatView.swift`, `ChatReadability.swift`, `NighthawkHud.swift`, `L10n.swift`, `en.lproj/Localizable.strings`, `ChatChromeTests.swift`, `project.pbxproj`, and `rust/darkfi-mobile-ffi/{Cargo.toml,lib.rs,sync.rs,proto}`.

---

## 1. MUST-FIX before 3.00.014 TestFlight

### 1.1 Chat HUD peer dialog reverse-resolves peer IPs through the system resolver (privacy invariant violation) — uncommitted
- `modules/Sources/Features/Home/Chat/ChatReadability.swift:61-84` — `PeerHostDisplay.dnsName(...)` defaults `reverseLookup` to `PeerHostDisplay.reverseLookup`, which calls `getaddrinfo` + `getnameinfo(NI_NAMEREQD)` on every IP-literal peer host. This is a clearnet PTR query via the OS resolver, bypassing Tor/Arti entirely, and it tells the DNS resolver (ISP / captive network) exactly which darkirc peers the device is connected to.
- `modules/Sources/Features/Home/Chat/ChatView.swift:869-873` — `PeerNamesDialog.task` runs exactly that: `snapshot.map { $0.dnsName(reverseLookup: PeerHostDisplay.reverseLookup) }` on a detached task.
- `ChatReadability.swift:66-68` — when the PTR fails, the function returns the raw IP literal (`return host`), so the dialog renders `10.0.0.1` etc. — the exact thing the invariant forbids.
- `stealthTests/ChatTests/ChatChromeTests.swift:113-120` bakes in the regression: asserts `dnsName(url: "tcp://10.0.0.1:1", …) == "10.0.0.1"`.
- **Fix:** delete `PeerHostDisplay.reverseLookup` and the `getaddrinfo`/`getnameinfo` code; for IP-literal hosts return an opaque label (e.g. `"peer \(index+1)"` or the `.onion`/DNS name only when the URL already carries one); update the two test cases to assert the opaque label, keep the "must not reverse-lookup" `XCTFail` guards.

### 1.2 Seed/wallet Keychain fallback to iCloud-syncable accessibility in Release
- `modules/Sources/Dependencies/WalletStorage/WalletStorage.swift:253-266` — `replaceData` first tries `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, but on `updateData` failure it deletes and re-adds with `kSecAttrAccessibleAfterFirstUnlock` (not `ThisDeviceOnly` → eligible for Keychain iCloud sync / device-to-device migration). Comment says "Unsigned Simulator builds" but the fallback is not gated on `#if targetEnvironment(simulator)`.
- **Fix:** wrap the fallback in `#if targetEnvironment(simulator)` and otherwise `throw`; at minimum use `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.

### 1.3 Wallet address written to a plaintext, backed-up file in Documents
- `modules/Sources/Features/App/App.swift:296-299` — after `prepareWith`, writes the address to `Documents/ios_wallet_address.txt` with `atomically: true`, no file-protection attribute. Documents is included in iCloud/Finder backups and (if `UIFileSharingEnabled`/`LSSupportsOpeningDocumentsInPlace` ever gets enabled) visible in Files. `SDKSynchronizerLive.swift:304` already knows about it in the wipe list, so it's intentional debugging leftover.
- **Fix:** delete lines 296-301 (the `else { // Why did it return nil? }` branch too) and the path entry at `SDKSynchronizerLive.swift:304`.

### 1.4 Amount parsing ignores locale decimal separator → `1,5` silently becomes invalid/0
- `modules/Sources/Utils/DarkfiTypes.swift:37-50` — `DrkAmount.fromDecimalString` splits on `"."` only and requires `allSatisfy(\.isNumber)`; input `"1,5"` fails → `nil`.
- `modules/Sources/UIComponents/TextFields/NighthawkTransactionAmountTextField.swift:12` — keyboard input uses `Locale.current.decimalSeparator` (so users in de/fr/es/pt/ru etc. type `,`). Result: amount is unparseable, Send continues with zero / "invalid amount" with no hint.
- **Fix:** in `fromDecimalString`, normalize `string.replacingOccurrences(of: Locale.current.decimalSeparator ?? ".", with: ".")` (and strip grouping separators) before splitting.

### 1.5 Splash biometrics gate can hang forever (no passcode / biometry unavailable)
- `modules/Sources/Features/Splash/Splash.swift:103-117` — `.authenticate` sets `isAuthenticating = true` and only sends `.authenticationResponse` inside `if canEvaluatePolicy(...) == true`. If the device has no passcode (or LA returns an error), nothing is sent: `isAuthenticating` stays true, `hasAttemptedAuthentication` stays false, so `SplashView.swift:35` never shows the Retry button and the wallet never launches.
- **Fix:** add an `else { await send(.authenticationResponse(false)) }` (or send an explicit `.authenticationUnavailable` that shows an alert + Continue).

### 1.6 Destructive DB wipe on broad error-string match
- `modules/Sources/Dependencies/SDKSynchronizer/SDKSynchronizerLive.swift:216-236` — on any `NativeDrkUnavailable`, matches `lower.contains("connectionfailed") || "initializationfailed" || "sqlite" || "queryexecution" || …` and then `removeItem(atPath: walletDbPath)` + cache. A transient gRPC "ConnectionFailed" or any error message that happens to contain "sqlite" wipes the wallet DB (local memos, tx history, scanned notes) and forces a full rescan from birthday.
- **Fix:** restrict deletion to an explicit `DarkfiError.walletDbCorrupt` variant surfaced by Rust; never wipe on connection / initialization strings; prompt the user before any wipe.

### 1.7 Sent-transaction direction derived from a status string
- `modules/Sources/Dependencies/SDKSynchronizer/SDKSynchronizerLive.swift:438` → `isSending: record.isSent`; Rust `rust/darkfi-mobile-ffi/src/transactions.rs:510` sets `is_sent = status == "Broadcasted"`. Once a sent tx is "Confirmed", `isSent` = false, `TransactionState.swift:177-179` maps it to `.received` and does `zecAmount: overview.totalAtomicValue` — but `netValueAtomic` is already negative for spends (`tx_inspect.rs:71-75`), so the row shows a received tx with a negative amount and the wrong icon. `timestampEpochSeconds: nil` (`SDKSynchronizerLive.swift:435`) also makes every row date render `---`.
- **Fix:** `isSending: record.netValueAtomic < 0` and `zecAmount: abs(totalAtomicValue)` (or keep signed and stop re-negating at `TransactionState.swift:179`); populate `timestampEpochSeconds` from the block header in the FFI record.

### 1.8 Toggling Tor-for-wallet does not re-route live wallet traffic
- `modules/Sources/Features/Home/NighthawkSettings/TorNetwork/TorNetwork.swift:124-129` — only persists the flag and calls `resolveArtiLifecycle`. The `DarkfiWalletHandle` was bootstrapped with `TorDarkfidEndpoint.toConnectUrl(...)` in `SDKSynchronizerLive.prepare` and is never re-prepared, so after enabling Tor the wallet keeps talking clearnet until relaunch (and the UI says Tor is on).
- **Fix:** after the toggle, call `sdkSynchronizer.stop()` + `prepareWith(…, .existingWallet)` + `start(false)`, or show a "Restart required" alert and gate the toggle behind it.

### 1.9 ChangeServer is fail-closed for any custom endpoint
- `modules/Sources/Features/Home/NighthawkSettings/ChangeServer/ChangeServer.swift:43-45` — `validHostAndPort` regex rejects any scheme, so users can only enter `host:port`. Rust `lightwallet_client.rs` then treats scheme-less as `http://`, and `require_https_over_socks` refuses plaintext to a remote host → every custom server fails. There is also no UI to set a TLS pin for the custom host (`LightwalletTlsPin.swift` only reads Info.plist / UserDefaults key), so a pinned build can't be pointed anywhere else.
- **Fix:** accept `https://host[:port]` in the regex, persist the full URL, and add an optional pin field (or clear the pin when a custom host is set and warn).

### 1.10 Address validation is a stub → no network guard on Send
- `modules/Sources/Dependencies/DerivationTool/DerivationToolLiveKey.swift:24-35` — `isSaplingAddress`, `isTransparentAddress`, `isDarkFiAddress` all `return true`. `Recipient.swift` relies on `isDarkFiAddress` so any string passes; mainnet vs testnet address bytes are not checked; the failure surfaces only from Rust at propose time with a raw error.
- `SendFlow.swift:161`, `:554` — memo screen is gated on `isSaplingAddress(recipient, "testnet")`/`isTransparentAddress(address, "testnet")` (Zcash leftovers). Because both always return true, `.continueTapped` always pushes AddMemo, but the `proceedWithRecipient` path at `:554` (`state.memo == nil && !isTransparentAddress`) always skips it — memo entry is unreachable when the user enters recipient first.
- **Fix:** implement `isDarkFiAddress` via the FFI (`validateAddress(addr, network)`), remove the `isSapling/isTransparent` gates, and always offer memo.

### 1.11 Hardcoded testnet endpoint baked into both schemes
- `modules/Sources/Dependencies/SDKSynchronizer/SDKSynchronizerLive.swift:83-84` — `defaultDarkfidEndpoint = "https://epidermis-sandbox-marshland.ngrok-free.dev"` used when no custom server is set, regardless of scheme. Mainnet scheme will sync against a testnet ngrok tunnel.
- **Fix:** move to per-configuration `.xcconfig` (`LIGHTWALLETD_URL`) → Info.plist, and fail loudly when empty for mainnet.

### 1.12 Chat: `isOutgoing` spoofable and silent Tor downgrade
- `modules/Sources/Features/Home/Chat/Chat.swift:267` — `isOutgoing: nick == myNickname`. A remote peer using the same nick renders as "you" (right-aligned/self-styled), including `drk:` invoice messages that `payInvoice` (`Chat.swift:932`) pre-fills into Send.
- `Chat.swift:939-943` — `.setChatTransport(false)` persists Tor-off and reconnects immediately with no confirmation, unlike Splash which requires an explicit "Continue without Tor".
- **Fix:** derive `isOutgoing` from an echo/local-send flag in the FFI event; add a confirmation alert before `setChatTransport(false)`; only pre-fill Send from a message the user tapped, not "latest `drk:` in history".

---

## 2. SHOULD-FIX soon

- `ImportWallet.swift:23,78` — `BlockHeight(birthdayHeight)?` on non-numeric input yields `nil` → `BlockHeight(0)` fallback → silent full rescan. Show a validation error instead.
- `DatabaseFiles.swift:39-63,84` — checks for `"\(network)-data.db"` (Zcash filenames); DarkFi writes `darkfi_wallet.db`/`darkfi_cache` (`SDKSynchronizerLive.swift:301-303`). `areDbFilesPresent` is always false; any caller relying on it (onboarding decision) is wrong. Align the filenames or delete the dependency.
- `SDKSynchronizerLive.swift:428-446` — `getAllTransactions` calls `handle.transactionPaymentMemo(txHash:)` once per record inside `map` (N synchronous FFI calls); batch it or lazy-load in detail view.
- No periodic `lightSyncSnapshot` polling in foreground (Home only refreshes on foreground/relaunch) — balance/sync status goes stale; add a `refreshNow` timer effect cancelled on background.
- `WalletStorage`/`UserPreferencesStorage.removeAll()` (`UserPreferencesStorage.swift:326-330`) does not clear the persistent chat nickname → identifier survives wallet deletion.
- `DaoHubView.swift:476` — `UIPasteboard.general.string = value` with no expiry; use the `pasteboard` dependency (60 s expiry, `PasteboardLiveKey.swift`).
- `DaoHub.swift:208-224` — `proposeAmount` / `proposeRecipient` passed to FFI unvalidated (empty recipient, locale decimal issue as 1.4); `UInt64(proposeDuration) ?? 10` silently defaults. Validate before enabling Submit.
- `RecoveryPhraseDisplayView.swift:64` initializes `isCaptured` in `onAppear` — OK — but `ExportSeedView` PDF export has no minimum password length; enforce ≥ 8 chars.
- `WalletLogger.swift` scrubs only `fallbackUserMessage`/`SyncFallbackReason`; `DaoHub.swift:227,255,266` and Send surface `error.localizedDescription` verbatim (Rust messages can include paths/URLs). Route through a redaction helper.
- `SDKSynchronizerLive.swift:119-120` — same unconditional cache/db `removeItem` on first prepare failure; see 1.6.
- `scripts/deploy-ios-device.sh:8` — `BUNDLE_ID="com.nighthawkapps.wallet.ios"` hardcoded while `SCHEME` is configurable; mainnet/testnet bundle IDs diverge → install/launch step targets the wrong app. Derive from `xcodebuild -showBuildSettings`.
- `stealthTests/SendTests/TransactionAmountInputTests.swift` still exercises Zatoshi/`.zec` concepts; either delete or port to `DrkAmount` — currently gives false coverage.
- `Package.swift:59` uses `from: "1.3.2"` for swift-custom-dump (only non-exact pin); make it `exact:` for reproducible archives.

---

## 3. Verified OK

- Seed/birthday and `wallet_pass` stored via Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` on the primary path (`WalletStorage.swift:256`, `DrkWalletPassStore.swift`); DM keys and encrypted channel JSON in `ChatSecureStorage` same class. `wallet_pass` is 32 random bytes from `SecRandomCopyBytes`.
- `SeedPhrase`/`Birthday` are `Redactable` (`Utils/SensitiveData.swift`); no seed in UserDefaults; no `os_log`/`print` of the seed found.
- Seed screens use `.privacySensitive()` + `ScreenCapture.isCaptured` gating (`RecoveryPhraseDisplayView.swift:18,35,64-69`); Receive/Addresses use `.privacySensitive()`.
- Background snapshot blur wired in `stealth/NighthawkApp.swift` (`privacyBlur`); `AppView.swift:43-44` forwards `scenePhase`.
- Pasteboard dependency sets a 60 s expiry for address/URI/public-key copies; chat copy paths also use 60 s.
- Tor gate on Splash is explicit: `torBootstrapFailed` shows Retry + "Continue without Tor" with hint copy (`SplashView.swift:41-62`, `Splash.swift:126-134`); no silent downgrade there.
- `strictOmrOnly` is read from `UserPreferencesStorage.live.strictOmrOnly` and passed into `DrkBootstrapConfig` (`SDKSynchronizerLive.swift:199`); default `false` matches README §UnifOMR "Trial-decrypt fallback (default on)".
- TLS pin: `LightwalletTlsPin.swift` reads `LightwalletTlsPinSha256` from Info.plist (build-setting substituted) with UserDefaults override, validates 64-hex; Rust `bootstrap.rs` parses it.
- Socks5 wrapping: `TorDarkfidEndpoint.toConnectUrl` rewrites to `socks5://` when Tor-for-wallet is on and Arti is running.
- `WalletHandleManager.shared` is a single instance guarded by `NSCondition`; `prepare` is idempotent for `.existingWallet`.
- `Memo.maxUtf8Bytes` enforced in `DarkfiTypes.swift`; `DrkAmount.decimalString` handles negative values; no `Int64` overflow on formatting (digits-string path; `fromDecimalString` bounds fraction length and uses `Int64(digits)` failable).
- `DrkPaymentUri.encode/decode` produce `drk:<addr>?amount=&memo=` matching the Android format; `RequestMoney.swift` uses it for the QR.
- Reorg callback bridged in `SDKSynchronizerLive.setReorgCallback` and surfaced through synchronizer state.
- Darkirc lifecycle: `DarkircDaemonManager.shared.start/stop` invoked from Chat on connect/disconnect and scene background; callbacks hop to `@MainActor` via `ChatEventRelay`; Tor-for-chat defaults to `true`.
- New L10n keys `nighthawk.chat.hudPeers` / `hudPeersEmpty` present in `en.lproj/Localizable.strings:426-427` and `L10n.swift` (non-en locales fall back to `fallback:` — acceptable).
- Build: `MARKETING_VERSION = 3.00.014` / `CURRENT_PROJECT_VERSION = 14` consistent across all configs; `IPHONEOS_DEPLOYMENT_TARGET = 17.0`; XCFramework `Info.plist` lists `ios-arm64` + `ios-arm64-simulator`; `build-darkfi-mobile-ffi-ios.sh` builds both unless `DEVICE_ONLY=1` (deploy script sets it — do a full build before Archive). SwiftGen 6.6.2 pinned exact; TCA 1.26.2 exact. `vendor-darkfi.sh` enforces a 40-hex pin from `docs/upstream/darkfi-revision.txt`.

---

## 4. UDL ↔ generated Swift mismatches

None. Every namespace function, `DarkfiWalletHandle` method, record (`DrkBootstrapConfig`, `DrkLightSyncState`, `DrkTransactionRecord`, DAO records, …), enum, error, and callback interface declared in `rust/darkfi-mobile-ffi/src/darkfi_mobile_ffi.udl` has a matching `public` declaration in `modules/Sources/DarkfiCore/darkfi_mobile_ffi.swift`, and the `DarkfiCore.xcframework` headers match. Checksums are regenerated by `scripts/build-darkfi-mobile-ffi-ios.sh`; the uncommitted `rust/darkfi-mobile-ffi` changes (`apply_full_block` in `lib.rs`/`sync.rs`, `proto/lightwallet.proto`, Cargo `0.2.0 → 0.2.1`, `tower 0.4 → 0.5`) do not alter the UDL surface, but the xcframework must be rebuilt from this tree before archiving so the Swift checksums match the binary.