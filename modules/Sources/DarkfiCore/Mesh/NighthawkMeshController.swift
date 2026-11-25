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
