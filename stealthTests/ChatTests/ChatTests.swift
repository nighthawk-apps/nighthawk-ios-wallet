//
//  ChatTests.swift
//  stealthTests
//
//  Tests for Chat reducer — connection states, message sending, channel selection.
//

import XCTest
import ComposableArchitecture
import DarkfiCore
import Models
import Security
@testable import Home
@testable import stealth_testnet

@MainActor
class ChatTests: XCTestCase {
    // MARK: - Connection State Tests
    
    func testInitialState_IsDisconnected() async throws {
        let store = TestStore(
            initialState: Chat.State(),
            reducer: Chat.init
        )
        
        XCTAssertEqual(store.state.connectionState, .disconnected)
        XCTAssertEqual(store.state.embeddedNodeStatus, .notUsed)
        XCTAssertFalse(store.state.connectionState.isConnected)
        XCTAssertNil(store.state.diagnosticDetail)
    }
    
    func testConnectionStateError_SetsDiagnosticDetail() async throws {
        let store = TestStore(
            initialState: Chat.State(),
            reducer: Chat.init
        )
        
        await store.send(.connectionStateChanged(.error)) { state in
            state.connectionState = .error
            state.diagnosticDetail = """
                Could not start the embedded darkirc node. Rebuild the Rust FFI with \
                ./scripts/build-darkfi-mobile-ffi-ios.sh, then try Connect again. \
                If it persists, check the Xcode console for P2P/DAG errors.
                """
        }
    }

    func testConnectionStateError_PreservesSpecificDiagnostic() async throws {
        let store = TestStore(
            initialState: Chat.State(),
            reducer: Chat.init
        )

        await store.send(.ircBridgeError("socks timeout")) { state in
            state.diagnosticDetail = "socks timeout"
        }
        await store.send(.connectionStateChanged(.error)) { state in
            state.connectionState = .error
        }
    }

    func testDmBack_ClearsSelectedContact() async throws {
        var initialState = Chat.State()
        let contact = DmContact(
            id: "c1",
            contactLabel: "alice",
            theirPublicB58: "peer",
            mySecretB58: "secret",
            myPublicB58: "mine"
        )
        initialState.selectedDmContact = contact
        initialState.messages = [
            .init(sender: "alice", content: "hi", isOutgoing: false)
        ]
        let store = TestStore(
            initialState: initialState,
            reducer: Chat.init
        )
        await store.send(.dmBackTapped) { state in
            state.selectedDmContact = nil
            state.messages = []
        }
    }
    
    func testConnectionStateConnected_ClearsDiagnosticDetail() async throws {
        var initialState = Chat.State()
        initialState.diagnosticDetail = "Some old error"
        
        let store = TestStore(
            initialState: initialState,
            reducer: Chat.init
        )
        
        await store.send(.connectionStateChanged(.connectedDirect)) { state in
            state.connectionState = .connectedDirect
            state.diagnosticDetail = nil
            state.selectedChannel = state.channels.first
        }
    }
    
    func testConnectionState_IsConnectedProperty() {
        XCTAssertTrue(Chat.State.ConnectionState.connectedDirect.isConnected)
        XCTAssertTrue(Chat.State.ConnectionState.connectedViaTor.isConnected)
        XCTAssertTrue(Chat.State.ConnectionState.connectedViaNym.isConnected)
        XCTAssertFalse(Chat.State.ConnectionState.disconnected.isConnected)
        XCTAssertFalse(Chat.State.ConnectionState.connecting.isConnected)
        XCTAssertFalse(Chat.State.ConnectionState.error.isConnected)
        XCTAssertFalse(Chat.State.ConnectionState.degraded.isConnected)
    }
    
    func testConnectionState_Labels() {
        XCTAssertEqual(Chat.State.ConnectionState.disconnected.label, "Disconnected")
        XCTAssertEqual(Chat.State.ConnectionState.connecting.label, "Connecting to IRC…")
        XCTAssertEqual(Chat.State.ConnectionState.startingDaemon.label, "Starting darkirc node…")
        XCTAssertEqual(Chat.State.ConnectionState.waitingForDagSync.label, "Syncing event graph…")
        XCTAssertEqual(Chat.State.ConnectionState.connectedDirect.label, "Connected (direct)")
        XCTAssertEqual(Chat.State.ConnectionState.connectedViaTor.label, "Connected (Tor)")
        XCTAssertEqual(Chat.State.ConnectionState.connectedViaNym.label, "Connected (Nym)")
        XCTAssertEqual(Chat.State.ConnectionState.degraded.label, "Degraded")
        XCTAssertEqual(Chat.State.ConnectionState.error.label, "Error")
    }
    
    func testEmbeddedNodeStatus_Labels() {
        XCTAssertEqual(Chat.State.EmbeddedNodeStatus.notUsed.label, "Not used")
        XCTAssertEqual(Chat.State.EmbeddedNodeStatus.starting.label, "Starting…")
        XCTAssertEqual(Chat.State.EmbeddedNodeStatus.running.label, "Running")
        XCTAssertEqual(Chat.State.EmbeddedNodeStatus.waitingForPeers.label, "Finding peers…")
        XCTAssertEqual(Chat.State.EmbeddedNodeStatus.syncingDag.label, "Syncing DAG…")
        XCTAssertEqual(Chat.State.EmbeddedNodeStatus.ready.label, "Ready")
        XCTAssertEqual(Chat.State.EmbeddedNodeStatus.missingBinary.label, "Missing binary")
        XCTAssertEqual(Chat.State.EmbeddedNodeStatus.failed.label, "Failed")
    }
    
    func testEmbeddedNodeStatusChanged() async throws {
        let store = TestStore(
            initialState: Chat.State(),
            reducer: Chat.init
        )
        
        await store.send(.embeddedNodeStatusChanged(.starting)) { state in
            state.embeddedNodeStatus = .starting
        }
        
        await store.send(.embeddedNodeStatusChanged(.running)) { state in
            state.embeddedNodeStatus = .running
        }
    }
    
    // MARK: - Channel Selection Tests
    
    func testChannelSelected_ClearsMessages() async throws {
        var initialState = Chat.State()
        initialState.connectionState = .connectedDirect
        initialState.selectedChannel = initialState.channels.first
        initialState.messages = [
            .init(sender: "alice", content: "hello", isOutgoing: false)
        ]
        
        let secondChannel = initialState.channels[1]
        
        let store = TestStore(
            initialState: initialState,
            reducer: Chat.init
        )
        
        await store.send(.channelSelected(secondChannel)) { state in
            state.selectedChannel = secondChannel
            state.messages = []
        }
    }

    func testChannelSwitch_RestoresComposerDraft() async throws {
        var initialState = Chat.State()
        let first = initialState.channels[0]
        let second = initialState.channels[1]
        initialState.selectedChannel = first
        initialState.composedMessage = "for-first"

        let store = TestStore(
            initialState: initialState,
            reducer: Chat.init
        )

        await store.send(.channelSelected(second)) { state in
            state.composerDrafts["ch:\(first.id)"] = "for-first"
            state.selectedChannel = second
            state.composedMessage = ""
        }

        await store.send(.channelSelected(first)) { state in
            state.selectedChannel = first
            state.composedMessage = "for-first"
        }
    }
    
    // MARK: - Message Tests
    
    func testSendHelp_AppendsSystemMessageWithoutNetwork() async throws {
        var initialState = Chat.State()
        initialState.connectionState = .connectedDirect
        initialState.selectedChannel = initialState.channels.first
        initialState.composedMessage = "/help"

        let store = TestStore(
            initialState: initialState,
            reducer: Chat.init
        )
        store.exhaustivity = .off

        await store.send(.sendMessage) { state in
            state.composedMessage = ""
        }
        XCTAssertEqual(store.state.messages.count, 1)
        XCTAssertEqual(store.state.messages.first?.sender, "System")
        XCTAssertTrue(store.state.messages.first?.content.contains("/nick") ?? false)
    }
    
    func testSendMessage_EmptyText_DoesNothing() async throws {
        var initialState = Chat.State()
        initialState.connectionState = .connectedDirect
        initialState.selectedChannel = initialState.channels.first
        initialState.composedMessage = "   "
        
        let store = TestStore(
            initialState: initialState,
            reducer: Chat.init
        )
        
        await store.send(.sendMessage)
        // No state change expected — empty message is ignored
    }
    
    func testSendMessage_NoChannel_DoesNothing() async throws {
        var initialState = Chat.State()
        initialState.connectionState = .connectedDirect
        initialState.selectedChannel = nil
        initialState.composedMessage = "hello"
        
        let store = TestStore(
            initialState: initialState,
            reducer: Chat.init
        )
        
        await store.send(.sendMessage)
    }
    
    func testMessageReceived_AppendsToSelectedChannel() async throws {
        var initialState = Chat.State()
        initialState.connectionState = .connectedDirect
        let channel = initialState.channels[0]
        initialState.selectedChannel = channel

        let store = TestStore(
            initialState: initialState,
            reducer: Chat.init
        )

        let msg1 = Chat.State.Message(
            sender: "bob",
            content: "hey",
            channel: channel.name,
            isOutgoing: false
        )

        await store.send(.messageReceived(msg1)) { state in
            state.seenEventIds.insert(msg1.id)
            state.dagSyncCount = 1
            var bucket = state.channelMessages[channel.name] ?? []
            bucket.append(msg1)
            state.channelMessages[channel.name] = bucket
            state.messages.append(msg1)
        }
    }
    
    // MARK: - Default Channels
    
    func testInitialChannels() {
        let state = Chat.State()
        let expected = DarkfiChatDefaults.defaultPublicChannels
        XCTAssertEqual(state.channels.count, expected.count)
        XCTAssertEqual(state.channels.map(\.name), expected)
        XCTAssertEqual(expected.first, "#nighthawk")
        XCTAssertEqual(state.selectedChannel?.name, "#nighthawk")
    }

    // MARK: - DM Keychain Migration & FFI Registration

    func testCryptoStoreMigratesPlaintextDiskSecretsToKeychainAndRegistersWithRust() async throws {
        let rootDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DarkircCryptoStoreTests-\(UUID().uuidString)", isDirectory: true)
        let appSupportDir = rootDir.appendingPathComponent("darkirc", isDirectory: true)
        let datastoreDir = rootDir.appendingPathComponent("darkirc_db", isDirectory: true)
        try FileManager.default.createDirectory(at: appSupportDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: datastoreDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: rootDir) }

        let kp1 = generateDmKeypair()
        let kp2 = generateDmKeypair()
        XCTAssertFalse(kp1.secretB58.isEmpty)
        XCTAssertFalse(kp2.publicB58.isEmpty)

        let legacyContact = DmContact(
            id: "legacy-alice",
            contactLabel: "alice_test",
            theirPublicB58: kp2.publicB58,
            mySecretB58: kp1.secretB58,
            myPublicB58: kp1.publicB58
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let legacyData = try encoder.encode([legacyContact])
        let appSupportFile = appSupportDir.appendingPathComponent("dm_contacts.json")
        let datastoreFile = datastoreDir.appendingPathComponent("dm_contacts.json")
        try legacyData.write(to: appSupportFile)
        try legacyData.write(to: datastoreFile)

        let service = "com.nighthawkapps.darkfi.test.\(UUID().uuidString)"
        let store = DarkircCryptoStore(
            storageDirectory: appSupportDir,
            datastoreDirectory: datastoreDir,
            keychainService: service,
            keychainAccount: "test_contacts"
        )

        let migrated = await store.allContacts()
        XCTAssertEqual(migrated.count, 1)
        XCTAssertEqual(migrated.first?.contactLabel, "alice_test")
        XCTAssertEqual(migrated.first?.mySecretB58, kp1.secretB58)

        // Plaintext secret files must be scrubbed & deleted from disk.
        XCTAssertFalse(FileManager.default.fileExists(atPath: appSupportFile.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: datastoreFile.path))

        // Add another contact, verify it persists in Keychain without touching disk, and registers in Rust.
        let kp3 = generateDmKeypair()
        let added = try await store.addContact(
            contactLabel: "bob_test",
            theirPublicB58: kp3.publicB58,
            mySecretB58: kp1.secretB58,
            myPublicB58: kp1.publicB58
        )
        XCTAssertEqual(added.contactLabel, "bob_test")
        XCTAssertFalse(FileManager.default.fileExists(atPath: appSupportFile.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: datastoreFile.path))

        await store.registerAllWithRust()
        // Sending while daemon stopped still triggers DM registration check first;
        // clearing & unregistering must clean up cleanly.
        await store.removeContact(id: added.id)
        let remaining = await store.allContacts()
        XCTAssertEqual(remaining.count, 1)

        await store.clearAll()
        let afterClear = await store.allContacts()
        XCTAssertTrue(afterClear.isEmpty)
        NighthawkContactStore.removeAll()
        DeviceAddressBook.removeAll()
    }

    // MARK: - ChatOutboxStore & State Transitions

    func testChatOutboxStorePersistsAndTransitionsDeliveryStates() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ChatOutboxTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let fileURL = dir.appendingPathComponent("outbox.json")

        let outbox1 = ChatOutboxStore(fileURL: fileURL)
        let queuedId = await outbox1.enqueue(id: "queued-123", channel: "#nighthawk", text: "offline hello")
        XCTAssertEqual(queuedId, "queued-123")
        await outbox1.updateDelivery(id: queuedId, delivery: "sending")

        // Reload from disk in a fresh instance to verify encrypted persistence & no plaintext leak
        let encryptedURL = dir.appendingPathComponent("outbox.enc")
        let outbox2 = ChatOutboxStore(fileURL: fileURL)
        let loaded = await outbox2.loadAll()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.id, "queued-123")
        XCTAssertEqual(loaded.first?.delivery, "sending")
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: encryptedURL.path))
        let diskBytes = try Data(contentsOf: encryptedURL)
        XCTAssertNil(String(data: diskBytes, encoding: .utf8)?.range(of: "offline hello"))

        await outbox2.remove(id: queuedId)
        let afterRemove = await outbox2.loadAll()
        XCTAssertTrue(afterRemove.isEmpty)
    }

    func testChatOutboxMigratesLegacyPlaintextJsonToEncryptedFile() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ChatOutboxMigrate-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let legacyURL = dir.appendingPathComponent("legacy_outbox.json")
        let encryptedURL = dir.appendingPathComponent("legacy_outbox.enc")
        let seedRecords = [
            ChatOutboxStore.Record(id: "queued-old", channel: "#nighthawk", text: "secret plaintext", delivery: "queued")
        ]
        try JSONEncoder().encode(seedRecords).write(to: legacyURL)

        let store = ChatOutboxStore(fileURL: legacyURL)
        let loaded = await store.loadAll()
        XCTAssertEqual(loaded, seedRecords)
        XCTAssertFalse(FileManager.default.fileExists(atPath: legacyURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: encryptedURL.path))
        let diskBytes = try Data(contentsOf: encryptedURL)
        XCTAssertNil(String(data: diskBytes, encoding: .utf8)?.range(of: "secret plaintext"))
    }

    func testChatReducer_OfflineSendQueuesAndTransitionsToSentOrFailed() async throws {
        var initialState = Chat.State()
        initialState.connectionState = .disconnected
        let channel = initialState.channels[0]
        initialState.selectedChannel = channel
        initialState.composedMessage = "queued msg"

        let store = TestStore(
            initialState: initialState,
            reducer: Chat.init
        )
        store.exhaustivity = .off

        await store.send(.sendMessage) { state in
            state.composedMessage = ""
        }
        let queuedMsg = try XCTUnwrap(store.state.channelMessages[channel.name]?.last)
        XCTAssertTrue(queuedMsg.id.hasPrefix("queued-"))

        await store.send(.markOutgoingSent(id: queuedMsg.id, channel: channel.name))
        let sentMsg = try XCTUnwrap(store.state.channelMessages[channel.name]?.last)
        XCTAssertTrue(sentMsg.id.hasPrefix("local-"))
        XCTAssertEqual(store.state.messages.last?.id, sentMsg.id)

        await store.send(.markOutgoingFailed(id: sentMsg.id, channel: channel.name))
        let failedMsg = try XCTUnwrap(store.state.channelMessages[channel.name]?.last)
        XCTAssertTrue(failedMsg.id.hasPrefix("failed-"))
        XCTAssertEqual(store.state.messages.last?.id, failedMsg.id)
        ChatHistoryStore.clearAll()
        await ChatOutboxStore.shared.clearAll()
    }

    func testWalletSendStagesReceiptWithoutPostingBeforeBroadcast() async throws {
        ChatReceiptBook.clearAll()
        var initialState = Chat.State()
        initialState.connectionState = .connectedDirect
        let channel = initialState.channels[0]
        initialState.selectedChannel = channel

        let store = TestStore(
            initialState: initialState,
            reducer: Chat.init
        )

        await store.send(.walletSend(address: "drk1dest", amount: "2.5", memo: "coffee", tip: false))
        await store.receive(.delegate(.payInvoice(address: "drk1dest", amount: "2.5", memo: "coffee")))

        // No pending receipt should be posted to chat before broadcast!
        XCTAssertTrue(store.state.messages.isEmpty)
        XCTAssertTrue((store.state.channelMessages[channel.name] ?? []).isEmpty)

        // Simulate SendFlow broadcast marking receipt ready & Home forwarding it
        let marked = ChatReceiptBook.markBroadcasted(txId: "txid_999")
        XCTAssertEqual(marked?.receipt.phase, .broadcasted)
        XCTAssertEqual(marked?.receipt.txId, "txid_999")
        XCTAssertEqual(marked?.targetChannel, channel.name)

        let ready = try XCTUnwrap(ChatReceiptBook.consumeReadyToPost())
        let store2 = TestStore(initialState: store.state, reducer: Chat.init)
        store2.exhaustivity = .off
        await store2.send(.postBroadcastedReceipt(ready.receipt, channel: ready.targetChannel))
        let posted = try XCTUnwrap(store2.state.channelMessages[channel.name]?.last)
        let parsed = ChatReceiptCodec.parse(posted.content)
        XCTAssertEqual(parsed?.phase, .broadcasted)
        XCTAssertEqual(parsed?.txId, "txid_999")
        ChatReceiptBook.clearAll()
        ChatHistoryStore.clearAll()
        await ChatOutboxStore.shared.clearAll()
    }

    func testResolveDiskKeyKeepsExistingKey() {
        let existing = Data(repeating: 7, count: 32)
        var writes = 0
        let resolved = ChatEncryptedFileStore.resolveDiskKey(
            status: errSecSuccess,
            data: existing,
            randomBytes: {
                XCTFail("must not generate a replacement key")
                return nil
            },
            upsert: { _ in
                writes += 1
                return errSecSuccess
            }
        )
        XCTAssertEqual(resolved, existing)
        XCTAssertEqual(writes, 0)
    }

    func testResolveDiskKeyCreatesOnlyWhenMissingAndStored() {
        let created = Data(repeating: 4, count: 32)
        var writes = 0
        let resolved = ChatEncryptedFileStore.resolveDiskKey(
            status: errSecItemNotFound,
            data: nil,
            randomBytes: { created },
            upsert: { bytes in
                writes += 1
                XCTAssertEqual(bytes.count, 32)
                return errSecSuccess
            }
        )
        XCTAssertEqual(resolved, created)
        XCTAssertEqual(writes, 1)
    }

    func testResolveDiskKeyDoesNotCacheWhenUpsertFails() {
        var writes = 0
        let resolved = ChatEncryptedFileStore.resolveDiskKey(
            status: errSecItemNotFound,
            data: nil,
            randomBytes: { Data(repeating: 4, count: 32) },
            upsert: { _ in
                writes += 1
                return errSecAuthFailed
            }
        )
        XCTAssertNil(resolved)
        XCTAssertEqual(writes, 1)
    }

    func testResolveDiskKeyRefusesUnexpectedKeychainStatus() {
        let statuses: [OSStatus] = [
            errSecInteractionNotAllowed,
            errSecAuthFailed,
            errSecDuplicateItem,
            errSecSuccess
        ]
        for status in statuses {
            var writes = 0
            let data: Data? = status == errSecSuccess ? Data(repeating: 1, count: 16) : Data(repeating: 1, count: 32)
            let resolved = ChatEncryptedFileStore.resolveDiskKey(
                status: status,
                data: data,
                randomBytes: { Data(repeating: 4, count: 32) },
                upsert: { _ in
                    writes += 1
                    return errSecSuccess
                }
            )
            XCTAssertNil(resolved, "status \(status) must not create a key")
            XCTAssertEqual(writes, 0, "status \(status) must not write a key")
        }
    }

    func testResolveDiskKeyIgnoresShortRandomBytes() {
        var writes = 0
        let resolved = ChatEncryptedFileStore.resolveDiskKey(
            status: errSecItemNotFound,
            data: nil,
            randomBytes: { Data(repeating: 4, count: 16) },
            upsert: { _ in
                writes += 1
                return errSecSuccess
            }
        )
        XCTAssertNil(resolved)
        XCTAssertEqual(writes, 0)
    }
}
