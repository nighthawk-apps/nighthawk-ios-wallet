//
//  ChangeServerPortTests.swift
//  stealthTests
//
//  Tests for DarkFi port validation (8345 mainnet, 18345 testnet).
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
    }
    
    func testCustomServer_MainnetPort_IsValid() {
        var state = ChangeServer.State()
        state.serverOption = .custom
        state.customServerAddress = "seed1.darkfi.dev:8345"
        XCTAssertTrue(state.isExpectedDarkFiPort)
    }
    
    func testCustomServer_TestnetPort_IsValid() {
        var state = ChangeServer.State()
        state.serverOption = .custom
        state.customServerAddress = "node.example.com:18345"
        XCTAssertTrue(state.isExpectedDarkFiPort)
    }
    
    func testCustomServer_WrongPort_IsInvalid() {
        var state = ChangeServer.State()
        state.serverOption = .custom
        state.customServerAddress = "node.example.com:9090"
        XCTAssertFalse(state.isExpectedDarkFiPort)
    }
    
    func testCustomServer_NoPort_IsInvalid() {
        var state = ChangeServer.State()
        state.serverOption = .custom
        state.customServerAddress = "node.example.com"
        XCTAssertFalse(state.isExpectedDarkFiPort)
    }
    
    func testCustomServer_EmptyAddress_IsInvalid() {
        var state = ChangeServer.State()
        state.serverOption = .custom
        state.customServerAddress = ""
        XCTAssertFalse(state.isExpectedDarkFiPort)
    }
    
    func testCustomServer_HostPortFormatValidation() {
        var state = ChangeServer.State()
        state.serverOption = .custom
        
        // Valid format
        state.customServerAddress = "node.darkfi.dev:8345"
        XCTAssertTrue(state.isValidHostAndPort)
        
        // Invalid format (no port)
        state.customServerAddress = "node.darkfi.dev"
        XCTAssertFalse(state.isValidHostAndPort)
        
        // Invalid format (port 0)
        state.customServerAddress = "node.darkfi.dev:0"
        XCTAssertFalse(state.isValidHostAndPort)
    }
}
