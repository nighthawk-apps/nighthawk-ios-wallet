import Darwin
import Foundation
import Network

/// Runtime lookup of `nh_transport_*`. An older static library without the
/// symbols returns nil instead of failing the link of mesh.
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
        call0("nh_transport_on_network_changed")
    }

    public static func onBackground() {
        call0("nh_transport_on_background")
    }

    public static func onForeground() {
        call0("nh_transport_on_foreground")
    }

    public static func setMesh(_ on: Bool) {
        call1("nh_transport_set_mesh", on ? 1 : 0)
    }

    public static func continueWithoutNym() {
        call0("nh_transport_continue_without_nym")
    }

    public static func clearSessionOverride() {
        call0("nh_transport_clear_session_override")
    }

    /// `kind`: 0 Nym, 1 Tor, 2 Direct.
    public static func apply(kind: Int32, nymPort: Int32, torPort: Int32) {
        typealias Apply = @convention(c) (Int32, Int32, Int32) -> Int32
        guard let fn = symbol("nh_transport_apply", as: Apply.self) else { return }
        _ = fn(kind, nymPort, torPort)
    }

    private static func call0(_ name: String) {
        typealias Fn = @convention(c) () -> Int32
        guard let fn = symbol(name, as: Fn.self) else { return }
        _ = fn()
    }

    private static func call1(_ name: String, _ arg: Int32) {
        typealias Fn = @convention(c) (Int32) -> Int32
        guard let fn = symbol(name, as: Fn.self) else { return }
        _ = fn(arg)
    }

    private static func symbol<T>(_ name: String, as type: T.Type) -> T? {
        guard let raw = dlsym(UnsafeMutableRawPointer(bitPattern: -2), name) else {
            return nil
        }
        return unsafeBitCast(raw, to: type)
    }
}
