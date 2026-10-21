//
//  TorNetworkTests.swift
//  stealthTests
//
//  Tests for TorNetwork reducer — toggle states, Arti lifecycle, preferences.
//

import XCTest
import ComposableArchitecture
import SDKSynchronizer
@testable import stealth_testnet

@MainActor
class TorNetworkTests: XCTestCase {
    
    func testInitialState() {
        let state = TorNetwork.State()
        XCTAssertEqual(state.privacyNetwork, .nym)
        XCTAssertTrue(state.isNymEnabled)
        XCTAssertEqual(state.nymStatus, .stopped)
        XCTAssertFalse(state.torForWallet)
        XCTAssertFalse(state.torForChat)
        XCTAssertEqual(state.torMode, .embeddedArti)
        XCTAssertEqual(state.externalSocksAddress, "127.0.0.1")
        XCTAssertEqual(state.externalSocksPort, "9050")
        XCTAssertEqual(state.artiStatus, .stopped)
        XCTAssertFalse(state.isTorEnabled)
        XCTAssertTrue(state.isUsingEmbedded)
    }
    
    func testIsTorEnabled_WhenWalletOrChatEnabled() {
        var state = TorNetwork.State()
        XCTAssertFalse(state.isTorEnabled)
        
        state.privacyNetwork = .tor
        XCTAssertTrue(state.torForWallet)
        XCTAssertTrue(state.isTorEnabled)
        
        state.privacyNetwork = .nym
        XCTAssertFalse(state.isTorEnabled)
        state.torForChat = true
        XCTAssertFalse(state.isTorEnabled)
    }
    
    func testSocksEndpoint_Embedded() {
        var state = TorNetwork.State()
        state.torMode = .embeddedArti
        XCTAssertEqual(state.socksEndpoint, "127.0.0.1:9050")
    }
    
    func testSocksEndpoint_External() {
        var state = TorNetwork.State()
        state.torMode = .externalSocks
        state.externalSocksAddress = "10.0.0.1"
        state.externalSocksPort = "1080"
        XCTAssertEqual(state.socksEndpoint, "10.0.0.1:1080")
    }
    
    func testSocksDescription_EmbeddedEnabled() {
        var state = TorNetwork.State()
        state.privacyNetwork = .tor
        state.torMode = .embeddedArti
        XCTAssertTrue(state.socksDescription.contains("Loopback"))
    }
    
    func testSocksDescription_External() {
        var state = TorNetwork.State()
        state.torMode = .externalSocks
        XCTAssertTrue(state.socksDescription.contains("external"))
    }
    
    func testPrivacyNetworkSelected_TorStopsNym() async throws {
        let store = TestStore(
            initialState: TorNetwork.State(),
            reducer: TorNetwork.init
        ) {
            $0.sdkSynchronizer = .inert
            $0.userStoredPreferences = .liveValue
        }
        
        store.exhaustivity = .off
        
        await store.send(.privacyNetworkSelected(.tor)) { state in
            state.privacyNetwork = .tor
        }
        await store.receive(\.stopNym)
    }
    
    func testPrivacyNetworkSelected_SameNetworkIsNoOp() async throws {
        let store = TestStore(
            initialState: TorNetwork.State(),
            reducer: TorNetwork.init
        )
        
        await store.send(.privacyNetworkSelected(.nym))
    }
    
    func testNymStatusChanged() async throws {
        let store = TestStore(
            initialState: TorNetwork.State(),
            reducer: TorNetwork.init
        )
        
        await store.send(.nymStatusChanged(.connected)) { state in
            state.nymStatus = .connected
        }
    }
    
    func testTorModeChanged_ToExternal() async throws {
        var initialState = TorNetwork.State()
        initialState.privacyNetwork = .tor
        initialState.artiStatus = .connected
        
        let store = TestStore(
            initialState: initialState,
            reducer: TorNetwork.init
        )
        
        store.exhaustivity = .off
        
        await store.send(.torModeChanged(.externalSocks)) { state in
            state.torMode = .externalSocks
        }
    }
    
    func testStopArti() async throws {
        var initialState = TorNetwork.State()
        initialState.artiStatus = .connected
        
        let store = TestStore(
            initialState: initialState,
            reducer: TorNetwork.init
        )
        
        await store.send(.stopArti) { state in
            state.artiStatus = .stopped
            state.artiBootstrapProgress = 0.0
        }
    }
    
    func testArtiStatusChanged() async throws {
        let store = TestStore(
            initialState: TorNetwork.State(),
            reducer: TorNetwork.init
        )
        
        await store.send(.artiStatusChanged(.bootstrapping)) { state in
            state.artiStatus = .bootstrapping
        }
        
        await store.send(.artiStatusChanged(.connected)) { state in
            state.artiStatus = .connected
        }
        
        await store.send(.artiStatusChanged(.failed)) { state in
            state.artiStatus = .failed
        }
    }
    
    func testArtiStatusLabels() {
        XCTAssertEqual(TorNetwork.State.ArtiStatus.stopped.rawValue, "Stopped")
        XCTAssertEqual(TorNetwork.State.ArtiStatus.bootstrapping.rawValue, "Bootstrapping…")
        XCTAssertEqual(TorNetwork.State.ArtiStatus.connected.rawValue, "Connected")
        XCTAssertEqual(TorNetwork.State.ArtiStatus.failed.rawValue, "Failed")
    }
}
