import Foundation

/// ATT length-prefix and the few header bytes the engine needs to bind a
/// link to an 8-byte Nighthawk sender. Byte layout matches
/// `mesh/packet.rs` and the Android `AttFrameCodec`.
enum NighthawkMeshFraming {
    static let serviceUUID = "6e686d73-0001-4000-a000-4e6967687468"
    static let characteristicUUID = "6e686d73-0002-4000-a000-4e6967687468"
    static let senderLength = 8
    static let headerLength = 26
    static let flagHasRecipient: UInt8 = 0x01
    static let defaultFragmentBytes = 469
    static let minAttPayload = 20
    static let maxConnections = 8
    static let maxFrameBytes = (1024 * 1024) + headerLength + senderLength

    struct Hint {
        var sender: Data
        var recipient: Data?
    }

    static func payloadCap(mtu: Int) -> Int {
        let raw = max(minAttPayload, mtu - 3)
        return min(defaultFragmentBytes, raw)
    }

    static func hint(_ frame: Data) -> Hint? {
        guard frame.count >= headerLength else { return nil }
        guard frame[0] == 0x4E, frame[1] == 0x48, frame[2] == 1 else { return nil }
        let sender = frame.subdata(in: 14..<22)
        if frame[5] & flagHasRecipient != 0 {
            guard frame.count >= headerLength + senderLength else { return nil }
            let recipient = frame.subdata(in: 22..<30)
            return Hint(sender: sender, recipient: recipient)
        }
        return Hint(sender: sender, recipient: nil)
    }

    static func hex(_ id: Data) -> String {
        id.map { String(format: "%02x", $0) }.joined()
    }

    static func chunks(frame: Data, attPayload: Int) -> [Data] {
        let cap = payloadCap(mtu: attPayload + 3)
        var length = UInt32(frame.count).bigEndian
        var stream = Data(bytes: &length, count: 4)
        stream.append(frame)
        var out: [Data] = []
        var offset = 0
        while offset < stream.count {
            let end = min(offset + cap, stream.count)
            out.append(stream.subdata(in: offset..<end))
            offset = end
        }
        return out
    }
}

/// Reassembles `u32 BE length || frame` from ATT notifications and writes.
final class NighthawkAttAssembler {
    private var buf = Data()

    func reset() {
        buf.removeAll(keepingCapacity: true)
    }

    func ingest(_ chunk: Data) -> [Data] {
        if chunk.isEmpty { return [] }
        buf.append(chunk)
        var frames: [Data] = []
        while true {
            if buf.count < 4 { return frames }
            let length = (Int(buf[0]) << 24) | (Int(buf[1]) << 16) | (Int(buf[2]) << 8) | Int(buf[3])
            if length > NighthawkMeshFraming.maxFrameBytes {
                buf.removeAll(keepingCapacity: false)
                return frames
            }
            if buf.count < 4 + length { return frames }
            frames.append(buf.subdata(in: 4..<(4 + length)))
            buf.removeSubrange(0..<(4 + length))
        }
    }
}
