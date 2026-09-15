import Foundation

/// Sans-I/O two- and three-phone radio lab. Frames are byte pipes, not a
/// live CoreBluetooth stack — Simulator BLE is not dual-role.
public enum MeshRadioScenario {
    public struct Phone {
        public var id: String
        public var meshOn = true
        public var peers: Set<String> = []
        public var inbox: [Data] = []

        public init(id: String) {
            self.id = id
        }
    }

    public static func chatFrame(from: Data, body: String) -> Data {
        MeshWireCodec.encode(MeshWirePacket(
            type: MeshWireCodec.dagEvent,
            ttl: 7,
            flags: 0,
            timestampMs: 0,
            sender: from,
            recipient: nil,
            payload: Data(body.utf8)
        ))!
    }

    public static func deliver(from: Phone, to: inout Phone, frame: Data) -> Bool {
        if !from.meshOn || !to.meshOn { return false }
        to.peers.insert(from.id)
        guard let pkt = MeshWireCodec.decode(frame) else { return false }
        if pkt.type == MeshWireCodec.lwdCtrl && !MeshLwdAllowlist.isAllowed(pkt.payload) {
            return false
        }
        to.inbox.append(frame)
        return true
    }

    public static func runThreePhoneScript() -> [String] {
        var log: [String] = []
        var a = Phone(id: "a")
        var r = Phone(id: "r")
        var g = Phone(id: "g")
        let idA = Data(repeating: 0x0A, count: 8)
        r.peers.formUnion(["a", "g"])
        a.peers.insert("r")
        g.peers.insert("r")
        log.append("connect a-r-g")

        let chat = chatFrame(from: idA, body: "#dev ping")
        precondition(deliver(from: a, to: &r, frame: chat))
        precondition(deliver(from: r, to: &g, frame: chat))
        log.append("chat")

        let sync = MeshWireCodec.encode(MeshWirePacket(
            type: MeshWireCodec.dagSync,
            ttl: 7,
            flags: 0,
            timestampMs: 0,
            sender: idA,
            recipient: nil,
            payload: Data([0x01, 0, 0, 0, 1, 0, 0])
        ))!
        precondition(deliver(from: a, to: &r, frame: sync))
        precondition(deliver(from: r, to: &g, frame: sync))
        log.append("dag-sync")

        r.meshOn = false
        precondition(!deliver(from: a, to: &r, frame: chatFrame(from: idA, body: "lost")))
        log.append("lost")

        r.meshOn = true
        r.peers = ["a", "g"]
        precondition(deliver(from: a, to: &r, frame: chatFrame(from: idA, body: "rejoin")))
        log.append("reconnect")

        r.peers = ["a", "g"]
        let idG = Data(repeating: 0x0C, count: 8)
        precondition(deliver(from: g, to: &r, frame: chatFrame(from: idG, body: "after-reset")))
        log.append("reset")
        return log
    }
}
