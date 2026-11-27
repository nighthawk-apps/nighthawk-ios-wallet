import Foundation
import Network

private enum TransportApplyABI {
    @_silgen_name("nh_transport_apply")
    static func apply(_ kind: Int32, _ nymPort: Int32, _ torPort: Int32) -> Int32
}

/// Direct UniFFI + C ABI transport lifecycle hooks (no runtime `dlsym` lookup).
public enum TransportHooks {
    private static let lock = NSLock()
    private static var didInstall = false
    private static let pathMonitor = NWPathMonitor()

    public static func install() {
        lock.lock()
        let start = !didInstall
        didInstall = true
        lock.unlock()
        guard start else { return }
        pathMonitor.pathUpdateHandler = { _ in
            onNetworkChanged()
        }
        pathMonitor.start(queue: DispatchQueue(label: "nh.transport.path"))
    }

    public static func onNetworkChanged() {
        transportOnNetworkChanged()
    }

    public static func onBackground() {
        transportOnBackground()
    }

    public static func onForeground() {
        transportOnForeground()
    }

    public static func setMesh(_ isEnabled: Bool) {
        transportSetMeshEnabled(on: isEnabled)
    }

    public static func continueWithoutNym() {
        transportContinueWithoutNym()
    }

    public static func clearSessionOverride() {
        transportClearSessionOverride()
    }

    public static func setDirectDisabled(_ disabled: Bool) {
        transportSetDirectDisabled(disabled: disabled)
    }

    public static func isDirectDisabled() -> Bool {
        transportIsDirectDisabled()
    }

    /// `kind`: 0 Nym, 1 Tor, 2 Direct.
    public static func apply(kind: Int32, nymPort: Int32, torPort: Int32) {
        _ = TransportApplyABI.apply(kind, nymPort, torPort)
    }
}
