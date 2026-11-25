//
//  ChangeServerPortTests.swift
//  stealthTests
//
//  Tests for ChangeServer lightwalletd endpoint validation, HTTPS/TLS presets,
//  saved state transitions, and LightwalletTlsPin rotation / fail-closed rules.
//

import ComposableArchitecture
import DarkfiCore
import XCTest
@testable import Home

@MainActor
final class ChangeServerPortTests: XCTestCase {
    func testDefaultServer_AlwaysValidPort() {
        var state = ChangeServer.State()
        state.serverOption = .default
        XCTAssertTrue(state.isExpectedDarkFiPort)
    }

    func testCustomServer_LightwalletPort9067_IsValid() {
        var state = ChangeServer.State()
        state.serverOption = .custom
        state.customServerAddress = "127.0.0.1:9067"
        XCTAssertTrue(state.isValidHostAndPort)
        XCTAssertTrue(state.isExpectedDarkFiPort)
    }

    func testCustomServer_HttpsPort443_IsValidWithoutWarning() {
        var state = ChangeServer.State()
        state.serverOption = .custom
        state.customServerAddress = "https://epidermis-sandbox-marshland.ngrok-free.dev:443"
        XCTAssertTrue(state.isTlsEndpoint)
        XCTAssertTrue(state.isValidHostAndPort)
        XCTAssertTrue(state.isExpectedDarkFiPort)
        XCTAssertEqual(
            state.effectiveCustomEndpoint,
            "https://epidermis-sandbox-marshland.ngrok-free.dev:443"
        )
    }

    func testCustomServer_WrongPort_TriggersWarning() {
        var state = ChangeServer.State()
        state.serverOption = .custom
        state.customServerAddress = "node.example.com:9090"
        XCTAssertTrue(state.isValidHostAndPort)
        XCTAssertFalse(state.isExpectedDarkFiPort)
    }

    func testCustomServer_NoPortOrEmpty_IsInvalid() {
        var state = ChangeServer.State()
        state.serverOption = .custom
        state.customServerAddress = "node.example.com"
        XCTAssertFalse(state.isValidHostAndPort)
        XCTAssertFalse(state.isExpectedDarkFiPort)

        state.customServerAddress = ""
        XCTAssertFalse(state.isValidHostAndPort)
        XCTAssertFalse(state.isExpectedDarkFiPort)

        state.customServerAddress = "node.darkfi.dev:0"
        XCTAssertFalse(state.isValidHostAndPort)
    }

    func testPresetSelectionAndTlsToggle() async {
        let store = TestStore(
            initialState: ChangeServer.State(),
            reducer: ChangeServer.init
        )

        await store.send(.presetSelected(ChangeServer.State.testnetTlsPreset)) {
            $0.serverOption = .custom
            $0.customServerAddress = "https://epidermis-sandbox-marshland.ngrok-free.dev:443"
            $0.useTls = true
        }
        XCTAssertTrue(store.state.canSave)

        await store.send(.useTlsToggled(false)) {
            $0.useTls = false
            $0.customServerAddress = "epidermis-sandbox-marshland.ngrok-free.dev:443"
        }

        await store.send(.useTlsToggled(true)) {
            $0.useTls = true
            $0.customServerAddress = "https://epidermis-sandbox-marshland.ngrok-free.dev:443"
        }
    }

    func testChangeSucceededUpdatesSavedState() async {
        var initial = ChangeServer.State()
        initial.serverOption = .custom
        initial.customServerAddress = "https://epidermis-sandbox-marshland.ngrok-free.dev:443"
        initial.useTls = true
        initial.isChangingServer = true

        let store = TestStore(
            initialState: initial,
            reducer: ChangeServer.init
        )

        await store.send(
            .changeSucceeded(
                savedUsesCustom: true,
                savedCustomServer: "https://epidermis-sandbox-marshland.ngrok-free.dev:443"
            )
        ) {
            $0.isChangingServer = false
            $0.savedUsesCustom = true
            $0.savedCustomServer = "https://epidermis-sandbox-marshland.ngrok-free.dev:443"
        }
        XCTAssertFalse(store.state.canSave)
    }

    func testLightwalletTlsPinRotationAndFailClosedValidation() throws {
        let suiteName = "LightwalletTlsPinTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let primaryHex = LightwalletTlsPin.testnetDefaultPinHex
        let previousHex = String(repeating: "ab", count: 32)
        let wrongHex = String(repeating: "cd", count: 32)

        let primaryData = try XCTUnwrap(LightwalletTlsPin.parseHexPin(primaryHex))
        let previousData = try XCTUnwrap(LightwalletTlsPin.parseHexPin(previousHex))
        let wrongData = try XCTUnwrap(LightwalletTlsPin.parseHexPin(wrongHex))
        XCTAssertEqual(primaryData.count, 32)

        // Empty bundle + empty defaults -> fail-closed on remote HTTPS.
        let emptyBundle = Bundle(for: ChangeServerPortTests.self)
        XCTAssertTrue(LightwalletTlsPin.requiresPin(forEndpoint: "https://epidermis-sandbox-marshland.ngrok-free.dev:443"))
        XCTAssertFalse(LightwalletTlsPin.requiresPin(forEndpoint: "tcp://127.0.0.1:9067"))
        XCTAssertFalse(LightwalletTlsPin.requiresPin(forEndpoint: "https://127.0.0.1:443"))
        XCTAssertFalse(
            LightwalletTlsPin.validateEndpoint(
                "https://epidermis-sandbox-marshland.ngrok-free.dev:443",
                defaults: defaults,
                bundle: emptyBundle
            )
        )
        XCTAssertTrue(
            LightwalletTlsPin.validateEndpoint(
                "tcp://127.0.0.1:9067",
                defaults: defaults,
                bundle: emptyBundle
            )
        )
        XCTAssertFalse(LightwalletTlsPin.matches(leafCertSha256: primaryData, defaults: defaults, bundle: emptyBundle))

        // Configure primary + previous rotation pins.
        defaults.set(primaryHex, forKey: LightwalletTlsPin.userDefaultsKey)
        defaults.set(previousHex, forKey: LightwalletTlsPin.previousUserDefaultsKey)

        XCTAssertEqual(LightwalletTlsPin.allowedPins(defaults: defaults, bundle: emptyBundle).count, 2)
        XCTAssertTrue(LightwalletTlsPin.matches(leafCertSha256: primaryData, defaults: defaults, bundle: emptyBundle))
        XCTAssertTrue(LightwalletTlsPin.matches(leafCertSha256: previousData, defaults: defaults, bundle: emptyBundle))
        XCTAssertFalse(LightwalletTlsPin.matches(leafCertSha256: wrongData, defaults: defaults, bundle: emptyBundle))
        XCTAssertTrue(
            LightwalletTlsPin.validateEndpoint(
                "https://epidermis-sandbox-marshland.ngrok-free.dev:443",
                defaults: defaults,
                bundle: emptyBundle
            )
        )
    }
}
