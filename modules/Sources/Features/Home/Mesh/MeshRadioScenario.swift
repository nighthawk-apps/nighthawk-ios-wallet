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
        var alice = Phone(id: "a")
        var relay = Phone(id: "r")
        var gateway = Phone(id: "g")
        let idAlice = Data(repeating: 0x0A, count: 8)
        relay.peers.formUnion(["a", "g"])
        alice.peers.insert("r")
        gateway.peers.insert("r")
        log.append("connect a-r-g")

        let chat = chatFrame(from: idAlice, body: "#dev ping")
        precondition(deliver(from: alice, to: &relay, frame: chat))
        precondition(deliver(from: relay, to: &gateway, frame: chat))
        log.append("chat")

        let sync = MeshWireCodec.encode(MeshWirePacket(
            type: MeshWireCodec.dagSync,
            ttl: 7,
            flags: 0,
            timestampMs: 0,
            sender: idAlice,
            recipient: nil,
            payload: Data([0x01, 0, 0, 0, 1, 0, 0])
        ))!
        precondition(deliver(from: alice, to: &relay, frame: sync))
        precondition(deliver(from: relay, to: &gateway, frame: sync))
        log.append("dag-sync")

        relay.meshOn = false
        precondition(!deliver(from: alice, to: &relay, frame: chatFrame(from: idAlice, body: "lost")))
        log.append("lost")

        relay.meshOn = true
        relay.peers = ["a", "g"]
        precondition(deliver(from: alice, to: &relay, frame: chatFrame(from: idAlice, body: "rejoin")))
        log.append("reconnect")

        relay.peers = ["a", "g"]
        let idGateway = Data(repeating: 0x0C, count: 8)
        precondition(deliver(from: gateway, to: &relay, frame: chatFrame(from: idGateway, body: "after-reset")))
        log.append("reset")
        return log
    }
}
