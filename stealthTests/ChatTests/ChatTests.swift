//
//  ChatTests.swift
//  stealthTests
//
//  Tests for Chat reducer — connection states, message sending, channel selection.
//

import XCTest
import ComposableArchitecture
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
            state.diagnosticDetail = "Could not start the embedded darkirc node. Rebuild the Rust FFI with ./scripts/build-darkfi-mobile-ffi-ios.sh, then try Connect again. If it persists, check the Xcode console for P2P/DAG errors."
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
    }
}
