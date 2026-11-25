//
//  AppInitializationTests.swift
//  stealthTests
//
//  Tests for Splash launch routing, Nym wait/skip session override,
//  PIN unlock flow, and runtime DarkfiNetwork detection.
//

import ComposableArchitecture
import DarkfiCore
import Models
import Splash
import UserPreferencesStorage
import Utils
import XCTest

@MainActor
final class AppInitializationTests: XCTestCase {
    override func tearDown() {
        SessionPrivacyOverride.clear()
        SecurityPinStore.clearPin()
        super.tearDown()
    }

    func testPendingLaunchRoutingMatrix() {
        XCTAssertEqual(
            Splash.pendingLaunch(initializationState: .uninitialized, backupComplete: false, biometricsEnabled: false),
            .newUser
        )
        XCTAssertEqual(
            Splash.pendingLaunch(initializationState: .needsMigration, backupComplete: false, biometricsEnabled: false),
            .migration
        )
        XCTAssertEqual(
            Splash.pendingLaunch(initializationState: .keysMissing, backupComplete: true, biometricsEnabled: false),
            .failed(.keysMissing)
        )
        XCTAssertEqual(
            Splash.pendingLaunch(initializationState: .failed, backupComplete: true, biometricsEnabled: false),
            .failed(.failed)
        )
        XCTAssertEqual(
            Splash.pendingLaunch(initializationState: .initialized, backupComplete: false, biometricsEnabled: true),
            .needsBackup
        )
        XCTAssertEqual(
            Splash.pendingLaunch(initializationState: .initialized, backupComplete: true, biometricsEnabled: true),
            .authenticate
        )
        XCTAssertEqual(
            Splash.pendingLaunch(initializationState: .initialized, backupComplete: true, biometricsEnabled: false),
            .launchWallet
        )
        XCTAssertEqual(
            Splash.pendingLaunch(initializationState: .filesMissing, backupComplete: true, biometricsEnabled: false),
            .launchWallet
        )
    }

    func testNewUserRouteAvoidsDuplicateWelcomePush() {
        XCTAssertEqual(Splash.newUserRoute(hasCompletedInitialRoute: false), .openWelcome)
        XCTAssertEqual(Splash.newUserRoute(hasCompletedInitialRoute: true), .alreadyOnWelcome)
    }

    func testNymReadyDispatchesPendingLaunch() async {
        var initial = Splash.State()
        initial.waitingForNym = true
        initial.pendingLaunch = .launchWallet

        let store = TestStore(
            initialState: initial,
            reducer: Splash.init
        )

        await store.send(.nymReady) {
            $0.waitingForNym = false
            $0.nymFailed = false
            $0.pendingLaunch = nil
        }
        await store.receive(.delegate(.initializeSDKAndLaunchWallet))
    }

    func testContinueWithoutNymSetsSessionOverrideAndLaunches() async {
        SessionPrivacyOverride.clear()
        var initial = Splash.State()
        initial.waitingForNym = true
        initial.nymFailed = true
        initial.pendingLaunch = .newUser

        let store = TestStore(
            initialState: initial,
            reducer: Splash.init
        )

        await store.send(.continueWithoutNym) {
            $0.waitingForNym = false
            $0.nymFailed = false
            $0.nymSkipped = true
            $0.pendingLaunch = nil
        }
        await store.receive(.delegate(.handleNewUser))
        XCTAssertTrue(SessionPrivacyOverride.forceDirectThisSession)
    }

    func testSplashPinUnlockAuthenticatesAndLaunchesWallet() async {
        SecurityPinStore.clearPin()
        XCTAssertTrue(SecurityPinStore.setPin("246810"))

        var prefs = UserPreferencesStorageClient.liveValue
        prefs.areBiometricsEnabled = { false }
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let store = TestStore(
            initialState: Splash.State(),
            reducer: Splash.init
        ) {
            $0.date = .constant(now)
            $0.userStoredPreferences = prefs
        }

        await store.send(.authenticate) {
            $0.requiresPinEntry = true
        }

        await store.send(.pinInputChanged("000000")) {
            $0.pinInput = "000000"
        }
        await store.send(.submitPinTapped) {
            $0.pinInput = ""
            $0.pinError = "Incorrect PIN. Try again."
        }

        await store.send(.pinInputChanged("246810")) {
            $0.pinInput = "246810"
            $0.pinError = nil
        }
        await store.send(.submitPinTapped) {
            $0.requiresPinEntry = false
            $0.pinInput = ""
            $0.pinError = nil
            $0.hasAttemptedAuthentication = true
            $0.lastAuthenticatedTime = now
        }
        await store.receive(.delegate(.initializeSDKAndLaunchWallet))
    }

    func testRuntimeDarkfiNetworkDetectionDefaultsToTestnetInTestBundle() {
        XCTAssertEqual(DarkfiNetwork.active(), .testnet)
        XCTAssertEqual(DarkfiNetwork.activeLabel, "testnet")
    }
}
