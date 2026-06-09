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
    
    func testConnectTapped_TransitionsToConnecting() async throws {
        let store = TestStore(
            initialState: Chat.State(),
            reducer: Chat.init
        )
        
        await store.send(.connectTapped) { state in
            state.connectionState = .connecting
        }
        
        // Simulated connection succeeds
        await store.receive(.connectionStateChanged(.connectedDirect)) { state in
            state.connectionState = .connectedDirect
            state.selectedChannel = state.channels.first
        }
    }
    
    func testRetryTapped_TransitionsToConnecting() async throws {
        var initialState = Chat.State()
        initialState.connectionState = .error
        initialState.diagnosticDetail = "Connection failed."
        
        let store = TestStore(
            initialState: initialState,
            reducer: Chat.init
        )
        
        await store.send(.retryTapped) { state in
            state.connectionState = .connecting
        }
        
        await store.receive(.connectionStateChanged(.connectedDirect)) { state in
            state.connectionState = .connectedDirect
            state.diagnosticDetail = nil
            state.selectedChannel = state.channels.first
        }
    }
    
    func testConnectionStateError_SetsDiagnosticDetail() async throws {
        let store = TestStore(
            initialState: Chat.State(),
            reducer: Chat.init
        )
        
        await store.send(.connectionStateChanged(.error)) { state in
            state.connectionState = .error
            state.diagnosticDetail = "Connection failed. Check your network or Tor settings."
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
        XCTAssertEqual(Chat.State.ConnectionState.connecting.label, "Connecting…")
        XCTAssertEqual(Chat.State.ConnectionState.connectedDirect.label, "Connected (direct)")
        XCTAssertEqual(Chat.State.ConnectionState.connectedViaTor.label, "Connected (Tor)")
        XCTAssertEqual(Chat.State.ConnectionState.degraded.label, "Degraded")
        XCTAssertEqual(Chat.State.ConnectionState.error.label, "Error")
    }
    
    func testEmbeddedNodeStatus_Labels() {
        XCTAssertEqual(Chat.State.EmbeddedNodeStatus.notUsed.label, "Not used")
        XCTAssertEqual(Chat.State.EmbeddedNodeStatus.starting.label, "Starting…")
        XCTAssertEqual(Chat.State.EmbeddedNodeStatus.running.label, "Running")
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
    
    func testSendMessage_AppendsToMessages() async throws {
        var initialState = Chat.State()
        initialState.connectionState = .connectedDirect
        initialState.selectedChannel = initialState.channels.first
        initialState.composedMessage = "Hello DarkFi!"
        
        let store = TestStore(
            initialState: initialState,
            reducer: Chat.init
        )
        
        await store.send(.sendMessage) { state in
            XCTAssertEqual(state.messages.count, 1)
            XCTAssertEqual(state.messages.first?.content, "Hello DarkFi!")
            XCTAssertTrue(state.messages.first?.isOutgoing ?? false)
            XCTAssertEqual(state.composedMessage, "")
        }
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
    
    func testMessagesReceived_AppendsAll() async throws {
        var initialState = Chat.State()
        initialState.connectionState = .connectedDirect
        
        let store = TestStore(
            initialState: initialState,
            reducer: Chat.init
        )
        
        let msg1 = Chat.State.Message(sender: "bob", content: "hey", isOutgoing: false)
        let msg2 = Chat.State.Message(sender: "alice", content: "hi", isOutgoing: false)
        
        await store.send(.messagesReceived([msg1, msg2])) { state in
            XCTAssertEqual(state.messages.count, 2)
        }
    }
    
    // MARK: - Default Channels
    
    func testInitialChannels() {
        let state = Chat.State()
        XCTAssertEqual(state.channels.count, 3)
        XCTAssertEqual(state.channels[0].name, "#dev")
        XCTAssertEqual(state.channels[1].name, "#darkfi")
        XCTAssertEqual(state.channels[2].name, "#random")
    }
}
