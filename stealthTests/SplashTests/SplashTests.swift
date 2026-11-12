//
//  SplashTests.swift
//  stealthTests
//
//  First-launch splash gates: Nym by default, Tor only when selected.
//

import AppVersion
import ComposableArchitecture
import DarkfiCore
import DatabaseFiles
import Darwin
import Generated
import Splash
import UserPreferencesStorage
import WalletStorage
import XCTest

private final class StopFlag: @unchecked Sendable {
    var value = false
}

@MainActor
final class SplashTests: XCTestCase {
    func testFirstLaunchWaitsForNymThenOnboards() async {
        let (stream, continuation) = AsyncStream.makeStream(of: Bool.self)
        defer { continuation.finish() }

        let store = TestStore(initialState: Splash.State()) {
            Splash()
        } withDependencies: {
            $0.appVersion = .mock
            $0.continuousClock = ImmediateClock()
            $0.walletStorage = .noOp
            $0.databaseFiles = .noOp
            $0.privacyNetwork.current = { .nym }
            $0.userStoredPreferences.areBiometricsEnabled = { false }
            $0.userStoredPreferences.isUserBackupComplete = { false }
            $0.userStoredPreferences.hasCompletedOnboarding = { false }
            $0.nymBootstrap.ensureReady = { _ in
                await stream.first { _ in true } ?? false
            }
            $0.nymBootstrap.stop = {}
        }

        await store.send(.onAppear) {
            $0.didStartLaunch = true
            $0.appVersion = "0.0.1"
            $0.networkGate = .nym
            $0.statusMessage = L10n.Nighthawk.Splash.nymBootstrapping
            $0.showDisableTorButton = true
        }
        await store.receive(\.checkWalletInitialization) {
            $0.walletCheckComplete = true
        }

        continuation.yield(true)
        await store.receive(\.torBootstrapSucceeded) {
            $0.statusMessage = L10n.Nighthawk.Splash.nymReady
            $0.showDisableTorButton = false
            $0.torGateOpen = true
            $0.didDispatchRoute = true
        }
        await store.receive(.delegate(.handleNewUser))
    }

    func testSelectedTorStillBootstrapsTor() async {
        let (stream, continuation) = AsyncStream.makeStream(of: Bool.self)
        defer { continuation.finish() }

        let store = TestStore(initialState: Splash.State()) {
            Splash()
        } withDependencies: {
            $0.appVersion = .mock
            $0.continuousClock = ImmediateClock()
            $0.walletStorage = .noOp
            $0.databaseFiles = .noOp
            $0.privacyNetwork.current = { .tor }
            $0.userStoredPreferences.torSocksPort = { "9050" }
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
            $0.networkGate = .tor
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

    func testDirectSkipsMixnetGate() async {
        let store = TestStore(initialState: Splash.State()) {
            Splash()
        } withDependencies: {
            $0.appVersion = .mock
            $0.continuousClock = ImmediateClock()
            $0.walletStorage = .noOp
            $0.databaseFiles = .noOp
            $0.privacyNetwork.current = { .direct }
            $0.userStoredPreferences.areBiometricsEnabled = { false }
            $0.userStoredPreferences.isUserBackupComplete = { false }
            $0.userStoredPreferences.hasCompletedOnboarding = { false }
        }

        await store.send(.onAppear) {
            $0.didStartLaunch = true
            $0.appVersion = "0.0.1"
            $0.networkGate = .direct
            $0.torGateOpen = true
        }
        await store.receive(\.checkWalletInitialization) {
            $0.walletCheckComplete = true
            $0.didDispatchRoute = true
        }
        await store.receive(.delegate(.handleNewUser))
    }

    func testContinueWithoutNymUnblocksOnboarding() async {
        let (stream, continuation) = AsyncStream.makeStream(of: Bool.self)
        defer { continuation.finish() }
        let stopped = StopFlag()

        let store = TestStore(initialState: Splash.State()) {
            Splash()
        } withDependencies: {
            $0.appVersion = .mock
            $0.continuousClock = ImmediateClock()
            $0.walletStorage = .noOp
            $0.databaseFiles = .noOp
            $0.privacyNetwork.current = { .nym }
            $0.privacyNetwork.setDirect = {}
            $0.userStoredPreferences.areBiometricsEnabled = { false }
            $0.userStoredPreferences.isUserBackupComplete = { false }
            $0.userStoredPreferences.hasCompletedOnboarding = { false }
            $0.userStoredPreferences.setTorForWalletEnabled = { _ in }
            $0.userStoredPreferences.setTorForChatEnabled = { _ in }
            $0.nymBootstrap.ensureReady = { _ in
                await stream.first { _ in true } ?? false
            }
            $0.nymBootstrap.stop = { stopped.value = true }
        }

        await store.send(.onAppear) {
            $0.didStartLaunch = true
            $0.appVersion = "0.0.1"
            $0.networkGate = .nym
            $0.statusMessage = L10n.Nighthawk.Splash.nymBootstrapping
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
        XCTAssertTrue(stopped.value)
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
            $0.privacyNetwork.current = { .nym }
            $0.userStoredPreferences.areBiometricsEnabled = { false }
            $0.userStoredPreferences.isUserBackupComplete = { true }
            $0.userStoredPreferences.hasCompletedOnboarding = { false }
            $0.nymBootstrap.ensureReady = { _ in
                await stream.first { _ in true } ?? false
            }
            $0.nymBootstrap.stop = {}
        }

        await store.send(.onAppear) {
            $0.didStartLaunch = true
            $0.appVersion = "0.0.1"
            $0.networkGate = .nym
            $0.statusMessage = L10n.Nighthawk.Splash.nymBootstrapping
            $0.showDisableTorButton = true
        }
        await store.receive(\.checkWalletInitialization) {
            $0.walletCheckComplete = true
            $0.initializationState = .filesMissing
        }

        continuation.yield(true)
        await store.receive(\.torBootstrapSucceeded) {
            $0.statusMessage = L10n.Nighthawk.Splash.nymReady
            $0.showDisableTorButton = false
            $0.torGateOpen = true
            $0.didDispatchRoute = true
        }
        await store.receive(.delegate(.handlePostBackupOnboarding))
    }

    func testNymFailureKeepsTheGateClosed() async {
        let (stream, continuation) = AsyncStream.makeStream(of: Bool.self)
        defer { continuation.finish() }

        let store = TestStore(initialState: Splash.State()) {
            Splash()
        } withDependencies: {
            $0.appVersion = .mock
            $0.continuousClock = ImmediateClock()
            $0.walletStorage = .noOp
            $0.databaseFiles = .noOp
            $0.privacyNetwork.current = { .nym }
            $0.userStoredPreferences.areBiometricsEnabled = { false }
            $0.userStoredPreferences.isUserBackupComplete = { false }
            $0.userStoredPreferences.hasCompletedOnboarding = { false }
            $0.nymBootstrap.ensureReady = { _ in
                await stream.first { _ in true } ?? false
            }
        }

        await store.send(.onAppear) {
            $0.didStartLaunch = true
            $0.appVersion = "0.0.1"
            $0.networkGate = .nym
            $0.statusMessage = L10n.Nighthawk.Splash.nymBootstrapping
            $0.showDisableTorButton = true
        }
        await store.receive(\.checkWalletInitialization) {
            $0.walletCheckComplete = true
        }
        continuation.yield(false)
        await store.receive(\.torBootstrapFailed) {
            $0.statusMessage = L10n.Nighthawk.Splash.nymFailed
            $0.showDisableTorButton = true
        }
    }
}

/// Live mixnet start against the real in-process proxy. Not a reducer test:
/// it boots Nym, checks the SOCKS port, then stops it.
final class NymStartTests: XCTestCase {
    override func setUp() {
        super.setUp()
        executionTimeAllowance = 240
    }

    func testNymProxyStartsConnectsAndAcceptsSocks() async throws {
        let port = NymBootstrap.defaultSocksPort
        let started = Date()
        let ready = await NymBootstrap.ensureReady(socksPort: port, timeoutSeconds: 180)
        let status = nymStatus()
        XCTAssertTrue(
            ready,
            "Nym did not become ready in \(Int(Date().timeIntervalSince(started)))s (status=\(status))"
        )
        XCTAssertTrue(
            status == "connected" || status == "reconnecting",
            "unexpected nym status \(status)"
        )

        let greeting = try socksGreeting(port: port)
        XCTAssertEqual(greeting, [0x05, 0x00], "SOCKS greeting \(greeting)")

        NymBootstrap.stop()
        let stopped = await statusBecomesStopped(timeoutSeconds: 15)
        XCTAssertTrue(stopped, "nym status stayed \(nymStatus()) after stop")
    }

    private func statusBecomesStopped(timeoutSeconds: Int) async -> Bool {
        let deadline = Date().addingTimeInterval(TimeInterval(timeoutSeconds))
        while Date() < deadline {
            if nymStatus() == "stopped" || nymStatus() == "failed" {
                return nymStatus() == "stopped"
            }
            try? await Task.sleep(for: .milliseconds(200))
        }
        return nymStatus() == "stopped"
    }

    /// SOCKS5 no-auth greeting. Does not open a remote connection.
    private func socksGreeting(port: UInt16) throws -> [UInt8] {
        let fd = socket(AF_INET, SOCK_STREAM, 0)
        XCTAssertGreaterThanOrEqual(fd, 0)
        defer { close(fd) }
        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        addr.sin_addr = in_addr(s_addr: inet_addr("127.0.0.1"))
        var timeout = timeval(tv_sec: 10, tv_usec: 0)
        setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
        setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
        let connected = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        XCTAssertEqual(connected, 0, "SOCKS connect failed errno \(errno)")
        let hello: [UInt8] = [0x05, 0x01, 0x00]
        let wrote = hello.withUnsafeBytes { raw -> Int in
            guard let base = raw.baseAddress else { return -1 }
            return send(fd, base, hello.count, 0)
        }
        XCTAssertEqual(wrote, hello.count)
        var reply = [UInt8](repeating: 0, count: 2)
        let got = reply.withUnsafeMutableBytes { raw -> Int in
            guard let base = raw.baseAddress else { return -1 }
            return recv(fd, base, 2, 0)
        }
        XCTAssertEqual(got, 2, "short SOCKS reply")
        return reply
    }
}
