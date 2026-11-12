//
//  ChatTests.swift
//  stealthTests
//
//  Chat reducer unit tests — defaults, connection labels, channel selection.
//  Live connect/send paths require the embedded darkirc daemon and are covered
//  by DarkircLifecycleTests / manual TestFlight checks.
//

import ComposableArchitecture
import XCTest
@testable import Home

@MainActor
final class ChatTests: XCTestCase {
    func testInitialState_IsDisconnectedWithNighthawkSelected() {
        let state = Chat.State()
        XCTAssertEqual(state.connectionState, .disconnected)
        XCTAssertEqual(state.embeddedNodeStatus, .notUsed)
        XCTAssertFalse(state.connectionState.isConnected)
        XCTAssertNil(state.diagnosticDetail)
        XCTAssertEqual(state.selectedChannel?.name, "#nighthawk")
        XCTAssertEqual(state.channels.map(\.name).first, "#nighthawk")
        XCTAssertEqual(state.channels.map(\.name), DarkfiChatDefaults.defaultPublicChannels)
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
        XCTAssertEqual(Chat.State.ConnectionState.connectedDirect.label, "Connected (direct)")
        XCTAssertEqual(Chat.State.ConnectionState.connectedViaTor.label, "Connected (Tor)")
        XCTAssertEqual(Chat.State.ConnectionState.error.label, "Error")
    }

    func testConnectionStateError_SetsDiagnosticDetail() async {
        let store = TestStore(
            initialState: Chat.State(),
            reducer: Chat.init
        )
        store.exhaustivity = .off

        await store.send(.connectionStateChanged(.error)) { state in
            state.connectionState = .error
            state.diagnosticDetail =
                "Could not start the embedded darkirc node. Rebuild the Rust FFI with ./scripts/build-darkfi-mobile-ffi-ios.sh, then try Connect again. If it persists, check the Xcode console for P2P/DAG errors."
        }
    }

    func testConnectionStateConnected_ClearsDiagnosticDetail() async {
        var initialState = Chat.State()
        initialState.diagnosticDetail = "Some old error"

        let store = TestStore(
            initialState: initialState,
            reducer: Chat.init
        )
        store.exhaustivity = .off

        await store.send(.connectionStateChanged(.connectedDirect)) { state in
            state.connectionState = .connectedDirect
            state.diagnosticDetail = nil
        }
    }

    func testChannelSelected_UpdatesSelectionAndClearsUnread() async {
        var initialState = Chat.State()
        guard var second = initialState.channels.dropFirst().first else {
            return XCTFail("expected more than one default channel")
        }
        second.unreadCount = 3
        initialState.channels[id: second.id] = second

        let store = TestStore(
            initialState: initialState,
            reducer: Chat.init
        )
        store.exhaustivity = .off

        await store.send(.channelSelected(second)) { state in
            state.selectedChannel = second
            state.channels[id: second.id]?.unreadCount = 0
            state.messages = []
        }
    }

    func testInitialChannels_NighthawkFirst() {
        let expected = DarkfiChatDefaults.defaultPublicChannels
        XCTAssertEqual(expected.first, "#nighthawk")
        XCTAssertEqual(
            DarkfiChatDefaults.defaultChannelTopics["#nighthawk"],
            "Nighthawk wallet users"
        )
        let state = Chat.State()
        XCTAssertEqual(state.channels.map(\.name), expected)
        XCTAssertEqual(state.selectedChannel?.name, "#nighthawk")
    }
}
