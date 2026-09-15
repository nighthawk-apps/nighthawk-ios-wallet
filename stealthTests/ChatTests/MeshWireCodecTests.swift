import Home
import XCTest

final class MeshWireCodecTests: XCTestCase {
    func testGoldenAnnounceMatchesRust() {
        let frame = Data([
            0x4E, 0x48, 0x01, 0xA1, 0x07, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11,
            0x00, 0x00, 0x00, 0x01, 0x00
        ])
        let pkt = MeshWireCodec.decode(frame)
        XCTAssertNotNil(pkt)
        XCTAssertEqual(pkt?.type, MeshWireCodec.announce)
        XCTAssertEqual(pkt?.ttl, 7)
        XCTAssertEqual(pkt?.timestampMs, 0)
        XCTAssertEqual(pkt?.payload, Data([0x00]))
        XCTAssertEqual(MeshWireCodec.encode(pkt!), frame)
    }

    func testRejectBitchatOpcode() {
        var frame = Data([
            0x4E, 0x48, 0x01, 0xAA, 0x07, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x01, 0x01
        ])
        frame[3] = 0x01
        XCTAssertNil(MeshWireCodec.decode(frame))
    }

    func testLwdAllowlistRejectsUnifOmr() {
        XCTAssertFalse(MeshLwdAllowlist.isAllowed(Data("GetUnifOmrDigest\n".utf8)))
        XCTAssertTrue(MeshLwdAllowlist.isAllowed(Data("GetLightInfo\n".utf8)))
    }

    func testAttRoundtrip() {
        let frame = Data((0..<800).map { UInt8(truncatingIfNeeded: $0) })
        let chunks = AttFrameSplitter.split(frame: frame, attPayload: 20)
        XCTAssertGreaterThan(chunks.count, 1)
        let asm = AttFrameAssembler()
        var out: [Data] = []
        for c in chunks { out.append(contentsOf: asm.ingest(c)) }
        XCTAssertEqual(out.count, 1)
        XCTAssertEqual(out[0], frame)
    }

    func testLinkPolicyRejectsBitchatUuid() {
        XCTAssertFalse(NighthawkMeshPolicy.isBitchatServiceUUID(NHBLELinkPolicy.serviceUUID.uuidString))
        XCTAssertEqual(NHBLELinkPolicy.scanServices().count, 1)
        XCTAssertEqual(NHBLELinkPolicy.maxConnections, 6)
        XCTAssertTrue(NHBLELinkPolicy.centralRestoreId.contains("central"))
    }

    func testDagBridgeRejectsOversizedEvent() {
        let bridge = MeshDagBridge()
        let pkt = MeshWirePacket(
            type: MeshWireCodec.noiseEnc,
            ttl: 0,
            flags: 0,
            timestampMs: 0,
            sender: Data(repeating: 2, count: 8),
            recipient: Data(repeating: 3, count: 8),
            payload: Data(repeating: 1, count: MeshDagBridge.maxBlobBytes + 1)
        )
        XCTAssertEqual(bridge.consider(pkt), .rejectedOversized)
        XCTAssertEqual(bridge.admittedCount, 0)
    }

    func testDagBridgeIgnoresPlaintextDagEvent() {
        let bridge = MeshDagBridge()
        let pkt = MeshWirePacket(
            type: MeshWireCodec.dagEvent,
            ttl: 7,
            flags: 0,
            timestampMs: 0,
            sender: Data(repeating: 2, count: 8),
            recipient: nil,
            payload: Data("channel\nnick\nbody".utf8)
        )
        XCTAssertEqual(bridge.consider(pkt), .ignored)
        XCTAssertEqual(bridge.admittedCount, 0)
    }

    func testInboxDropsForbiddenLwd() {
        let c = NighthawkMeshController.shared
        let before = c.acceptedFrameCount
        let pkt = MeshWirePacket(
            type: MeshWireCodec.lwdCtrl,
            ttl: 0,
            flags: 0,
            timestampMs: 0,
            sender: Data(repeating: 1, count: 8),
            recipient: nil,
            payload: Data("GetUnifOmrDigest\n".utf8)
        )
        let frame = MeshWireCodec.encode(pkt)!
        c.meshLinkDidReceive(frame)
        XCTAssertEqual(c.acceptedFrameCount, before)
    }

    func testInboxIgnoresPlaintextDagEvent() {
        let c = NighthawkMeshController.shared
        let before = c.acceptedFrameCount
        let pkt = MeshWirePacket(
            type: MeshWireCodec.dagEvent,
            ttl: 7,
            flags: 0,
            timestampMs: 0,
            sender: Data(repeating: 1, count: 8),
            recipient: nil,
            payload: Data("channel\nnick\nbody".utf8)
        )
        let frame = MeshWireCodec.encode(pkt)!
        c.meshLinkDidReceive(frame)
        XCTAssertEqual(c.acceptedFrameCount, before)
    }
}
