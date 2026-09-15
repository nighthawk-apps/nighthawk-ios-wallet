import Foundation

public struct MeshWirePacket: Equatable {
    public var type: UInt8
    public var ttl: UInt8
    public var flags: UInt8
    public var timestampMs: UInt64
    public var sender: Data
    public var recipient: Data?
    public var payload: Data

    public init(
        type: UInt8,
        ttl: UInt8,
        flags: UInt8,
        timestampMs: UInt64,
        sender: Data,
        recipient: Data?,
        payload: Data
    ) {
        self.type = type
        self.ttl = ttl
        self.flags = flags
        self.timestampMs = timestampMs
        self.sender = sender
        self.recipient = recipient
        self.payload = payload
    }
}

/// Byte-identical to `darkfi-mobile-ffi` `mesh/packet.rs`.
public enum MeshWireCodec {
    public static let magic: [UInt8] = [0x4E, 0x48]
    public static let version: UInt8 = 1
    public static let headerLen = 26
    public static let senderLen = 8
    public static let flagHasRecipient: UInt8 = 0x01
    public static let maxPayload = 1024 * 1024

    public static let announce: UInt8 = 0xA1
    public static let noiseHs: UInt8 = 0xA2
    public static let noiseEnc: UInt8 = 0xA3
    public static let fragment: UInt8 = 0xA4
    public static let dagSync: UInt8 = 0xA5
    public static let dagEvent: UInt8 = 0xA6
    public static let lwdCtrl: UInt8 = 0xA7
    public static let bulkOffer: UInt8 = 0xA8
    public static let bulkJoin: UInt8 = 0xA9
    public static let ping: UInt8 = 0xAA
    public static let pong: UInt8 = 0xAB

    private static let known: Set<UInt8> = [
        announce, noiseHs, noiseEnc, fragment, dagSync, dagEvent,
        lwdCtrl, bulkOffer, bulkJoin, ping, pong
    ]

    public static func encode(_ pkt: MeshWirePacket) -> Data? {
        guard pkt.payload.count <= maxPayload, pkt.sender.count == senderLen else { return nil }
        if let rx = pkt.recipient, rx.count != senderLen { return nil }
        var flags = pkt.flags
        if pkt.recipient != nil {
            flags |= flagHasRecipient
        } else {
            flags &= ~flagHasRecipient
        }
        var out = Data()
        out.append(contentsOf: magic)
        out.append(version)
        out.append(pkt.type)
        out.append(pkt.ttl)
        out.append(flags)
        appendUInt64BE(&out, pkt.timestampMs)
        out.append(pkt.sender)
        if let rx = pkt.recipient { out.append(rx) }
        appendUInt32BE(&out, UInt32(pkt.payload.count))
        out.append(pkt.payload)
        return out
    }

    public static func decode(_ bytes: Data) -> MeshWirePacket? {
        guard bytes.count >= headerLen else { return nil }
        let b = [UInt8](bytes)
        guard b[0] == magic[0], b[1] == magic[1], b[2] == version else { return nil }
        guard known.contains(b[3]) else { return nil }
        let ttl = b[4]
        let flags = b[5]
        let timestampMs = readUInt64BE(b, 6)
        let sender = Data(b[14..<22])
        var off = 22
        var recipient: Data?
        if flags & flagHasRecipient != 0 {
            guard bytes.count >= off + senderLen + 4 else { return nil }
            recipient = Data(b[off..<(off + senderLen)])
            off += senderLen
        }
        guard bytes.count >= off + 4 else { return nil }
        let plen = Int(readUInt32BE(b, off))
        off += 4
        guard plen >= 0, plen <= maxPayload, bytes.count == off + plen else { return nil }
        return MeshWirePacket(
            type: b[3],
            ttl: ttl,
            flags: flags,
            timestampMs: timestampMs,
            sender: sender,
            recipient: recipient,
            payload: Data(b[off...])
        )
    }

    private static func appendUInt64BE(_ out: inout Data, _ value: UInt64) {
        for shift in stride(from: 56, through: 0, by: -8) {
            out.append(UInt8((value >> UInt64(shift)) & 0xFF))
        }
    }

    private static func appendUInt32BE(_ out: inout Data, _ value: UInt32) {
        for shift in stride(from: 24, through: 0, by: -8) {
            out.append(UInt8((value >> UInt32(shift)) & 0xFF))
        }
    }

    private static func readUInt64BE(_ b: [UInt8], _ off: Int) -> UInt64 {
        var v: UInt64 = 0
        for i in 0..<8 { v = (v << 8) | UInt64(b[off + i]) }
        return v
    }

    private static func readUInt32BE(_ b: [UInt8], _ off: Int) -> UInt32 {
        var v: UInt32 = 0
        for i in 0..<4 { v = (v << 8) | UInt32(b[off + i]) }
        return v
    }
}

public enum MeshLwdAllowlist {
    public static let maxCtrlBytes = 32 * 1024
    public static let allowed: Set<String> = [
        "GetLightInfo", "GetOmrCapabilities", "SendTransaction",
        "RegisterCluePublicKey", "GetCluePublicKey"
    ]
    public static let forbidden: Set<String> = [
        "GetUnifOmrDigest", "FetchPirBatch", "GetBlockRange",
        "GetNoteCommitments", "GetNullifiers", "GetCompactBlocks"
    ]

    public static func methodLeaf(_ payload: Data) -> String? {
        guard !payload.isEmpty, payload.count <= maxCtrlBytes else { return nil }
        let nl = payload.firstIndex(of: 0x0A) ?? payload.endIndex
        return String(data: payload[..<nl], encoding: .utf8)
    }

    public static func isForbidden(_ method: String) -> Bool {
        forbidden.contains(where: { $0.caseInsensitiveCompare(method) == .orderedSame })
    }

    public static func isAllowed(_ payload: Data) -> Bool {
        guard let method = methodLeaf(payload) else { return false }
        if isForbidden(method) { return false }
        return allowed.contains(where: { $0.caseInsensitiveCompare(method) == .orderedSame })
    }
}
