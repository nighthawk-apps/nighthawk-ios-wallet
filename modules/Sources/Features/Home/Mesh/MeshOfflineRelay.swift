import Foundation

/// Wallet / chat path when lightwalletd or DarkIRC is unreachable.
/// Small RPCs ride BLE ctrl; UnifOMR never does — that is bulk join only.
public enum MeshOfflineRelay {
    public enum Plan: Equatable {
        case none
        case ctrl(dest: Data, method: String)
        case bulkJoin(dest: Data)
    }

    public static func plan(
        meshOn: Bool,
        internetUnreachable: Bool,
        needUnifOmr: Bool,
        sceneForeground: Bool,
        fromBgRefresh: Bool = false,
        dest: Data?,
        gatewayCaps: UInt8 = 0,
        method: String = "GetLightInfo"
    ) -> Plan {
        _ = gatewayCaps
        if !meshOn || !internetUnreachable { return .none }
        guard let dest, dest.count == 8 else { return .none }
        if !NighthawkMeshPolicy.mayOriginateLwdCtrl(sceneForeground: sceneForeground) {
            return .none
        }
        if needUnifOmr {
            if sceneForeground && !fromBgRefresh {
                return .bulkJoin(dest: dest)
            }
            return .none
        }
        if MeshLwdAllowlist.isForbidden(method) { return .none }
        let payload = Data("\(method)\n".utf8)
        guard MeshLwdAllowlist.isAllowed(payload) else { return .none }
        return .ctrl(dest: dest, method: method)
    }
}
