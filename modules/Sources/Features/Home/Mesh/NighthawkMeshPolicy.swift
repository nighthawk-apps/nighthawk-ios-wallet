import Foundation
import UIKit

/// iOS mesh policy. CoreBluetooth duty cycle is not configurable; this
/// encodes what the engine and UI are allowed to do in each scene state.
public enum NighthawkMeshPolicy {
    public static let bleCentralRestoreId = "com.nighthawkapps.ble.central"
    public static let blePeripheralRestoreId = "com.nighthawkapps.ble.peripheral"
    public static let walletRefreshTaskId = "com.nighthawkapps.sync"
    public static let walletProcessingTaskId = "com.nighthawkapps.sync.processing"

    public static let serviceUUIDString = "6E686D73-0001-4000-A000-4E6967687468"
    public static let characteristicUUIDString = "6E686D73-0002-4000-A000-4E6967687468"

    public static func gatewayReady(
        meshOn: Bool,
        gatewayOptIn: Bool,
        charging: Bool,
        unmetered: Bool
    ) -> Bool {
        meshOn && gatewayOptIn && charging && unmetered
    }

    /// Existing `BGAppRefresh` / `BGProcessing` must keep calling internet `refreshNow()`.
    public static func backgroundTaskMayStartUnifOmr(taskIdentifier: String) -> Bool {
        _ = taskIdentifier
        return false
    }

    public static func mayRunFullMesh(sceneForeground: Bool) -> Bool {
        sceneForeground
    }

    public static func mayFinishInFlightCtrl(backgroundTaskActive: Bool) -> Bool {
        backgroundTaskActive
    }

    public static func mayStartUnifOmrBulk(sceneForeground: Bool, gatewayReady: Bool, fromBgRefresh: Bool = false) -> Bool {
        sceneForeground && gatewayReady && !fromBgRefresh
    }

    public static func mayOriginateLwdCtrl(sceneForeground: Bool) -> Bool {
        sceneForeground
    }

    public static let backgroundDrainBudgetSeconds: TimeInterval = 30

    public static func gcsIntervalSeconds(sceneForeground: Bool) -> TimeInterval {
        sceneForeground ? 15 : 60
    }

    public static func isBitchatServiceUUID(_ uuid: String) -> Bool {
        uuid.lowercased().hasPrefix("f47b5e2d")
    }

    /// CoreBluetooth `CBManagerState` raw values (stable).
    public enum RadioUserState: Equatable {
        case pending
        case ready
        case poweredOff
        case unauthorized
        case unsupported
    }

    public static func radioUserState(centralRawValue: Int) -> RadioUserState {
        switch centralRawValue {
        case 5: return .ready // poweredOn
        case 4: return .poweredOff
        case 3: return .unauthorized
        case 2: return .unsupported
        default: return .pending
        }
    }

    public static func shouldRediscoverRestoredLink(
        peripheralConnected: Bool,
        hasCharacteristic: Bool
    ) -> Bool {
        peripheralConnected && !hasCharacteristic
    }

    public static func shouldReconnectRestoredLink(peripheralConnected: Bool) -> Bool {
        !peripheralConnected
    }
}

public enum NHBulkPolicy {
    public static let maxBytes: UInt64 = 200 * 1024 * 1024
    public static let maxSeconds: TimeInterval = 15 * 60
    public static let kindSoftAP: UInt8 = 2
    public static let kindMultipeer: UInt8 = 3
    /// Bonjour service type — 1–15 characters, matches Info.plist `_nighthawk-mesh._tcp`.
    public static let serviceType = "nighthawk-mesh"

    public static func mayStart(sceneForeground: Bool, gatewayReady: Bool, fromBgRefresh: Bool) -> Bool {
        NighthawkMeshPolicy.mayStartUnifOmrBulk(
            sceneForeground: sceneForeground,
            gatewayReady: gatewayReady,
            fromBgRefresh: fromBgRefresh
        )
    }
}
