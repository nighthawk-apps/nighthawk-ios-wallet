import Foundation

public enum MeshAttPolicy {
    public static let attOverhead = 3
    public static let defaultMtu = 23
    public static let fragmentChunk = 469

    public static func writePayloadCap(mtu: Int) -> Int {
        min(fragmentChunk, max(20, mtu - attOverhead))
    }
}

public final class AttFrameAssembler {
    private var buf = Data()
    private let maxFrame: Int

    public init(maxFrame: Int = MeshWireCodec.maxPayload + MeshWireCodec.headerLen + 8) {
        self.maxFrame = maxFrame
    }

    public func reset() { buf.removeAll(keepingCapacity: false) }

    public func ingest(_ chunk: Data) -> [Data] {
        buf.append(chunk)
        var out: [Data] = []
        while buf.count >= 4 {
            let prefix = [UInt8](buf.prefix(4))
            let len = prefix.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
            if len > UInt32(maxFrame) {
                buf.removeAll()
                break
            }
            let need = 4 + Int(len)
            guard buf.count >= need else { break }
            out.append(buf.subdata(in: 4..<need))
            buf.removeSubrange(0..<need)
        }
        return out
    }
}

public enum AttFrameSplitter {
    public static func split(frame: Data, attPayload: Int) -> [Data] {
        let cap = max(1, attPayload)
        var stream = Data()
        var count = UInt32(frame.count)
        for shift in stride(from: 24, through: 0, by: -8) {
            stream.append(UInt8((count >> UInt32(shift)) & 0xFF))
        }
        stream.append(frame)
        var chunks: [Data] = []
        var i = stream.startIndex
        while i < stream.endIndex {
            let end = stream.index(i, offsetBy: cap, limitedBy: stream.endIndex) ?? stream.endIndex
            chunks.append(stream[i..<end])
            i = end
        }
        return chunks
    }
}
