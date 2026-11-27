import Combine
import Foundation
import UIKit

/// App boundary for the Nighthawk mesh. Gateway relay stays off, matching
/// the Android coordinator for this pass. The radio keeps running in the
/// background when the user has turned mesh on.
@MainActor
public final class NighthawkMeshController: ObservableObject {
    public static let shared = NighthawkMeshController()

    @Published public private(set) var enabled: Bool
    @Published public private(set) var statusLine: String

    private let link = NighthawkBLELink()
    private let engine = NighthawkMeshEngine()
    private let defaultsKey = "nighthawk.meshEnabled"

    private init() {
        let stored = UserDefaults.standard.bool(forKey: defaultsKey)
        enabled = stored
        statusLine = stored ? "Mesh starting" : "Mesh off"
        link.onReady = { [weak engine] linkID, meshID in
            engine?.linkReady(linkID, advertisedMeshID: meshID)
        }
        link.onBytes = { [weak engine] linkID, chunk in
            engine?.ingest(linkID: linkID, chunk: chunk)
        }
        link.onDown = { [weak engine] linkID in
            engine?.linkDown(linkID)
        }
        engine.sendFrame = { [weak link] linkID, frame in
            link?.write(linkID: linkID, frame: frame)
        }
        engine.retireLink = { [weak link] linkID in
            link?.retire(linkID: linkID)
        }
    }

    public func noteStatus(_ line: String) {
        statusLine = line
    }

    public func setEnabled(_ isEnabled: Bool) {
        UserDefaults.standard.set(isEnabled, forKey: defaultsKey)
        enabled = isEnabled
        TransportHooks.setMesh(isEnabled)
        if isEnabled {
            startRadio(foreground: true)
        } else {
            link.stop()
            engine.stop()
        }
    }

    /// Disable nearby mesh, stop BLE, and wipe native mesh keys & state (wallet delete).
    public func wipe() {
        UserDefaults.standard.set(false, forKey: defaultsKey)
        enabled = false
        TransportHooks.setMesh(false)
        link.stop()
        engine.wipe()
    }

    /// Publish a serialized DarkIRC DAG frame to connected mesh peers.
    @discardableResult
    public nonisolated static func publishDag(_ bytes: Data) -> Bool {
        NighthawkMeshEngine.publishDag(bytes)
    }

    /// Pop the next inbound mesh event (if any) for DarkIRC bridge consumption.
    public nonisolated static func popInboundEvent() -> NighthawkMeshInboundEvent? {
        NighthawkMeshEngine.popInboundEvent()
    }

    /// Pop queued JSON-encoded mesh gateway/bulk control events.
    public nonisolated static func popEventsJSON() -> String? {
        NighthawkMeshEngine.popEventsJSON()
    }

    /// Last gateway peer 8-byte mesh ID, if known.
    public nonisolated static func lastGatewayPeer() -> Data? {
        NighthawkMeshEngine.lastGatewayPeer()
    }

    /// Drive gateway control queue once.
    @discardableResult
    public nonisolated static func pumpGateway() -> Bool {
        NighthawkMeshEngine.pumpGateway()
    }

    /// Submit a lightwalletd control RPC over the mesh to `dest` (8-byte peer ID).
    public nonisolated static func submitLwdCtrl(dest: Data, method: String, body: Data) -> Data? {
        NighthawkMeshEngine.submitLwdCtrl(dest: dest, method: method, body: body)
    }

    /// Request a bulk sync channel with `dest` (8-byte peer ID).
    public nonisolated static func submitBulkJoin(dest: Data) -> Data? {
        NighthawkMeshEngine.submitBulkJoin(dest: dest)
    }

    /// Set (or clear with nil/0) the active bulk-sync TCP override endpoint.
    @discardableResult
    public nonisolated static func setBulkTcp(host: String?, port: UInt16) -> Bool {
        NighthawkMeshEngine.setBulkTcp(host: host, port: port)
    }

    /// Account transferred bulk bytes against the native rate budget.
    public nonisolated static func recordBulkBytes(_ count: UInt64) -> Bool {
        NighthawkMeshEngine.recordBulkBytes(count)
    }

    /// Pin an X25519 peer static public key (32 bytes) for BLE mesh control frames.
    @discardableResult
    public nonisolated static func pinPeerKey(_ staticPublic: Data) -> Bool {
        NighthawkMeshEngine.pinPeerKey(staticPublic)
    }

    /// Unpin an X25519 peer static public key (32 bytes).
    @discardableResult
    public nonisolated static func unpinPeerKey(_ staticPublic: Data) -> Bool {
        NighthawkMeshEngine.unpinPeerKey(staticPublic)
    }

    /// Clear all pinned peer static public keys.
    public nonisolated static func clearPinnedPeers() {
        NighthawkMeshEngine.clearPinnedPeers()
    }

    /// Require authenticated pinned keys on BLE mesh control frames.
    public nonisolated static func setRequirePinnedControl(_ required: Bool) {
        NighthawkMeshEngine.setRequirePinnedControl(required)
    }

    /// Starts the radio again after launch when the user left mesh on.
    public func restoreIfEnabled() {
        guard enabled else { return }
        startRadio(foreground: true)
    }

    public func setForeground(_ foreground: Bool) {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let charging = Self.charging()
        engine.setPower(foreground: foreground, charging: charging)
        link.setForeground(foreground)
        if foreground && enabled {
            startRadio(foreground: true)
        }
    }

    private func startRadio(foreground: Bool) {
        UIDevice.current.isBatteryMonitoringEnabled = true
        engine.start(foreground: foreground, charging: Self.charging())
        link.start(foreground: foreground)
    }

    private static func charging() -> Bool {
        switch UIDevice.current.batteryState {
        case .charging, .full:
            return true
        default:
            return false
        }
    }
}
