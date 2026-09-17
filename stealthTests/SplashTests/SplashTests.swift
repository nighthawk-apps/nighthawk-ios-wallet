//
//  SplashTests.swift
//  stealthTests
//
//  First-launch splash gates: version + Tor connecting before onboarding.
//

import AppVersion
import ComposableArchitecture
import DatabaseFiles
import Generated
import Splash
import UserPreferencesStorage
import WalletStorage
import XCTest

@MainActor
final class SplashTests: XCTestCase {
    func testFirstLaunchWaitsForTorThenOnboards() async {
        let (stream, continuation) = AsyncStream.makeStream(of: Bool.self)
        defer { continuation.finish() }

        let store = TestStore(initialState: Splash.State()) {
            Splash()
        } withDependencies: {
            $0.appVersion = .mock
            $0.continuousClock = ImmediateClock()
            $0.walletStorage = .noOp
            $0.databaseFiles = .noOp
            $0.userStoredPreferences.torForWalletEnabled = { true }
            $0.userStoredPreferences.torForChatEnabled = { true }
            $0.userStoredPreferences.areBiometricsEnabled = { false }
            $0.userStoredPreferences.isUserBackupComplete = { false }
            $0.userStoredPreferences.hasCompletedOnboarding = { false }
            $0.torBootstrap.ensureReady = { _ in
                await stream.first { _ in true } ?? false
            }
            $0.torBootstrap.stop = {}
        }

        await store.send(.onAppear) {
            $0.didStartLaunch = true
            $0.appVersion = "0.0.1"
            $0.statusMessage = L10n.Nighthawk.Splash.torBootstrapping
            $0.showDisableTorButton = true
        }
        await store.receive(\.checkWalletInitialization) {
            $0.walletCheckComplete = true
        }

        continuation.yield(true)
        await store.receive(\.torBootstrapSucceeded) {
            $0.statusMessage = L10n.Nighthawk.Splash.torReady
            $0.showDisableTorButton = false
            $0.torGateOpen = true
            $0.didDispatchRoute = true
        }
        await store.receive(.delegate(.handleNewUser))
    }

    func testContinueWithoutTorUnblocksOnboarding() async {
        let (stream, continuation) = AsyncStream.makeStream(of: Bool.self)
        defer { continuation.finish() }

        let store = TestStore(initialState: Splash.State()) {
            Splash()
        } withDependencies: {
            $0.appVersion = .mock
            $0.continuousClock = ImmediateClock()
            $0.walletStorage = .noOp
            $0.databaseFiles = .noOp
            $0.userStoredPreferences.torForWalletEnabled = { true }
            $0.userStoredPreferences.torForChatEnabled = { true }
            $0.userStoredPreferences.areBiometricsEnabled = { false }
            $0.userStoredPreferences.isUserBackupComplete = { false }
            $0.userStoredPreferences.hasCompletedOnboarding = { false }
            $0.userStoredPreferences.setTorForWalletEnabled = { _ in }
            $0.userStoredPreferences.setTorForChatEnabled = { _ in }
            $0.torBootstrap.ensureReady = { _ in
                await stream.first { _ in true } ?? false
            }
            $0.torBootstrap.stop = {}
        }

        await store.send(.onAppear) {
            $0.didStartLaunch = true
            $0.appVersion = "0.0.1"
            $0.statusMessage = L10n.Nighthawk.Splash.torBootstrapping
            $0.showDisableTorButton = true
        }
        await store.receive(\.checkWalletInitialization) {
            $0.walletCheckComplete = true
        }

        await store.send(.disableTorAndContinue) {
            $0.statusMessage = nil
            $0.showDisableTorButton = false
            $0.torGateOpen = true
            $0.didDispatchRoute = true
        }
        await store.receive(.delegate(.handleNewUser))
    }

    func testAfterBackupShowsOnboardingBeforeHome() async {
        let (stream, continuation) = AsyncStream.makeStream(of: Bool.self)
        defer { continuation.finish() }

        let store = TestStore(initialState: Splash.State()) {
            Splash()
        } withDependencies: {
            $0.appVersion = .mock
            $0.continuousClock = ImmediateClock()
            $0.walletStorage = .noOp
            $0.walletStorage.areKeysPresent = { true }
            $0.databaseFiles = .noOp
            $0.userStoredPreferences.torForWalletEnabled = { true }
            $0.userStoredPreferences.torForChatEnabled = { true }
            $0.userStoredPreferences.areBiometricsEnabled = { false }
            $0.userStoredPreferences.isUserBackupComplete = { true }
            $0.userStoredPreferences.hasCompletedOnboarding = { false }
            $0.torBootstrap.ensureReady = { _ in
                await stream.first { _ in true } ?? false
            }
            $0.torBootstrap.stop = {}
        }

        await store.send(.onAppear) {
            $0.didStartLaunch = true
            $0.appVersion = "0.0.1"
            $0.statusMessage = L10n.Nighthawk.Splash.torBootstrapping
            $0.showDisableTorButton = true
        }
        await store.receive(\.checkWalletInitialization) {
            $0.walletCheckComplete = true
            $0.initializationState = .filesMissing
        }

        continuation.yield(true)
        await store.receive(\.torBootstrapSucceeded) {
            $0.statusMessage = L10n.Nighthawk.Splash.torReady
            $0.showDisableTorButton = false
            $0.torGateOpen = true
            $0.didDispatchRoute = true
        }
        await store.receive(.delegate(.handlePostBackupOnboarding))
    }
}
