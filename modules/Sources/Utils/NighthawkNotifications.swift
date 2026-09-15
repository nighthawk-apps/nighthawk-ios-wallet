import Foundation

extension Notification.Name {
    /// Posted when live `refreshNow` cannot reach lightwalletd. Mesh may
    /// originate BLE ctrl / bulk; `BGAppRefresh` must still not start UnifOMR.
    public static let nighthawkLightwalletdUnreachable =
        Notification.Name("com.nighthawkapps.lwd.unreachable")
}
