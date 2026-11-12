import CoreBluetooth
import Foundation

/// CoreBluetooth-only radio. Restore IDs and UUID filter are public
/// so unit tests can check policy without spinning a manager.
public enum NHBLELinkPolicy {
    public static let maxConnections = 6
    public static let centralRestoreId = NighthawkMeshPolicy.bleCentralRestoreId
    public static let peripheralRestoreId = NighthawkMeshPolicy.blePeripheralRestoreId

    public static var serviceUUID: CBUUID {
        CBUUID(string: NighthawkMeshPolicy.serviceUUIDString)
    }

    public static var characteristicUUID: CBUUID {
        CBUUID(string: NighthawkMeshPolicy.characteristicUUIDString)
    }

    public static func scanServices() -> [CBUUID] { [serviceUUID] }

    public static func shouldConnect(advertised: [CBUUID]) -> Bool {
        advertised.contains(serviceUUID) &&
            !advertised.contains(where: { NighthawkMeshPolicy.isBitchatServiceUUID($0.uuidString) })
    }
}

public protocol NHBLELinkSink: AnyObject {
    func meshLinkDidReceive(_ frame: Data)
    func meshLinkNeedsFlush()
    func meshLinkRadioStateDidChange(_ centralRawValue: Int)
}

public extension NHBLELinkSink {
    func meshLinkNeedsFlush() {}
    func meshLinkRadioStateDidChange(_ centralRawValue: Int) {}
}

/// Dual-role GATT. Never call UniFFI synchronously on `bleQueue`.
public final class NHBLELinkLayer: NSObject, @unchecked Sendable {
    public static let shared = NHBLELinkLayer()

    public weak var sink: NHBLELinkSink?
    public private(set) var isRunning = false
    public private(set) var peerCount = 0

    private let bleQueue = DispatchQueue(label: "com.nighthawkapps.mesh.ble")
    private var central: CBCentralManager?
    private var peripheral: CBPeripheralManager?
    private var localCharacteristic: CBMutableCharacteristic?
    private var centrals: [CBCentral] = []
    private var peripherals: [UUID: CBPeripheral] = [:]
    private var assemblers: [UUID: AttFrameAssembler] = [:]
    private var writeCap = MeshAttPolicy.writePayloadCap(mtu: MeshAttPolicy.defaultMtu)
    private var attToMesh: [UUID: Data] = [:]
    private var meshToAtt: [String: UUID] = [:]
    private var keepAlive = true
    private var lastReconnect: [UUID: Date] = [:]
    private var hasCharacteristic: Set<UUID> = []
    private var linkMeta: [UUID: NHBLERedundantLinkPolicy.Link] = [:]
    private var mostRecentBind: [String: String] = [:]
    private var lastTraffic = Date.distantPast
    private var lastConnectAttempt = Date.distantPast
    private var appIsActive = true
    private var dutyTimer: DispatchSourceTimer?

    private override init() {
        super.init()
    }

    public func start() {
        bleQueue.async { [weak self] in
            guard let self, !self.isRunning else { return }
            self.isRunning = true
            let centralOpts: [String: Any] = [
                CBCentralManagerOptionRestoreIdentifierKey: NHBLELinkPolicy.centralRestoreId,
                CBCentralManagerOptionShowPowerAlertKey: true
            ]
            let periOpts: [String: Any] = [
                CBPeripheralManagerOptionRestoreIdentifierKey: NHBLELinkPolicy.peripheralRestoreId,
                CBPeripheralManagerOptionShowPowerAlertKey: true
            ]
            self.central = CBCentralManager(delegate: self, queue: self.bleQueue, options: centralOpts)
            self.peripheral = CBPeripheralManager(delegate: self, queue: self.bleQueue, options: periOpts)
        }
    }

    public func stop() {
        bleQueue.async { [weak self] in
            guard let self else { return }
            self.isRunning = false
            self.central?.stopScan()
            self.peripheral?.stopAdvertising()
            self.peripherals.values.forEach { self.central?.cancelPeripheralConnection($0) }
            self.peripherals.removeAll()
            self.centrals.removeAll()
            self.assemblers.removeAll()
            self.attToMesh.removeAll()
            self.meshToAtt.removeAll()
            self.hasCharacteristic.removeAll()
            self.linkMeta.removeAll()
            self.mostRecentBind.removeAll()
            self.dutyTimer?.cancel()
            self.dutyTimer = nil
            self.lastReconnect.removeAll()
            self.peerCount = 0
            self.central = nil
            self.peripheral = nil
            self.localCharacteristic = nil
        }
    }

    public func send(_ frame: Data) {
        bleQueue.async { [weak self] in
            self?.sendLocked(frame)
        }
    }

    public func setSceneForeground(_ foreground: Bool, alwaysOn: Bool = true) {
        bleQueue.async { [weak self] in
            guard let self, self.isRunning else { return }
            self.keepAlive = foreground || alwaysOn
            self.appIsActive = foreground
            if self.keepAlive {
                self.refreshScanDuty()
                self.startAdvertisingLocked()
            } else {
                self.dutyTimer?.cancel()
                self.dutyTimer = nil
                self.central?.stopScan()
                self.peripheral?.stopAdvertising()
            }
        }
    }

    public func resumeAfterForeground() {
        bleQueue.async { [weak self] in
            guard let self, self.isRunning else { return }
            self.keepAlive = true
            self.appIsActive = true
            self.refreshScanDuty()
            self.startAdvertisingLocked()
            self.rediscoverRestoredLocked()
        }
    }

    private func startScanLocked() {
        guard let central, central.state == .poweredOn, isRunning else { return }
        central.scanForPeripherals(
            withServices: NHBLELinkPolicy.scanServices(),
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    private func startAdvertisingLocked() {
        guard let peripheral, peripheral.state == .poweredOn, isRunning else { return }
        if peripheral.isAdvertising { return }
        if localCharacteristic == nil {
            let service = CBMutableService(type: NHBLELinkPolicy.serviceUUID, primary: true)
            let ch = CBMutableCharacteristic(
                type: NHBLELinkPolicy.characteristicUUID,
                properties: [.write, .writeWithoutResponse, .notify],
                value: nil,
                permissions: [.writeable]
            )
            service.characteristics = [ch]
            localCharacteristic = ch
            peripheral.removeAllServices()
            peripheral.add(service)
        }
        var adv: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [NHBLELinkPolicy.serviceUUID]
        ]
        if let pid = MeshEngineBridge.peerId(), pid.count == 8 {
            adv[CBAdvertisementDataServiceDataKey] = [NHBLELinkPolicy.serviceUUID: pid]
        }
        peripheral.startAdvertising(adv)
    }

    private func rediscoverRestoredLocked() {
        guard let central, central.state == .poweredOn, isRunning else { return }
        for peri in peripherals.values {
            peri.delegate = self
            if peri.state == .connected,
               NighthawkMeshPolicy.shouldRediscoverRestoredLink(
                peripheralConnected: true,
                hasCharacteristic: hasCharacteristic.contains(peri.identifier)
               ) {
                peri.discoverServices(NHBLELinkPolicy.scanServices())
            } else if peri.state == .disconnected,
                      NighthawkMeshPolicy.shouldReconnectRestoredLink(peripheralConnected: false) {
                reconnectIfAllowed(peri)
            }
        }
    }

    private func reconnectIfAllowed(_ peripheral: CBPeripheral) {
        guard isRunning, keepAlive, let central, central.state == .poweredOn else { return }
        let id = peripheral.identifier
        let now = Date()
        if let last = lastReconnect[id], now.timeIntervalSince(last) < 8 { return }
        lastReconnect[id] = now
        peripheral.delegate = self
        peripherals[id] = peripheral
        central.connect(peripheral, options: nil)
    }

    private func clearLocalLinks(notifyEngine: Bool) {
        if notifyEngine {
            for mesh in attToMesh.values {
                MeshEngineBridge.neighborDown(mesh)
            }
        }
        peripherals.removeAll()
        centrals.removeAll()
        assemblers.removeAll()
        attToMesh.removeAll()
        meshToAtt.removeAll()
        hasCharacteristic.removeAll()
        linkMeta.removeAll()
        mostRecentBind.removeAll()
        peerCount = 0
    }

    private func ingest(_ id: UUID, chunk: Data) {
        let asm = assemblers[id] ?? AttFrameAssembler()
        assemblers[id] = asm
        lastTraffic = Date()
        if dutyTimer != nil {
            refreshScanDuty()
        }
        let frames = asm.ingest(chunk)
        if !frames.isEmpty {
            DispatchQueue.global(qos: .utility).async { [weak self] in
                for frame in frames {
                    if let pkt = MeshWireCodec.decode(frame), pkt.sender.count == 8 {
                        self?.bleQueue.async {
                            self?.rememberMesh(att: id, mesh: pkt.sender)
                        }
                    }
                    self?.sink?.meshLinkDidReceive(frame)
                }
            }
        }
    }

    private func rememberMesh(att: UUID, mesh: Data) {
        guard mesh.count == 8 else { return }
        let hex = meshHex(mesh)
        attToMesh[att] = mesh
        meshToAtt[hex] = att
        mostRecentBind[hex] = att.uuidString
        var link = linkMeta[att] ?? NHBLERedundantLinkPolicy.Link(
            uuid: att.uuidString,
            peerID: hex,
            isConnected: peripherals[att]?.state == .connected,
            hasCharacteristic: hasCharacteristic.contains(att)
        )
        link.peerID = hex
        linkMeta[att] = link
        retireStaleRadios(peerHex: hex, ingress: att.uuidString)
    }

    private func retireStaleRadios(peerHex: String, ingress: String?) {
        let links = Array(linkMeta.values)
        guard let kept = NHBLERedundantLinkPolicy.keptUUID(
            ingressUUID: ingress,
            mostRecentlyBoundUUID: mostRecentBind[peerHex],
            links: links,
            peerID: peerHex
        ) else { return }
        for raw in NHBLERedundantLinkPolicy.uuidsToRetire(links: links, peerID: peerHex, keeping: kept) {
            guard let uuid = UUID(uuidString: raw), let peri = peripherals[uuid] else { continue }
            central?.cancelPeripheralConnection(peri)
        }
    }

    private func refreshScanDuty() {
        guard isRunning, keepAlive, let central, central.state == .poweredOn else { return }
        let connected = linkMeta.values.filter(\.isConnected).count
        let recent = Date().timeIntervalSince(lastTraffic) < 15
        let plan = NHBLEScanDutyPolicy.plan(
            dutyEnabled: true,
            appIsActive: appIsActive,
            connectedCount: connected,
            hasRecentTraffic: recent
        )
        switch plan {
        case .continuous:
            dutyTimer?.cancel()
            dutyTimer = nil
            startScanLocked()
        case let .dutyCycle(onDuration, offDuration):
            scheduleDuty(onDuration: onDuration, offDuration: offDuration)
        }
    }

    private func scheduleDuty(onDuration: TimeInterval, offDuration: TimeInterval) {
        dutyTimer?.cancel()
        startScanLocked()
        let timer = DispatchSource.makeTimerSource(queue: bleQueue)
        timer.schedule(deadline: .now() + onDuration, repeating: onDuration + offDuration)
        timer.setEventHandler { [weak self] in
            guard let self, self.isRunning, self.keepAlive else { return }
            self.central?.stopScan()
            self.bleQueue.asyncAfter(deadline: .now() + offDuration) { [weak self] in
                guard let self, self.isRunning, self.keepAlive, self.dutyTimer != nil else { return }
                self.startScanLocked()
            }
        }
        dutyTimer = timer
        timer.resume()
    }

    private func meshHex(_ id: Data) -> String {
        id.map { String(format: "%02x", $0) }.joined()
    }

    private func forgetAtt(_ att: UUID) {
        if let mesh = attToMesh.removeValue(forKey: att) {
            meshToAtt.removeValue(forKey: meshHex(mesh))
            MeshEngineBridge.neighborDown(mesh)
        }
    }

    private func sendLocked(_ frame: Data) {
        guard let pkt = MeshWireCodec.decode(frame),
              let dest = pkt.recipient,
              dest.count == 8,
              let uuid = meshToAtt[meshHex(dest)]
        else { return }
        let chunks = AttFrameSplitter.split(frame: frame, attPayload: writeCap)
        if let ch = localCharacteristic,
           let central = centrals.first(where: { $0.identifier == uuid }) {
            for chunk in chunks {
                peripheral?.updateValue(chunk, for: ch, onSubscribedCentrals: [central])
            }
        }
        if let peri = peripherals[uuid],
           let svc = peri.services?.first(where: { $0.uuid == NHBLELinkPolicy.serviceUUID }),
           let ch = svc.characteristics?.first(where: { $0.uuid == NHBLELinkPolicy.characteristicUUID }) {
            for chunk in chunks {
                let type: CBCharacteristicWriteType =
                    peri.canSendWriteWithoutResponse ? .withoutResponse : .withResponse
                peri.writeValue(chunk, for: ch, type: type)
            }
        }
    }

}

extension NHBLELinkLayer: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        sink?.meshLinkRadioStateDidChange(central.state.rawValue)
        switch central.state {
        case .poweredOn:
            if isRunning {
                refreshScanDuty()
                rediscoverRestoredLocked()
            }
        case .poweredOff, .unauthorized, .unsupported:
            // CoreBluetooth already left poweredOn — do not issue stop/cancel.
            clearLocalLinks(notifyEngine: central.state == .poweredOff)
        default:
            break
        }
    }

    public func centralManager(
        _ central: CBCentralManager,
        willRestoreState dict: [String: Any]
    ) {
        let restored = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] ?? []
        for peri in restored {
            peri.delegate = self
            peripherals[peri.identifier] = peri
        }
        peerCount = peripherals.count + centrals.count
        if central.state == .poweredOn, isRunning {
            refreshScanDuty()
            rediscoverRestoredLocked()
        }
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let uuids = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]) ?? []
        guard NHBLELinkPolicy.shouldConnect(advertised: uuids) else { return }
        guard peripherals[peripheral.identifier] == nil else { return }
        let connectedCount = linkMeta.values.filter(\.isConnected).count
        guard NHBLEScanDutyPolicy.shouldConnect(rssi: RSSI.intValue, connectedCount: connectedCount) else { return }
        guard peripherals.count < NHBLELinkPolicy.maxConnections else { return }
        let now = Date()
        guard now.timeIntervalSince(lastConnectAttempt) >= NHBLEScanDutyPolicy.connectRateLimit else { return }
        lastConnectAttempt = now
        if let svcData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data],
           let hint = svcData[NHBLELinkPolicy.serviceUUID], hint.count == 8 {
            rememberMesh(att: peripheral.identifier, mesh: hint)
        }
        peripheral.delegate = self
        peripherals[peripheral.identifier] = peripheral
        linkMeta[peripheral.identifier] = NHBLERedundantLinkPolicy.Link(
            uuid: peripheral.identifier.uuidString,
            peerID: attToMesh[peripheral.identifier].map(meshHex),
            isConnected: false,
            hasCharacteristic: false
        )
        peerCount = peripherals.count + centrals.count
        central.connect(peripheral, options: nil)
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        var link = linkMeta[peripheral.identifier] ?? NHBLERedundantLinkPolicy.Link(
            uuid: peripheral.identifier.uuidString,
            peerID: attToMesh[peripheral.identifier].map(meshHex),
            isConnected: true,
            hasCharacteristic: hasCharacteristic.contains(peripheral.identifier),
            lastConnectedAt: Date()
        )
        link.isConnected = true
        link.lastConnectedAt = Date()
        linkMeta[peripheral.identifier] = link
        if let mesh = attToMesh[peripheral.identifier] {
            retireStaleRadios(peerHex: meshHex(mesh), ingress: peripheral.identifier.uuidString)
        }
        refreshScanDuty()
        peripheral.discoverServices(NHBLELinkPolicy.scanServices())
    }

    public func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        let _ = error
        peripherals.removeValue(forKey: peripheral.identifier)
        linkMeta.removeValue(forKey: peripheral.identifier)
        forgetAtt(peripheral.identifier)
        peerCount = peripherals.count + centrals.count
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        let _ = error
        assemblers.removeValue(forKey: peripheral.identifier)
        hasCharacteristic.remove(peripheral.identifier)
        linkMeta.removeValue(forKey: peripheral.identifier)
        forgetAtt(peripheral.identifier)
        if isRunning, keepAlive {
            reconnectIfAllowed(peripheral)
        } else {
            peripherals.removeValue(forKey: peripheral.identifier)
        }
        peerCount = peripherals.count + centrals.count
        refreshScanDuty()
    }
}

extension NHBLELinkLayer: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        peripheral.services?.forEach { peripheral.discoverCharacteristics(NHBLELinkPolicy.scanServices().isEmpty ? nil : [NHBLELinkPolicy.characteristicUUID], for: $0) }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        service.characteristics?
            .filter { $0.uuid == NHBLELinkPolicy.characteristicUUID }
            .forEach { peripheral.setNotifyValue(true, for: $0) }
        let mtu = peripheral.maximumWriteValueLength(for: .withoutResponse)
        if mtu > 0 { writeCap = MeshAttPolicy.writePayloadCap(mtu: mtu + MeshAttPolicy.attOverhead) }
        hasCharacteristic.insert(peripheral.identifier)
        if var link = linkMeta[peripheral.identifier] {
            link.hasCharacteristic = true
            linkMeta[peripheral.identifier] = link
        }
        if let mesh = attToMesh[peripheral.identifier] {
            retireStaleRadios(peerHex: meshHex(mesh), ingress: peripheral.identifier.uuidString)
            MeshEngineBridge.neighborUp(mesh)
            sink?.meshLinkNeedsFlush()
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard let data = characteristic.value else { return }
        ingest(peripheral.identifier, chunk: data)
    }
}

extension NHBLELinkLayer: CBPeripheralManagerDelegate {
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        sink?.meshLinkRadioStateDidChange(peripheral.state.rawValue)
        switch peripheral.state {
        case .poweredOn:
            if isRunning { startAdvertisingLocked() }
        case .poweredOff, .unauthorized, .unsupported:
            localCharacteristic = nil
            centrals.removeAll()
            peerCount = peripherals.count
        default:
            break
        }
    }

    public func peripheralManager(
        _ peripheral: CBPeripheralManager,
        willRestoreState dict: [String: Any]
    ) {
        let restoredServices = (dict[CBPeripheralManagerRestoredStateServicesKey] as? [CBMutableService]) ?? []
        if localCharacteristic == nil {
            if let service = restoredServices.first(where: { $0.uuid == NHBLELinkPolicy.serviceUUID }),
               let restored = service.characteristics?.first(where: { $0.uuid == NHBLELinkPolicy.characteristicUUID }) as? CBMutableCharacteristic {
                localCharacteristic = restored
            }
        }
        if peripheral.state == .poweredOn, isRunning, !peripheral.isAdvertising {
            startAdvertisingLocked()
        }
    }

    public func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didReceiveWrite requests: [CBATTRequest]
    ) {
        for req in requests {
            if let data = req.value {
                ingest(req.central.identifier, chunk: data)
            }
            peripheral.respond(to: req, withResult: .success)
        }
    }

    public func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        if !centrals.contains(where: { $0.identifier == central.identifier }) {
            guard centrals.count < NHBLELinkPolicy.maxConnections else { return }
            centrals.append(central)
        }
        peerCount = peripherals.count + centrals.count
    }

    public func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        centrals.removeAll { $0.identifier == central.identifier }
        forgetAtt(central.identifier)
        peerCount = peripherals.count + centrals.count
    }

    public func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didReceiveRead request: CBATTRequest
    ) {
        peripheral.respond(to: request, withResult: .readNotPermitted)
    }
}
