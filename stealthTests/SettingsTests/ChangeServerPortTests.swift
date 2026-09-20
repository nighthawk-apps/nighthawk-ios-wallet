//
//  ChangeServerPortTests.swift
//  stealthTests
//
//  Tests for DarkFi lightwalletd endpoint validation.
//

import XCTest
import ComposableArchitecture
@testable import stealth_testnet

@MainActor
class ChangeServerPortTests: XCTestCase {

    func testDefaultServer_AlwaysValidPort() {
        var state = ChangeServer.State()
        state.serverOption = .default
        XCTAssertTrue(state.isExpectedDarkFiPort)
        XCTAssertFalse(state.isPrivateOrLoopbackHost)
    }
    
    func testCustomServer_LwdPort_IsValid() {
        var state = ChangeServer.State()
        state.serverOption = .custom
        state.customServerAddress = "lwd.example.com:9067"
        XCTAssertTrue(state.isExpectedDarkFiPort)
        XCTAssertFalse(state.isPrivateOrLoopbackHost)
    }
    
    func testCustomServer_TlsPort_IsValid() {
        var state = ChangeServer.State()
        state.serverOption = .custom
        state.customServerAddress = "lwd.example.com:443"
        XCTAssertTrue(state.isExpectedDarkFiPort)
    }
    
    func testCustomServer_WrongPort_IsInvalid() {
        var state = ChangeServer.State()
        state.serverOption = .custom
        state.customServerAddress = "node.example.com:9090"
        XCTAssertFalse(state.isExpectedDarkFiPort)
    }

    func testCustomServer_PrivateHost_Blocked() {
        var state = ChangeServer.State()
        state.serverOption = .custom
        state.customServerAddress = "192.168.1.10:9067"
        XCTAssertTrue(state.isPrivateOrLoopbackHost)
        XCTAssertFalse(state.canSave)
    }

    func testCustomServer_HttpsHost_IsValid() {
        var state = ChangeServer.State()
        state.serverOption = .custom
        state.customServerAddress = "https://lwd.example.com"
        XCTAssertTrue(state.isValidHostAndPort)
        XCTAssertTrue(state.isExpectedDarkFiPort)
        XCTAssertTrue(state.usesRemoteHttps)
        XCTAssertFalse(state.isPrivateOrLoopbackHost)
    }

    func testCustomServer_HttpsHostPort_IsValid() {
        var state = ChangeServer.State()
        state.serverOption = .custom
        state.customServerAddress = "https://lwd.example.com:443"
        XCTAssertTrue(state.isValidHostAndPort)
        XCTAssertTrue(state.isExpectedDarkFiPort)
        XCTAssertTrue(state.usesRemoteHttps)
    }
}
