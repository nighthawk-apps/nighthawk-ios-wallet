import Darwin
import Foundation

/// Optional C ABI to the Rust mesh engine. Uses `dlsym` so a simulator
/// xcframework without the new symbols still links.
enum MeshEngineBridge {
    typealias StartFn = @convention(c) () -> Int32
    typealias StopFn = @convention(c) () -> Int32
    typealias FlagFn = @convention(c) (Int32) -> Int32
    typealias PowerFn = @convention(c) (Int32, Int32, Int32) -> Int32
    typealias IngestFn = @convention(c) (UnsafePointer<UInt8>?, Int32) -> Int32
    typealias PopFn = @convention(c) (UnsafeMutablePointer<UInt8>?, Int32) -> Int32
    typealias PumpFn = @convention(c) () -> Int32
    typealias BulkTcpFn = @convention(c) (UnsafePointer<CChar>?, Int32) -> Int32
    typealias RecordFn = @convention(c) (UInt64) -> Int32
    typealias WipeFn = @convention(c) () -> Int32
    typealias SubmitCtrlFn = @convention(c) (
        UnsafePointer<UInt8>?,
        UnsafePointer<CChar>?,
        UnsafePointer<UInt8>?,
        Int32,
        UnsafeMutablePointer<UInt8>?
    ) -> Int32
    typealias SubmitJoinFn = @convention(c) (
        UnsafePointer<UInt8>?,
        UnsafeMutablePointer<UInt8>?
    ) -> Int32
    typealias PublishDagFn = @convention(c) (UnsafePointer<UInt8>?, Int32) -> Int32
    typealias NeighborFn = @convention(c) (UnsafePointer<UInt8>?) -> Int32

    static var available: Bool { startFn != nil }

    private static let startFn: StartFn? = symbol("nh_mesh_start")
    private static let stopFn: StopFn? = symbol("nh_mesh_stop")
    private static let gwFn: FlagFn? = symbol("nh_mesh_set_gateway_eligible")
    private static let powerFn: PowerFn? = symbol("nh_mesh_set_os_power_state")
    private static let ingestFn: IngestFn? = symbol("nh_mesh_ingest_link_bytes")
    private static let popFn: PopFn? = symbol("nh_mesh_pop_outbound")
    private static let pumpFn: PumpFn? = symbol("nh_mesh_pump_gateway")
    private static let eventsFn: PopFn? = symbol("nh_mesh_pop_events_json")
    private static let bulkTcpFn: BulkTcpFn? = symbol("nh_mesh_set_bulk_tcp")
    private static let recordFn: RecordFn? = symbol("nh_mesh_record_bulk_bytes")
    private static let wipeFn: WipeFn? = symbol("nh_mesh_wipe")
    private static let lastGwFn: PopFn? = symbol("nh_mesh_last_gateway_peer")
    private static let submitCtrlFn: SubmitCtrlFn? = symbol("nh_mesh_submit_lwd_ctrl")
    private static let submitJoinFn: SubmitJoinFn? = symbol("nh_mesh_submit_bulk_join")
    private static let publishDagFn: PublishDagFn? = symbol("nh_mesh_publish_dag")
    private static let requestDagFn: StartFn? = symbol("nh_mesh_request_dag_sync")
    private static let neighborUpFn: NeighborFn? = symbol("nh_mesh_neighbor_up")
    private static let neighborDownFn: NeighborFn? = symbol("nh_mesh_neighbor_down")
    private static let peerIdFn: PopFn? = symbol("nh_mesh_peer_id")

    static func start() {
        _ = startFn?()
    }

    static func stop() {
        _ = stopFn?()
    }

    static func setGatewayEligible(_ on: Bool) {
        _ = gwFn?(on ? 1 : 0)
    }

    static func setPower(foreground: Bool, charging: Bool, unmetered: Bool) {
        _ = powerFn?(foreground ? 1 : 0, charging ? 1 : 0, unmetered ? 1 : 0)
    }

    static func ingest(_ frame: Data) {
        frame.withUnsafeBytes { raw in
            guard let p = raw.bindMemory(to: UInt8.self).baseAddress else { return }
            _ = ingestFn?(p, Int32(frame.count))
        }
    }

    static func flushOutbound(_ send: (Data) -> Void) {
        guard let popFn else { return }
        var buf = [UInt8](repeating: 0, count: 64 * 1024)
        for _ in 0..<32 {
            let n = buf.withUnsafeMutableBufferPointer { popFn($0.baseAddress, Int32($0.count)) }
            if n <= 0 { return }
            send(Data(buf.prefix(Int(n))))
        }
    }

    static func pumpGateway() {
        _ = pumpFn?()
    }

    static func popEventsJson() -> String? {
        guard let eventsFn else { return nil }
        var buf = [UInt8](repeating: 0, count: 64 * 1024)
        let n = buf.withUnsafeMutableBufferPointer { eventsFn($0.baseAddress, Int32($0.count)) }
        if n <= 0 { return nil }
        return String(bytes: buf.prefix(Int(n)), encoding: .utf8)
    }

    static func setBulkTcp(host: String?, port: Int32) {
        guard let bulkTcpFn else { return }
        if let host {
            host.withCString { _ = bulkTcpFn($0, port) }
        } else {
            _ = bulkTcpFn(nil, 0)
        }
    }

    static func recordBulkBytes(_ n: UInt64) -> Bool {
        (recordFn?(n) ?? 0) == 1
    }

    static func wipe() {
        _ = wipeFn?()
        setBulkTcp(host: nil, port: 0)
    }

    static func lastGatewayPeer() -> Data? {
        guard let lastGwFn else { return nil }
        var buf = [UInt8](repeating: 0, count: 8)
        let n = buf.withUnsafeMutableBufferPointer { lastGwFn($0.baseAddress, Int32($0.count)) }
        guard n == 8 else { return nil }
        return Data(buf)
    }

    static func submitLwdCtrl(dest: Data, method: String, body: Data = Data()) -> Bool {
        guard dest.count == 8, let submitCtrlFn else { return false }
        var corr = [UInt8](repeating: 0, count: 16)
        return dest.withUnsafeBytes { destRaw in
            method.withCString { methodPtr in
                let destPtr = destRaw.bindMemory(to: UInt8.self).baseAddress
                return corr.withUnsafeMutableBufferPointer { corrBuf in
                    if body.isEmpty {
                        return submitCtrlFn(destPtr, methodPtr, nil, 0, corrBuf.baseAddress) == 0
                    }
                    return body.withUnsafeBytes { bodyRaw in
                        submitCtrlFn(
                            destPtr,
                            methodPtr,
                            bodyRaw.bindMemory(to: UInt8.self).baseAddress,
                            Int32(body.count),
                            corrBuf.baseAddress
                        ) == 0
                    }
                }
            }
        }
    }

    static func submitBulkJoin(dest: Data) -> Bool {
        guard dest.count == 8, let submitJoinFn else { return false }
        var corr = [UInt8](repeating: 0, count: 16)
        return dest.withUnsafeBytes { destRaw in
            return corr.withUnsafeMutableBufferPointer { corrBuf in
                submitJoinFn(
                    destRaw.bindMemory(to: UInt8.self).baseAddress,
                    corrBuf.baseAddress
                ) == 0
            }
        }
    }

    static func publishDag(_ body: Data) -> Bool {
        guard let publishDagFn else { return false }
        return body.withUnsafeBytes { raw in
            guard let p = raw.bindMemory(to: UInt8.self).baseAddress else { return false }
            return publishDagFn(p, Int32(body.count)) == 0
        }
    }

    static func requestDagSync() {
        _ = requestDagFn?()
    }

    static func neighborUp(_ dest: Data) {
        guard dest.count == 8, let neighborUpFn else { return }
        dest.withUnsafeBytes { raw in
            _ = neighborUpFn(raw.bindMemory(to: UInt8.self).baseAddress)
        }
    }

    static func neighborDown(_ dest: Data) {
        guard dest.count == 8, let neighborDownFn else { return }
        dest.withUnsafeBytes { raw in
            _ = neighborDownFn(raw.bindMemory(to: UInt8.self).baseAddress)
        }
    }

    static func peerId() -> Data? {
        guard let peerIdFn else { return nil }
        var buf = [UInt8](repeating: 0, count: 8)
        let n = buf.withUnsafeMutableBufferPointer { peerIdFn($0.baseAddress, Int32($0.count)) }
        guard n == 8 else { return nil }
        return Data(buf)
    }

    static var cacheEvicted = false
    static var neighborsReady: Bool { neighborUpFn != nil && neighborDownFn != nil }

    static func drainEvents() {
        guard let eventsFn else { return }
        var buf = [UInt8](repeating: 0, count: 16 * 1024)
        let n = buf.withUnsafeMutableBufferPointer { eventsFn($0.baseAddress, Int32($0.count)) }
        guard n > 0 else { return }
        let json = String(bytes: buf.prefix(Int(n)), encoding: .utf8) ?? ""
        if json.contains("\"cache_full\"") {
            cacheEvicted = true
        }
    }

    private static func symbol<T>(_ name: String) -> T? {
        // Darwin RTLD_DEFAULT is (void *)-2; the named constant is not
        // always imported into Swift.
        let rtldDefault = UnsafeMutableRawPointer(bitPattern: -2)
        guard let sym = dlsym(rtldDefault, name) else { return nil }
        return unsafeBitCast(sym, to: T.self)
    }
}
