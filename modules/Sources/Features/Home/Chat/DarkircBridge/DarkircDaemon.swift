//
//  DarkircDaemon.swift
//  stealth
//
//  Manages the embedded darkirc lifecycle on iOS.
//
//  No custom chat logic here — this is a thin lifecycle manager that:
//    1. Writes TOML config to the app sandbox
//    2. Calls into Rust FFI to start/stop the darkirc daemon
//    3. Monitors status for the UI
//    4. Handles app backgrounding/resume
//
//  All P2P networking, DAG sync, message relay, and encryption
//  is handled by darkirc inside the Rust FFI library.
//

import DarkfiCore
import Foundation

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
/// No subprocess spawning is needed. All chat operations (P2P, DAG sync,
/// message relay, encryption) are handled by the Rust darkirc daemon.
public final class DarkircDaemonManager: @unchecked Sendable {
    public static let shared = DarkircDaemonManager()
    
    /// Active IRC client connected to the local darkirc daemon.
    /// Set by the Chat reducer after connecting.
    public var activeIrcClient: DarkircIrcClient?
    
    /// Returns the current status from the Rust FFI daemon.
    public var status: EmbeddedDarkircNodeStatus {
        EmbeddedDarkircNodeStatus(ffiStatus: darkircStatus())
    }
    
    /// Whether the darkirc runtime is available (always true — compiled into FFI).
    public var isBinaryAvailable: Bool { true }
    
    /// Config directory inside the app’s sandbox.
    public var configDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("darkirc", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    /// Datastore path for the sled DB (event graph, DAG history).
    public var datastorePath: String {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dbDir = docs.appendingPathComponent("darkirc_db", isDirectory: true)
        try? FileManager.default.createDirectory(at: dbDir, withIntermediateDirectories: true)
        return dbDir.path
    }
    
    private init() {}
    
    /// Start the embedded darkirc runtime.
    ///
    /// Calls into Rust FFI `startDarkirc()` which spawns background threads for
    /// P2P networking and event-graph DAG sync. Incoming events are relayed to
    /// Swift through the supplied `DarkircEventCallback.on_message` bridge
    /// (there is NO local IRC socket); outgoing messages go through the
    /// `send_chat_message` FFI. This matches Android's `DarkfiChatController`.
    /// Returns immediately — DAG sync proceeds asynchronously.
    ///
    /// When `useTor` is true the Rust daemon routes all P2P traffic over
    /// darkfi's embedded Tor (arti) transport using the `tor://` onion seeds,
    /// so the "Connected (Tor)" indicator reflects a real onion path. When
    /// false it connects over clearnet `tcp+tls` seeds.
    public func start(callback: DarkircEventCallback? = nil, useTor: Bool = false) throws {
        let currentStatus = status
        guard currentStatus != .running && currentStatus != .starting else {
            return // Already running
        }
        
        // Start darkirc via Rust FFI — spawns threads internally and connects
        // to the P2P seeds (over Tor when requested) to sync the event-graph DAG.
        try startDarkirc(datastorePath: datastorePath, useTor: useTor, callback: callback)
    }
    
    /// Stop the embedded darkirc runtime and disconnect IRC client.
    public func stop() {
        activeIrcClient?.disconnect()
        activeIrcClient = nil
        try? stopDarkirc()
    }
    
    // MARK: - App Lifecycle
    
    /// Ensure darkirc is running. Call this from `sceneWillEnterForeground`.
    ///
    /// If darkirc was still running (iOS ~30s background grace),
    /// the IRC bridge reconnects instantly. If it stopped, we do a
    /// full restart with DAG sync.
    public func ensureRunning() {
        let current = status
        switch current {
        case .running:
            // Still running — no action needed. The Rust daemon keeps its P2P
            // connection and event callback alive; nothing to reconnect.
            break
            
        case .notUsed, .failed:
            // Daemon stopped during background — full restart
            do {
                try start()
            } catch {
                // Will be shown in Chat tab status indicator
            }
            
        case .starting:
            break // Already starting
            
        case .missingBinary:
            break // Should never happen
        }
    }
    
    /// Call from `sceneDidEnterBackground`.
    /// We don't stop darkirc — let iOS's ~30s grace keep it alive.
    public func handleBackgrounding() {
        // No-op: let darkirc keep syncing during background grace period.
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
