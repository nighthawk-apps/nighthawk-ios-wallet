//
//  SettingsTests.swift
//  stealthTests
//
//  Tests for NighthawkSettings, Security (6-digit PIN store & reducer),
//  About (dynamic version/build), and Advanced (theme selection).
//

import AppVersion
import ComposableArchitecture
import LocalAuthenticationClient
import Models
import UserPreferencesStorage
import XCTest
@testable import Home

@MainActor
final class SettingsTests: XCTestCase {
    override func tearDown() {
        SecurityPinStore.clearPin()
        super.tearDown()
    }

    func testSecurityPinStoreLifecycleAndValidation() {
        let testService = "com.nighthawkapps.darkfi.testPin.\(UUID().uuidString)"
        let testAccount = "unit_test_pin"
        defer { SecurityPinStore.clearPin(service: testService, account: testAccount) }

        XCTAssertFalse(SecurityPinStore.isPinSet(service: testService, account: testAccount))
        XCTAssertFalse(SecurityPinStore.isValidPinFormat("12345"))
        XCTAssertFalse(SecurityPinStore.isValidPinFormat("12345a"))
        XCTAssertTrue(SecurityPinStore.isValidPinFormat("482910"))

        XCTAssertFalse(SecurityPinStore.setPin("123", service: testService, account: testAccount))
        XCTAssertTrue(SecurityPinStore.setPin("482910", service: testService, account: testAccount))
        XCTAssertTrue(SecurityPinStore.isPinSet(service: testService, account: testAccount))
        XCTAssertTrue(SecurityPinStore.verifyPin("482910", service: testService, account: testAccount))
        XCTAssertFalse(SecurityPinStore.verifyPin("000000", service: testService, account: testAccount))

        SecurityPinStore.clearPin(service: testService, account: testAccount)
        XCTAssertFalse(SecurityPinStore.isPinSet(service: testService, account: testAccount))
    }

    func testSecurityReducerPinSetupVerifyChangeAndDisable() async {
        SecurityPinStore.clearPin()
        let store = TestStore(
            initialState: Security.State(),
            reducer: Security.init
        ) {
            $0.userStoredPreferences = .liveValue
            $0.localAuthenticationContext = LocalAuthContextClientGenerator {
                LocalAuthenticationContextClient(
                    biometryType: { .none },
                    canEvaluatePolicy: { _ in false },
                    evaluatePolicy: { _, _ in false }
                )
            }
        }

        // Start setup
        await store.send(.startSetupPinTapped) {
            $0.pinFlowStep = .setupEnter
        }
        await store.send(.pinInputChanged("12ab345678")) {
            $0.pinInput = "123456"
        }
        await store.send(.submitPinTapped) {
            $0.pinFlowStep = .setupConfirm(firstPin: "123456")
            $0.pinInput = ""
        }

        // Mismatch confirmation
        await store.send(.pinInputChanged("654321")) {
            $0.pinInput = "654321"
        }
        await store.send(.submitPinTapped) {
            $0.pinErrorMessage = "PINs did not match. Try again."
            $0.pinInput = ""
        }

        // Correct confirmation enables PIN
        await store.send(.pinInputChanged("123456")) {
            $0.pinInput = "123456"
            $0.pinErrorMessage = nil
        }
        await store.send(.submitPinTapped) {
            $0.isPinEnabled = true
            $0.pinFlowStep = .idle
            $0.pinInput = ""
            $0.pinStatusMessage = "6-digit App PIN enabled."
        }
        XCTAssertTrue(SecurityPinStore.isPinSet())

        // Verify PIN
        await store.send(.startVerifyPinTapped) {
            $0.pinFlowStep = .verifyOnly
            $0.pinStatusMessage = nil
        }
        await store.send(.pinInputChanged("123456")) {
            $0.pinInput = "123456"
        }
        await store.send(.submitPinTapped) {
            $0.pinFlowStep = .idle
            $0.pinInput = ""
            $0.pinStatusMessage = "PIN verified."
        }

        // Disable PIN
        await store.send(.startDisablePinTapped) {
            $0.pinFlowStep = .disableVerifyCurrent
            $0.pinStatusMessage = nil
        }
        await store.send(.pinInputChanged("123456")) {
            $0.pinInput = "123456"
        }
        await store.send(.submitPinTapped) {
            $0.isPinEnabled = false
            $0.pinFlowStep = .idle
            $0.pinInput = ""
            $0.pinStatusMessage = "App PIN disabled."
        }
        XCTAssertFalse(SecurityPinStore.isPinSet())
    }

    func testAboutOnAppearLoadsDynamicVersionAndBuild() async {
        let store = TestStore(
            initialState: About.State(),
            reducer: About.init
        ) {
            $0.appVersion = AppVersionClient(
                appVersion: { "3.01.19" },
                appBuild: { "30100819" }
            )
        }

        await store.send(.onAppear) {
            $0.appVersion = "3.01.19"
            $0.appBuild = "30100819"
        }
        XCTAssertEqual(store.state.versionDisplay, "Version 3.01.19 (30100819)")
    }

    func testAdvancedThemeSelectionPersistsWithoutBanditFlag() async {
        var savedTheme: NighthawkSetting.Theme?
        var prefs = UserPreferencesStorageClient.liveValue
        prefs.screenMode = { .keepOn }
        prefs.appIcon = { .default }
        prefs.theme = { .default }
        prefs.isBandit = { false }
        prefs.setTheme = { savedTheme = $0 }

        let store = TestStore(
            initialState: Advanced.State(),
            reducer: Advanced.init
        ) {
            $0.userStoredPreferences = prefs
        }

        await store.send(.onAppear) {
            $0.selectedScreenMode = .keepOn
            $0.selectedAppIcon = .default
            $0.theme = .cyberpunk
            $0.showBanditSettings = false
        }

        await store.send(.binding(.set(\.theme, .midnight))) {
            $0.theme = .midnight
        }
        XCTAssertEqual(savedTheme, .midnight)
    }
}
