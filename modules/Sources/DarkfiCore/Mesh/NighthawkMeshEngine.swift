import Foundation

/// C ABI from `mesh/abi.rs`. Kept out of the UniFFI header so a bindgen
/// refresh does not drop the symbols.
private enum NighthawkMeshABI {
    @_silgen_name("nh_mesh_start")
    static func start() -> Int32

    @_silgen_name("nh_mesh_stop")
    static func stop() -> Int32

    @_silgen_name("nh_mesh_set_gateway_eligible")
    static func setGatewayEligible(_ optIn: Int32) -> Int32

    @_silgen_name("nh_mesh_set_os_power_state")
    static func setPower(_ foreground: Int32, _ charging: Int32, _ unmetered: Int32) -> Int32

    @_silgen_name("nh_mesh_ingest_link_bytes")
    static func ingest(_ ptr: UnsafePointer<UInt8>?, _ len: Int32) -> Int32

    @_silgen_name("nh_mesh_pop_outbound")
    static func popOutbound(_ ptr: UnsafeMutablePointer<UInt8>?, _ cap: Int32) -> Int32

    @_silgen_name("nh_mesh_status")
    static func status(_ ptr: UnsafeMutablePointer<UInt8>?, _ cap: Int32) -> Int32

    @_silgen_name("nh_mesh_peer_id")
    static func peerID(_ ptr: UnsafeMutablePointer<UInt8>?, _ cap: Int32) -> Int32

    @_silgen_name("nh_mesh_request_dag_sync")
    static func requestDagSync() -> Int32

    @_silgen_name("nh_mesh_emit_presence")
    static func emitPresence() -> Int32

    @_silgen_name("nh_mesh_neighbor_up")
    static func neighborUp(_ dest: UnsafePointer<UInt8>?) -> Int32

    @_silgen_name("nh_mesh_neighbor_down")
    static func neighborDown(_ dest: UnsafePointer<UInt8>?) -> Int32
}

/// Engine-queue owner of protocol state. BitChat's rule: this queue never
/// sync-waits on the radio queue, and the radio never sync-waits on this one.
final class NighthawkMeshEngine {
    let queue = DispatchQueue(label: "nh.mesh.engine")
    var sendFrame: ((String, Data) -> Void)?
    /// Disconnect a Bluetooth address that this mesh identity has replaced.
    var retireLink: ((String) -> Void)?

    private let queueKey = DispatchSpecificKey<UInt8>()
    private var running = false
    private var localID = Data()
    private var linkToMesh: [String: Data] = [:]
    private var meshToLink: [String: String] = [:]
    private var liveLinks = Set<String>()
    private var assemblers: [String: NighthawkAttAssembler] = [:]
    private var held: [Data] = []
    private var pump: DispatchSourceTimer?
    private var ticks = 0
    private(set) var statusLine = "Mesh off"

    init() {
        queue.setSpecific(key: queueKey, value: 1)
    }

    func start(foreground: Bool, charging: Bool) {
        queue.async {
            guard !self.running else {
                self.applyPower(foreground: foreground, charging: charging)
                return
            }
            guard NighthawkMeshABI.start() == 0 else {
                self.publish("Mesh engine failed to start")
                return
            }
            _ = NighthawkMeshABI.setGatewayEligible(0)
            self.running = true
            self.localID = Self.readPeerID()
            self.applyPower(foreground: foreground, charging: charging)
            self.startPump()
            self.publish("Mesh on")
        }
    }

    func stop() {
        queue.async {
            self.pump?.cancel()
            self.pump = nil
            self.running = false
            self.linkToMesh.removeAll()
            self.meshToLink.removeAll()
            self.liveLinks.removeAll()
            self.assemblers.removeAll()
            self.held.removeAll()
            _ = NighthawkMeshABI.stop()
            self.publish("Mesh off")
        }
    }

    func setPower(foreground: Bool, charging: Bool) {
        queue.async { self.applyPower(foreground: foreground, charging: charging) }
    }

    func linkReady(_ linkID: String, advertisedMeshID: Data?) {
        queue.async {
            self.liveLinks.insert(linkID)
            if let advertisedMeshID, advertisedMeshID.count == NighthawkMeshFraming.senderLength {
                self.bind(linkID, meshID: advertisedMeshID, handshake: true)
            }
            if self.running {
                _ = NighthawkMeshABI.emitPresence()
                self.flush()
            }
        }
    }

    func linkDown(_ linkID: String) {
        queue.async {
            self.liveLinks.remove(linkID)
            self.assemblers.removeValue(forKey: linkID)
            if let meshID = self.linkToMesh.removeValue(forKey: linkID) {
                let hex = NighthawkMeshFraming.hex(meshID)
                // A newer radio for this identity already replaced this link.
                guard self.meshToLink[hex] == linkID else { return }
                self.meshToLink.removeValue(forKey: hex)
                meshID.withUnsafeBytes { raw in
                    _ = NighthawkMeshABI.neighborDown(raw.bindMemory(to: UInt8.self).baseAddress)
                }
            }
        }
    }

    func ingest(linkID: String, chunk: Data) {
        queue.async {
            guard self.running else { return }
            let assembler = self.assemblers[linkID] ?? NighthawkAttAssembler()
            self.assemblers[linkID] = assembler
            for frame in assembler.ingest(chunk) {
                guard let hint = NighthawkMeshFraming.hint(frame) else { continue }
                // Handshake only from an announce. A Noise handshake must be
                // ingested as the responder; neighbor_up here would open a
                // second session and drop the peer's reply.
                let announce = frame.count > 3 && frame[3] == 0xA1
                self.bind(linkID, meshID: hint.sender, handshake: announce)
                frame.withUnsafeBytes { raw in
                    guard let base = raw.bindMemory(to: UInt8.self).baseAddress else { return }
                    _ = NighthawkMeshABI.ingest(base, Int32(frame.count))
                }
            }
            self.flush()
        }
    }

    private func bind(_ linkID: String, meshID: Data, handshake: Bool) {
        guard meshID.count == NighthawkMeshFraming.senderLength else { return }
        if meshID == localID { return }
        let hex = NighthawkMeshFraming.hex(meshID)
        let previous = linkToMesh[linkID]
        let stale = meshToLink[hex]
        linkToMesh[linkID] = meshID
        meshToLink[hex] = linkID
        if let stale, stale != linkID {
            // Newest connection wins. The older address is no longer advertised.
            liveLinks.remove(stale)
            linkToMesh.removeValue(forKey: stale)
            assemblers.removeValue(forKey: stale)
            meshID.withUnsafeBytes { raw in
                _ = NighthawkMeshABI.neighborDown(raw.bindMemory(to: UInt8.self).baseAddress)
            }
            retireLink?(stale)
        }
        let learned = previous != meshID || stale != nil && stale != linkID
        if handshake && learned && running {
            meshID.withUnsafeBytes { raw in
                _ = NighthawkMeshABI.neighborUp(raw.bindMemory(to: UInt8.self).baseAddress)
            }
        }
    }

    private func applyPower(foreground: Bool, charging: Bool) {
        guard running else { return }
        _ = NighthawkMeshABI.setPower(foreground ? 1 : 0, charging ? 1 : 0, 0)
    }

    private func startPump() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 0.25, repeating: 0.25)
        timer.setEventHandler { [weak self] in
            self?.tick()
        }
        timer.resume()
        pump = timer
    }

    private func tick() {
        guard running else { return }
        ticks += 1
        if ticks % 60 == 0 {
            _ = NighthawkMeshABI.requestDagSync()
            refreshStatus()
        }
        flush()
    }

    private func flush() {
        while held.count < 64 {
            guard let frame = Self.popOutbound() else { break }
            held.append(frame)
        }
        var keep: [Data] = []
        for frame in held {
            guard let hint = NighthawkMeshFraming.hint(frame) else { continue }
            if let recipient = hint.recipient {
                let hex = NighthawkMeshFraming.hex(recipient)
                if let linkID = meshToLink[hex], liveLinks.contains(linkID) {
                    sendFrame?(linkID, frame)
                } else {
                    keep.append(frame)
                }
            } else if liveLinks.isEmpty {
                keep.append(frame)
            } else {
                for linkID in liveLinks {
                    sendFrame?(linkID, frame)
                }
            }
        }
        held = keep
    }

    private func refreshStatus() {
        var buf = [UInt8](repeating: 0, count: 512)
        let n = buf.withUnsafeMutableBytes { raw -> Int32 in
            NighthawkMeshABI.status(raw.bindMemory(to: UInt8.self).baseAddress, Int32(raw.count))
        }
        guard n > 0 else { return }
        let text = String(bytes: buf.prefix(Int(n)), encoding: .utf8) ?? "Mesh on"
        publish(text)
    }

    private func publish(_ text: String) {
        statusLine = text
        let line = text
        DispatchQueue.main.async {
            NighthawkMeshController.shared.noteStatus(line)
        }
    }

    private static func readPeerID() -> Data {
        var buf = [UInt8](repeating: 0, count: 8)
        let n = buf.withUnsafeMutableBytes { raw -> Int32 in
            NighthawkMeshABI.peerID(raw.bindMemory(to: UInt8.self).baseAddress, Int32(raw.count))
        }
        guard n == 8 else { return Data() }
        return Data(buf)
    }

    private static func popOutbound() -> Data? {
        var cap = 2048
        var buf = [UInt8](repeating: 0, count: cap)
        var n = buf.withUnsafeMutableBytes { raw -> Int32 in
            NighthawkMeshABI.popOutbound(raw.bindMemory(to: UInt8.self).baseAddress, Int32(cap))
        }
        if n == -3 {
            cap = 70_000
            buf = [UInt8](repeating: 0, count: cap)
            n = buf.withUnsafeMutableBytes { raw -> Int32 in
                NighthawkMeshABI.popOutbound(raw.bindMemory(to: UInt8.self).baseAddress, Int32(cap))
            }
        }
        guard n > 0 else { return nil }
        return Data(buf.prefix(Int(n)))
    }
}
