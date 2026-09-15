import Foundation

public enum MeshDagAdmit: Equatable {
    case ignored
    case admitted
    case rejectedOversized
    case rejectedForbiddenLwd
}

/// Native-side DAG admit. Blob cap matches `EventGraph::MAX_MESH_EVENT_BLOB`.
/// RLN / `validate_new` stay in DarkFi ingest — this only keeps BLE from
/// queuing a compact-block dump.
public final class MeshDagBridge: @unchecked Sendable {
    public static let maxBlobBytes = 1024 * 1024 - 512
    private let maxBlob: Int
    private var admitted: [Data] = []
    private let lock = NSLock()

    public init(maxBlobBytes: Int = MeshDagBridge.maxBlobBytes) {
        self.maxBlob = maxBlobBytes
    }

    public var admittedCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return admitted.count
    }

    public func consider(_ pkt: MeshWirePacket) -> MeshDagAdmit {
        lock.lock()
        defer { lock.unlock() }
        if pkt.type == MeshWireCodec.lwdCtrl {
            return .rejectedForbiddenLwd
        }
        if pkt.type == MeshWireCodec.dagEvent || pkt.type == MeshWireCodec.dagSync {
            return .ignored
        }
        if pkt.type == MeshWireCodec.noiseEnc && pkt.payload.count > maxBlob {
            return .rejectedOversized
        }
        return .ignored
    }

    public func popAdmitted() -> [Data] {
        lock.lock()
        defer { lock.unlock() }
        let out = admitted
        admitted.removeAll()
        return out
    }
}
