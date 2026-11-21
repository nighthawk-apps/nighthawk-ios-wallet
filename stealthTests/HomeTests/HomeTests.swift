//
//  HomeTests.swift
//  stealthTests
//
//  Reducer tests for Home tab selection and initial state.
//

import ComposableArchitecture
import DarkfiCore
import Models
import XCTest
@testable import Home

@MainActor
final class HomeTests: XCTestCase {
    override func invokeTest() {
        withDependencies {
            HomeTestSupport.configureDependencies(&$0)
        } operation: {
            super.invokeTest()
        }
    }

    func testInitialSelectedTab_IsChat() {
        withDependencies {
            HomeTestSupport.configureDependencies(&$0)
        } operation: {
            let state = Home.State(receiveAddress: nil)
            XCTAssertEqual(state.selectedTab, .chat)
        }
    }

    func testTabSelected_UpdatesSelectedTab() async {
        let store = TestStore(
            initialState: HomeTestSupport.makeState(),
            reducer: Home.init
        ) {
            HomeTestSupport.configureDependencies(&$0)
        }
        store.exhaustivity = .off

        await store.send(.tabSelected(.dex)) { state in
            state.selectedTab = .dex
        }
        await store.send(.tabSelected(.daoHub)) { state in
            state.selectedTab = .daoHub
        }
        await store.send(.tabSelected(.chat)) { state in
            state.selectedTab = .chat
        }
        await store.send(.tabSelected(.settings)) { state in
            state.selectedTab = .settings
        }
        await store.send(.tabSelected(.wallet)) { state in
            state.selectedTab = .wallet
        }
    }

    func testViewAddressesTapped_PresentsAddressesSheet() async {
        let store = TestStore(
            initialState: HomeTestSupport.makeState(),
            reducer: Home.init
        ) {
            HomeTestSupport.configureDependencies(&$0)
        }
        store.exhaustivity = .off

        await store.send(.wallet(.delegate(.showAddresses))) {
            $0.destination = .addresses(.init(receiveAddress: nil, showCloseButton: false))
        }
    }

    func testCryptoStoreMigratesDiskSecretsToKeychainAndRegistersFfiContacts() async throws {
        let rootDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("HomeCryptoStoreTests-\(UUID().uuidString)", isDirectory: true)
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
        XCTAssertFalse(FileManager.default.fileExists(atPath: appSupportFile.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: datastoreFile.path))

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
        await store.removeContact(id: added.id)
        let remaining = await store.allContacts()
        XCTAssertEqual(remaining.count, 1)

        await store.clearAll()
        let afterClear = await store.allContacts()
        XCTAssertTrue(afterClear.isEmpty)
        NighthawkContactStore.removeAll()
        DeviceAddressBook.removeAll()
    }

    func testChatOutboxStoreAndChatReducerDeliveryStateTransitions() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("HomeOutboxTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let fileURL = dir.appendingPathComponent("outbox.json")

        let outbox1 = ChatOutboxStore(fileURL: fileURL)
        let queuedId = await outbox1.enqueue(id: "queued-123", channel: "#nighthawk", text: "offline hello")
        XCTAssertEqual(queuedId, "queued-123")
        await outbox1.updateDelivery(id: queuedId, delivery: "sending")

        let outbox2 = ChatOutboxStore(fileURL: fileURL)
        let loaded = await outbox2.loadAll()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.delivery, "sending")
        await outbox2.remove(id: queuedId)
        let afterRemove = await outbox2.loadAll()
        XCTAssertTrue(afterRemove.isEmpty)

        var initialState = Chat.State()
        initialState.connectionState = .disconnected
        let channel = initialState.channels[0]
        initialState.selectedChannel = channel
        initialState.composedMessage = "queued msg"

        let chatStore = TestStore(
            initialState: initialState,
            reducer: Chat.init
        ) {
            HomeTestSupport.configureDependencies(&$0)
        }
        chatStore.exhaustivity = .off

        await chatStore.send(.sendMessage) { state in
            state.composedMessage = ""
        }
        let queuedMsg = try XCTUnwrap(chatStore.state.channelMessages[channel.name]?.last)
        XCTAssertTrue(queuedMsg.id.hasPrefix("queued-"))

        await chatStore.send(.markOutgoingSent(id: queuedMsg.id, channel: channel.name))
        let sentMsg = try XCTUnwrap(chatStore.state.channelMessages[channel.name]?.last)
        XCTAssertTrue(sentMsg.id.hasPrefix("local-"))
        XCTAssertEqual(chatStore.state.messages.last?.id, sentMsg.id)

        await chatStore.send(.markOutgoingFailed(id: sentMsg.id, channel: channel.name))
        let failedMsg = try XCTUnwrap(chatStore.state.channelMessages[channel.name]?.last)
        XCTAssertTrue(failedMsg.id.hasPrefix("failed-"))
        XCTAssertEqual(chatStore.state.messages.last?.id, failedMsg.id)

        // Retrying a failed message removes the old failed bubble in-place before resending.
        await chatStore.send(.retryOutgoing(channel: channel.name, text: "queued msg"))
        await chatStore.receive(.sendMessage)
        let remainingFailed = (chatStore.state.channelMessages[channel.name] ?? [])
            .filter { $0.id.hasPrefix("failed-") }
        XCTAssertTrue(remainingFailed.isEmpty)
        XCTAssertEqual(chatStore.state.channelMessages[channel.name]?.count, 1)

        await chatStore.send(.newDmTapped)
        XCTAssertNotNil(chatStore.state.newDmConversation)

        ChatHistoryStore.clearAll()
        await ChatOutboxStore.shared.clearAll()
    }

    func testChatWalletSendStagesReceiptAndPostsOnlyAfterBroadcast() async throws {
        ChatReceiptBook.clearAll()
        var initialState = Chat.State()
        initialState.connectionState = .connectedDirect
        let channel = initialState.channels[0]
        initialState.selectedChannel = channel

        let chatStore = TestStore(
            initialState: initialState,
            reducer: Chat.init
        ) {
            HomeTestSupport.configureDependencies(&$0)
        }

        await chatStore.send(.walletSend(address: "drk1dest", amount: "2.5", memo: "coffee", tip: false))
        await chatStore.receive(.delegate(.payInvoice(address: "drk1dest", amount: "2.5", memo: "coffee")))

        XCTAssertTrue(chatStore.state.messages.isEmpty)
        XCTAssertTrue((chatStore.state.channelMessages[channel.name] ?? []).isEmpty)

        let marked = ChatReceiptBook.markBroadcasted(txId: "txid_999")
        XCTAssertEqual(marked?.receipt.phase, .broadcasted)
        XCTAssertEqual(marked?.receipt.txId, "txid_999")
        XCTAssertEqual(marked?.targetChannel, channel.name)

        let ready = try XCTUnwrap(ChatReceiptBook.consumeReadyToPost())
        let chatStore2 = TestStore(initialState: chatStore.state, reducer: Chat.init) {
            HomeTestSupport.configureDependencies(&$0)
        }
        chatStore2.exhaustivity = .off
        await chatStore2.send(.postBroadcastedReceipt(ready.receipt, channel: ready.targetChannel))
        let posted = try XCTUnwrap(chatStore2.state.channelMessages[channel.name]?.last)
        let parsed = ChatReceiptCodec.parse(posted.content)
        XCTAssertEqual(parsed?.phase, .broadcasted)
        XCTAssertEqual(parsed?.txId, "txid_999")
        ChatReceiptBook.clearAll()
        ChatHistoryStore.clearAll()
        await ChatOutboxStore.shared.clearAll()
    }

    func testDeviceAddressBookCaseSensitiveBase58AndContactInviteUri() {
        DeviceAddressBook.removeAll()
        NighthawkContactStore.removeAll()
        defer {
            DeviceAddressBook.removeAll()
            NighthawkContactStore.removeAll()
        }

        _ = DeviceAddressBook.upsert(label: "old", address: "Drk1abc")
        let distinct = DeviceAddressBook.upsert(label: "Ada", address: "drk1abc")
        XCTAssertEqual(distinct.count, 2)

        let replaced = DeviceAddressBook.upsert(label: "AdaNew", address: "drk1abc")
        XCTAssertEqual(replaced.count, 2)
        XCTAssertEqual(replaced.first?.label, "AdaNew")

        let uri = NighthawkContacts.contactInviteUri(
            NighthawkContact(id: "ada", nickname: "Ada", dmPublicKey: "dmPk123", walletAddress: "drk1xyz")
        )
        let parsed = NighthawkContacts.parseInvite(uri ?? "")
        XCTAssertEqual(parsed?.nickname, "Ada")
        XCTAssertEqual(parsed?.dmPublicKey, "dmPk123")
        XCTAssertEqual(parsed?.walletAddress, "drk1xyz")
    }
}
