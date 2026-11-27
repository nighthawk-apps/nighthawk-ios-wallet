//
//  AppInitializationTests.swift
//  stealthTests
//
//  Tests for Splash launch routing, Nym wait/skip session override,
//  PIN unlock flow, and runtime DarkfiNetwork detection.
//

import ComposableArchitecture
import DarkfiCore
import DatabaseFiles
import Models
import Splash
import UserPreferencesStorage
import Utils
import WalletStorage
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

        var prefs = UserPreferencesStorageClient.liveValue
        prefs.disableDirectConnection = { false }

        let store = TestStore(
            initialState: initial,
            reducer: Splash.init
        ) {
            $0.userStoredPreferences = prefs
        }

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

        var prefs = UserPreferencesStorageClient.liveValue
        prefs.disableDirectConnection = { false }

        let store = TestStore(
            initialState: initial,
            reducer: Splash.init
        ) {
            $0.userStoredPreferences = prefs
        }

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

    func testSplashPinLockoutAfterFiveFailures() async {
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
        for _ in 1..<SecurityPinStore.maxFailedAttempts {
            await store.send(.pinInputChanged("000000")) {
                $0.pinInput = "000000"
                $0.pinError = nil
            }
            await store.send(.submitPinTapped) {
                $0.pinInput = ""
                $0.pinError = "Incorrect PIN. Try again."
            }
        }
        await store.send(.pinInputChanged("000000")) {
            $0.pinInput = "000000"
            $0.pinError = nil
        }
        await store.send(.submitPinTapped) {
            $0.pinInput = ""
            $0.pinError = "Too many attempts. Try again in 30 seconds."
        }
        await store.send(.pinInputChanged("246810")) {
            $0.pinInput = "246810"
            $0.pinError = nil
        }
        await store.send(.submitPinTapped) {
            $0.pinInput = ""
            $0.pinError = "Too many attempts. Try again in 30 seconds."
        }
    }

    func testRuntimeDarkfiNetworkDetectionDefaultsToTestnetInTestBundle() {
        XCTAssertEqual(DarkfiNetwork.active(), .testnet)
        XCTAssertEqual(DarkfiNetwork.activeLabel, "testnet")
    }

    func testSplashNymRetriesStaleWarmStartFailureBeforeSurfacingError() async {
        let mock = MockNymController(initialStatus: "failed") { startCall in
            startCall == 1 ? ("bootstrapping", false) : ("connected", true)
        }
        let clock = TestClock()
        var prefs = UserPreferencesStorageClient.liveValue
        prefs.walletPrivacyNetwork = { .nym }
        prefs.areBiometricsEnabled = { false }
        prefs.isUserBackupComplete = { false }
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let store = TestStore(
            initialState: Splash.State(),
            reducer: Splash.init
        ) {
            $0.continuousClock = clock
            $0.date = .constant(now)
            $0.databaseFiles = .testValue
            $0.walletStorage = .noOp
            $0.userStoredPreferences = prefs
            $0.nymBootstrap = mock.client
        }

        await store.send(.checkWalletInitialization) {
            $0.pendingLaunch = .newUser
            $0.waitingForNym = true
            $0.nymFailed = false
            $0.nymStartedAt = now
        }

        await mock.waitForStartCalls(1)
        await clock.advance(by: .milliseconds(500))
        mock.setState(status: "connected", running: true)
        await clock.advance(by: .milliseconds(500))

        await store.receive(.nymReady) {
            $0.waitingForNym = false
            $0.nymFailed = false
            $0.pendingLaunch = nil
        }
        await store.receive(.delegate(.handleNewUser))
        XCTAssertEqual(mock.startCalls, 1)
    }

    func testSplashNymAutoRetriesEarlyFailureAndReportsFailureOnlyAfterRetry() async {
        let mock = MockNymController(initialStatus: "stopped") { _ in
            ("failed", false)
        }
        let clock = TestClock()
        var prefs = UserPreferencesStorageClient.liveValue
        prefs.walletPrivacyNetwork = { .nym }
        prefs.areBiometricsEnabled = { false }
        prefs.isUserBackupComplete = { false }
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let store = TestStore(
            initialState: Splash.State(),
            reducer: Splash.init
        ) {
            $0.continuousClock = clock
            $0.date = .constant(now)
            $0.databaseFiles = .testValue
            $0.walletStorage = .noOp
            $0.userStoredPreferences = prefs
            $0.nymBootstrap = mock.client
        }

        await store.send(.checkWalletInitialization) {
            $0.pendingLaunch = .newUser
            $0.waitingForNym = true
            $0.nymFailed = false
            $0.nymStartedAt = now
        }

        await mock.waitForStartCalls(1)
        await clock.advance(by: .milliseconds(1500))
        await mock.waitForStartCalls(2)
        await clock.advance(by: .milliseconds(500))

        await store.receive(.nymFailed) {
            $0.nymFailed = true
        }
        XCTAssertEqual(mock.startCalls, 2)

        mock.setTransition { _ in ("connected", true) }
        await store.send(.retryNym) {
            $0.nymFailed = false
            $0.nymStartedAt = now
        }
        await mock.waitForStartCalls(3)
        await store.receive(.nymReady) {
            $0.waitingForNym = false
            $0.nymFailed = false
            $0.pendingLaunch = nil
        }
        await store.receive(.delegate(.handleNewUser))
    }

    func testSplashNymTreatsReconnectingAsReady() async {
        let mock = MockNymController(initialStatus: "reconnecting", running: false) { _ in
            ("reconnecting", false)
        }
        var prefs = UserPreferencesStorageClient.liveValue
        prefs.walletPrivacyNetwork = { .nym }
        prefs.areBiometricsEnabled = { false }
        prefs.isUserBackupComplete = { false }

        let store = TestStore(
            initialState: Splash.State(),
            reducer: Splash.init
        ) {
            $0.databaseFiles = .testValue
            $0.walletStorage = .noOp
            $0.userStoredPreferences = prefs
            $0.nymBootstrap = mock.client
        }

        await store.send(.checkWalletInitialization)
        await store.receive(.delegate(.handleNewUser))
        XCTAssertEqual(mock.startCalls, 0)
    }
}

private final class MockNymController: @unchecked Sendable {
    private let lock = NSLock()
    private var _status: String
    private var _running: Bool
    private var _startCalls = 0
    private var _onStart: (Int) -> (String, Bool)

    init(
        initialStatus: String,
        running: Bool = false,
        onStart: @escaping (Int) -> (String, Bool)
    ) {
        self._status = initialStatus
        self._running = running
        self._onStart = onStart
    }

    var startCalls: Int {
        lock.lock()
        defer { lock.unlock() }
        return _startCalls
    }

    func waitForStartCalls(_ expected: Int) async {
        for _ in 0..<200 {
            if startCalls >= expected { return }
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(5))
        }
    }

    func setState(status: String, running: Bool) {
        lock.lock()
        _status = status
        _running = running
        lock.unlock()
    }

    func setTransition(_ onStart: @escaping (Int) -> (String, Bool)) {
        lock.lock()
        _onStart = onStart
        lock.unlock()
    }

    var client: NymBootstrapClient {
        NymBootstrapClient(
            start: { _ in
                self.lock.lock()
                self._startCalls += 1
                let call = self._startCalls
                let (nextStatus, nextRunning) = self._onStart(call)
                self._status = nextStatus
                self._running = nextRunning
                self.lock.unlock()
                return nextStatus == "bootstrapping" || nextRunning
            },
            status: {
                self.lock.lock()
                defer { self.lock.unlock() }
                return self._status
            },
            isRunning: {
                self.lock.lock()
                defer { self.lock.unlock() }
                return self._running
            },
            stop: {
                self.lock.lock()
                self._status = "stopped"
                self._running = false
                self.lock.unlock()
            }
        )
    }
}
