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

/// Same-role duplicate links after a privacy-address rotation or state restore.
/// Keeps the newest writable central-role connection. If the newest link is
/// still discovering its characteristic, consolidation waits so the fresh
/// address is not cancelled in favor of a stale one.
public enum NHBLERedundantLinkPolicy {
    public struct Link: Equatable {
        public var uuid: String
        public var peerID: String?
        public var isConnected: Bool
        public var hasCharacteristic: Bool
        public var lastConnectedAt: Date?

        public init(
            uuid: String,
            peerID: String?,
            isConnected: Bool,
            hasCharacteristic: Bool,
            lastConnectedAt: Date? = nil
        ) {
            self.uuid = uuid
            self.peerID = peerID
            self.isConnected = isConnected
            self.hasCharacteristic = hasCharacteristic
            self.lastConnectedAt = lastConnectedAt
        }
    }

    public static func keptUUID(
        ingressUUID: String?,
        mostRecentlyBoundUUID: String?,
        links: [Link],
        peerID: String
    ) -> String? {
        let bound = links.filter { $0.peerID == peerID && $0.isConnected }
        guard bound.count > 1 else { return nil }

        let writable = bound.filter(\.hasCharacteristic)
        let candidates = writable.isEmpty ? bound : writable

        if !writable.isEmpty,
           let newestBound = bound.compactMap(\.lastConnectedAt).max(),
           !writable.contains(where: { $0.lastConnectedAt == newestBound }) {
            return nil
        }

        if let newestDate = candidates.compactMap(\.lastConnectedAt).max() {
            let newest = candidates.filter { $0.lastConnectedAt == newestDate }
            if newest.count == 1 {
                return newest[0].uuid
            }
            return anchored(
                among: newest,
                ingressUUID: ingressUUID,
                mostRecentlyBoundUUID: mostRecentlyBoundUUID
            ) ?? newest.map(\.uuid).min()
        }

        return anchored(
            among: candidates,
            ingressUUID: ingressUUID,
            mostRecentlyBoundUUID: mostRecentlyBoundUUID
        )
    }

    public static func uuidsToRetire(links: [Link], peerID: String, keeping kept: String) -> [String] {
        links
            .filter { $0.peerID == peerID && $0.isConnected && $0.uuid != kept }
            .map(\.uuid)
    }

    private static func anchored(
        among candidates: [Link],
        ingressUUID: String?,
        mostRecentlyBoundUUID: String?
    ) -> String? {
        if let ingressUUID, candidates.contains(where: { $0.uuid == ingressUUID }) {
            return ingressUUID
        }
        if let mostRecentlyBoundUUID, candidates.contains(where: { $0.uuid == mostRecentlyBoundUUID }) {
            return mostRecentlyBoundUUID
        }
        return nil
    }
}

public enum NHBLEScanDutyPlan: Equatable {
    case continuous
    case dutyCycle(onDuration: TimeInterval, offDuration: TimeInterval)
}

/// Foreground scan duty once more than two peers are up and traffic is quiet.
/// Sparse meshes and recent frames stay on a continuous scan.
public enum NHBLEScanDutyPolicy {
    public static let highDegreeThreshold = 6
    public static let onDuration: TimeInterval = 5
    public static let offDuration: TimeInterval = 10
    public static let denseOnDuration: TimeInterval = 3
    public static let denseOffDuration: TimeInterval = 15
    public static let connectRateLimit: TimeInterval = 0.5
    public static let weakRSSICutoff = -90

    public static func plan(
        dutyEnabled: Bool,
        appIsActive: Bool,
        connectedCount: Int,
        hasRecentTraffic: Bool
    ) -> NHBLEScanDutyPlan {
        let forceContinuous = connectedCount <= 2 || hasRecentTraffic
        let shouldDuty = dutyEnabled && appIsActive && connectedCount > 0 && !forceContinuous
        guard shouldDuty else { return .continuous }
        if connectedCount >= highDegreeThreshold {
            return .dutyCycle(onDuration: denseOnDuration, offDuration: denseOffDuration)
        }
        return .dutyCycle(onDuration: onDuration, offDuration: offDuration)
    }

    public static func shouldConnect(rssi: Int, connectedCount: Int) -> Bool {
        if connectedCount == 0 { return true }
        return rssi >= weakRSSICutoff
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
