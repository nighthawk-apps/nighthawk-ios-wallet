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
            if self.keepAlive {
                self.startScanLocked()
                self.startAdvertisingLocked()
            } else {
                self.central?.stopScan()
                self.peripheral?.stopAdvertising()
            }
        }
    }

    public func resumeAfterForeground() {
        bleQueue.async { [weak self] in
            guard let self, self.isRunning else { return }
            self.keepAlive = true
            self.startScanLocked()
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
        peerCount = 0
    }

    private func ingest(_ id: UUID, chunk: Data) {
        let asm = assemblers[id] ?? AttFrameAssembler()
        assemblers[id] = asm
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
        attToMesh[att] = mesh
        meshToAtt[meshHex(mesh)] = att
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
                startScanLocked()
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
            startScanLocked()
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
        guard peripherals.count < NHBLELinkPolicy.maxConnections else { return }
        if let svcData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data],
           let hint = svcData[NHBLELinkPolicy.serviceUUID], hint.count == 8 {
            rememberMesh(att: peripheral.identifier, mesh: hint)
        }
        peripheral.delegate = self
        peripherals[peripheral.identifier] = peripheral
        peerCount = peripherals.count + centrals.count
        central.connect(peripheral, options: nil)
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(NHBLELinkPolicy.scanServices())
    }

    public func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        let _ = error
        peripherals.removeValue(forKey: peripheral.identifier)
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
        forgetAtt(peripheral.identifier)
        if isRunning, keepAlive {
            reconnectIfAllowed(peripheral)
        } else {
            peripherals.removeValue(forKey: peripheral.identifier)
        }
        peerCount = peripherals.count + centrals.count
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
        if let mesh = attToMesh[peripheral.identifier] {
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
