//
//  DarkircDaemon.swift
//  stealth
//
//  Manages the embedded darkirc lifecycle on iOS.
//
//  Thin lifecycle manager that:
//    1. Calls into Rust FFI to start/stop the darkirc daemon
//    2. Exposes status for the UI
//    3. Requests a short UIKit background task on scene background
//
//  All P2P networking, DAG sync, message relay, and encryption
//  is handled by darkirc inside the Rust FFI library (UniFFI callback bridge —
//  there is no local IRC socket).
//

import DarkfiCore
import Foundation
import UIKit

/// Status of the embedded darkirc node.
public enum EmbeddedDarkircNodeStatus: Equatable {
    case notUsed
    case starting
    case running
    case missingBinary
    case failed(String)

    /// Map from FFI status string to enum
    init(ffiStatus: String) {
        switch ffiStatus {
        case "not_running": self = .notUsed
        case "starting":    self = .starting
        case "running":     self = .running
        case "stopping":    self = .notUsed
        case "failed":      self = .failed("darkirc daemon failed")
        default:            self = .notUsed
        }
    }
}

/// Manages the embedded darkirc runtime for P2P IRC chat.
///
/// On iOS, darkirc is compiled as a Rust static library and runs in-process.
/// Incoming events arrive via UniFFI `DarkircEventCallback`; outgoing messages
/// go through `send_chat_message`.
public final class DarkircDaemonManager: @unchecked Sendable {
    public static let shared = DarkircDaemonManager()

    /// Extends execution briefly when the scene enters background (iOS ~30s max).
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    /// Returns the current status from the Rust FFI daemon.
    public var status: EmbeddedDarkircNodeStatus {
        EmbeddedDarkircNodeStatus(ffiStatus: darkircStatus())
    }

    /// Whether the darkirc runtime is available (always true — compiled into FFI).
    public var isBinaryAvailable: Bool { true }

    /// Config directory inside the app’s sandbox.
    public var configDirectory: URL {
        // swiftlint:disable:next force_unwrapping
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("darkirc", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Datastore path for the sled DB (event graph, DAG history).
    public var datastorePath: String {
        // swiftlint:disable:next force_unwrapping
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dbDir = docs.appendingPathComponent("darkirc_db", isDirectory: true)
        try? FileManager.default.createDirectory(at: dbDir, withIntermediateDirectories: true)
        return dbDir.path
    }

    private var lifecycleObservers: [NSObjectProtocol] = []

    private init() {
        // `willTerminate` often does not fire (iOS suspends instead of killing).
        // Register both here so sled flush does not depend on SwiftUI scenePhase.
        let term = NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleTermination()
        }
        let bg = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleBackgrounding()
        }
        lifecycleObservers = [term, bg]
    }

    /// Start the embedded darkirc runtime.
    ///
    /// Calls into Rust FFI `startDarkirc()` which spawns background threads for
    /// P2P networking and event-graph DAG sync. Incoming events are relayed to
    /// Swift through the supplied `DarkircEventCallback.on_message` bridge;
    /// outgoing messages go through `send_chat_message`.
    /// Returns immediately — DAG sync proceeds asynchronously.
    ///
    /// When `useTor` is true the Rust daemon dials onion seeds via SOCKS5
    /// (`127.0.0.1:torSocksPort` — usually embedded Arti). Callers must ensure
    /// Arti is bootstrapped first (`TorBootstrap.ensureReady`).
    /// When false it connects over clearnet `tcp+tls` seeds.
    public func start(
        callback: DarkircEventCallback? = nil,
        useTor: Bool = false,
        torSocksPort: UInt16 = 9050
    ) throws {
        let currentStatus = status
        guard currentStatus != .running && currentStatus != .starting else {
            return // Already running
        }

        try startDarkirc(
            datastorePath: datastorePath,
            useTor: useTor,
            torSocksPort: torSocksPort,
            callback: callback
        )
    }

    /// Stop the embedded darkirc runtime.
    public func stop() {
        try? stopDarkirc()
    }

    /// Stop any in-flight start so a fresh `start(callback:)` can attach the bridge.
    ///
    /// If the daemon thread crashed without resetting `DAEMON_STATUS` (e.g. thread
    /// abort or stack overflow), the drain loop will time out (10s). In that case
    /// we proceed anyway — `start_darkirc()` will return a descriptive error if
    /// the status is truly stuck.
    public func restartForChat(
        callback: DarkircEventCallback,
        useTor: Bool,
        torSocksPort: UInt16 = 9050
    ) async throws {
        stop()
        for _ in 0..<40 {
            let status = darkircStatus()
            if status == "not_running" || status == "failed" {
                break
            }
            if status == "running" {
                try? stopDarkirc()
            }
            try await Task.sleep(for: .milliseconds(250))
        }
        if useTor {
            let ready = await TorBootstrap.ensureReady(socksPort: torSocksPort)
            guard ready else {
                throw NSError(
                    domain: "DarkircDaemon",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Tor (Arti) failed to bootstrap for chat"]
                )
            }
        }
        try start(callback: callback, useTor: useTor, torSocksPort: torSocksPort)
    }

    // MARK: - App Lifecycle

    /// Call when the scene enters background. Requests a short UIKit background
    /// task so the in-process UniFFI darkirc threads can keep sockets alive for
    /// the OS-allowed grace window (~30s). When the OS expiration handler fires,
    /// we gracefully stop darkirc so Sled DB is cleanly flushed before the
    /// process is suspended. Chat reconnects on resume via the Chat reducer's
    /// `scenePhaseChanged(.active)` (with a fresh event callback).
    public func handleBackgrounding() {
        endBackgroundTask()
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "darkirc.backgroundExecution") { [weak self] in
            // Expiration handler: gracefully stop darkirc so Sled DB is flushed.
            self?.stop()
            self?.endBackgroundTask()
        }
    }

    /// Call when the scene becomes active again — ends any outstanding background task.
    public func handleForegrounding() {
        endBackgroundTask()
    }

    /// Gracefully stop darkirc and end the background task. Called on app
    /// termination and from the expiration handler.
    public func handleTermination() {
        stop()
        endBackgroundTask()
    }

    private func endBackgroundTask() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
}

/// Errors for darkirc daemon management.
public enum DarkircError: Error, LocalizedError {
    case missingBinary
    case launchFailed(String)

    public var errorDescription: String? {
        switch self {
        case .missingBinary:
            return "darkirc runtime not available in the Rust FFI library"
        case .launchFailed(let detail):
            return "Failed to start darkirc: \(detail)"
        }
    }
}
