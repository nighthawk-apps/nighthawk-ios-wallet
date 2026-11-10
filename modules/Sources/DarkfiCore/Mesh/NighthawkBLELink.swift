import CoreBluetooth
import Foundation

/// The only CoreBluetooth type in the mesh stack. Dual central and
/// peripheral, confined to `bleQueue`. Modeled on BitChat's
/// BLE-ARCHITECTURE-V3 link layer: this type does not decode Nighthawk
/// packets. It reports link up, link down, and raw ATT bytes.
final class NighthawkBLELink: NSObject {
    let queue = DispatchQueue(label: "nh.mesh.ble")

    var onReady: ((String, Data?) -> Void)?
    var onBytes: ((String, Data) -> Void)?
    var onDown: ((String) -> Void)?

    private var central: CBCentralManager?
    private var peripheral: CBPeripheralManager?
    private var meshCharacteristic: CBMutableCharacteristic?
    private var started = false
    private var foreground = true
    private var scanning = false
    private var serviceAdded = false

    private var peripherals: [UUID: CBPeripheral] = [:]
    private var characteristics: [UUID: CBCharacteristic] = [:]
    private var advertisedIDs: [UUID: Data] = [:]
    private var subscribed: [UUID: CBCentral] = [:]
    private var pending: [String: [Data]] = [:]
    private var admitted: [String] = []
    private var dutyTimer: DispatchSourceTimer?
    private var dutyGeneration = 0

    private let service = CBUUID(string: NighthawkMeshFraming.serviceUUID)
    private let characteristicUUID = CBUUID(string: NighthawkMeshFraming.characteristicUUID)

    func start(foreground: Bool) {
        queue.async {
            self.foreground = foreground
            guard !self.started else {
                self.applyDuty()
                return
            }
            self.started = true
            self.central = CBCentralManager(
                delegate: self,
                queue: self.queue,
                options: [
                    CBCentralManagerOptionRestoreIdentifierKey: "nh.mesh.central",
                    CBCentralManagerOptionShowPowerAlertKey: true
                ]
            )
            self.peripheral = CBPeripheralManager(
                delegate: self,
                queue: self.queue,
                options: [CBPeripheralManagerOptionRestoreIdentifierKey: "nh.mesh.peripheral"]
            )
        }
    }

    func stop() {
        queue.async {
            self.started = false
            self.dutyTimer?.cancel()
            self.dutyTimer = nil
            self.central?.stopScan()
            self.scanning = false
            self.peripheral?.stopAdvertising()
            for peripheral in self.peripherals.values {
                self.central?.cancelPeripheralConnection(peripheral)
            }
            self.peripherals.removeAll()
            self.characteristics.removeAll()
            self.advertisedIDs.removeAll()
            self.subscribed.removeAll()
            self.pending.removeAll()
            self.admitted.removeAll()
            self.central = nil
            self.peripheral = nil
            self.meshCharacteristic = nil
            self.serviceAdded = false
        }
    }

    func setForeground(_ foreground: Bool) {
        queue.async {
            self.foreground = foreground
            if self.started { self.applyDuty() }
        }
    }

    /// Drop a Bluetooth address that a newer connection to the same identity replaced.
    func retire(linkID: String) {
        queue.async { self.drop(linkID: linkID) }
    }

    func write(linkID: String, frame: Data) {
        queue.async {
            let cap = self.payloadCap(linkID)
            let chunks = NighthawkMeshFraming.chunks(frame: frame, attPayload: cap)
            self.pending[linkID, default: []].append(contentsOf: chunks)
            self.drain(linkID)
        }
    }

    private func payloadCap(_ linkID: String) -> Int {
        if linkID.hasPrefix("p:"),
           let uuid = UUID(uuidString: String(linkID.dropFirst(2))),
           let peripheral = peripherals[uuid] {
            return peripheral.maximumWriteValueLength(for: .withoutResponse)
        }
        return NighthawkMeshFraming.defaultFragmentBytes
    }

    private func linkID(peripheral: CBPeripheral) -> String {
        "p:" + peripheral.identifier.uuidString
    }

    private func linkID(central: CBCentral) -> String {
        "c:" + central.identifier.uuidString
    }

    private func admit(_ id: String) -> String? {
        if admitted.contains(id) { return nil }
        var evicted: String?
        if admitted.count >= NighthawkMeshFraming.maxConnections {
            evicted = admitted.removeFirst()
        }
        admitted.append(id)
        return evicted
    }

    private func forget(_ id: String) {
        admitted.removeAll { $0 == id }
        pending.removeValue(forKey: id)
    }

    private func applyDuty() {
        guard started, central?.state == .poweredOn else { return }
        dutyTimer?.cancel()
        dutyTimer = nil
        dutyGeneration += 1
        let generation = dutyGeneration
        let peers = peripherals.count + subscribed.count
        let on: TimeInterval
        let off: TimeInterval
        if foreground {
            on = 8
            off = 2
        } else if peers > 0 {
            on = 1
            off = 29
        } else {
            on = 1
            off = 59
        }
        startScan()
        if peripheral?.state == .poweredOn {
            startAdvertising()
        }
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + on, repeating: .never)
        timer.setEventHandler { [weak self] in
            guard let self, self.started, self.dutyGeneration == generation else { return }
            self.central?.stopScan()
            self.scanning = false
            self.queue.asyncAfter(deadline: .now() + off) {
                guard self.dutyGeneration == generation else { return }
                self.applyDuty()
            }
        }
        timer.resume()
        dutyTimer = timer
    }

    private func startScan() {
        guard started, let central, central.state == .poweredOn, !central.isScanning else { return }
        central.scanForPeripherals(
            withServices: [service],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: foreground]
        )
        scanning = true
    }

    private func startAdvertising() {
        guard started, let peripheral, peripheral.state == .poweredOn, !peripheral.isAdvertising else { return }
        peripheral.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [service]])
    }

    private func ensureService() {
        guard let peripheral, peripheral.state == .poweredOn, !serviceAdded else { return }
        let characteristic = CBMutableCharacteristic(
            type: characteristicUUID,
            properties: [.write, .writeWithoutResponse, .notify],
            value: nil,
            permissions: [.writeable]
        )
        let gatt = CBMutableService(type: service, primary: true)
        gatt.characteristics = [characteristic]
        meshCharacteristic = characteristic
        peripheral.add(gatt)
        serviceAdded = true
    }

    private func connect(_ peripheral: CBPeripheral, advertised: Data?) {
        let id = linkID(peripheral: peripheral)
        if peripherals[peripheral.identifier] != nil || admitted.contains(id) { return }
        if let evicted = admit(id) {
            drop(linkID: evicted)
        }
        if let advertised, advertised.count == NighthawkMeshFraming.senderLength {
            advertisedIDs[peripheral.identifier] = advertised
        }
        peripheral.delegate = self
        peripherals[peripheral.identifier] = peripheral
        central?.connect(peripheral, options: nil)
    }

    private func drop(linkID: String) {
        forget(linkID)
        if linkID.hasPrefix("p:"), let uuid = UUID(uuidString: String(linkID.dropFirst(2))) {
            if let peripheral = peripherals.removeValue(forKey: uuid) {
                central?.cancelPeripheralConnection(peripheral)
            }
            characteristics.removeValue(forKey: uuid)
            advertisedIDs.removeValue(forKey: uuid)
        }
        if linkID.hasPrefix("c:"), let uuid = UUID(uuidString: String(linkID.dropFirst(2))) {
            subscribed.removeValue(forKey: uuid)
        }
        onDown?(linkID)
    }

    private func drain(_ linkID: String) {
        guard var queue = pending[linkID], !queue.isEmpty else { return }
        if linkID.hasPrefix("p:"),
           let uuid = UUID(uuidString: String(linkID.dropFirst(2))),
           let peripheral = peripherals[uuid],
           let characteristic = characteristics[uuid] {
            guard peripheral.canSendWriteWithoutResponse else { return }
            let chunk = queue.removeFirst()
            pending[linkID] = queue
            peripheral.writeValue(chunk, for: characteristic, type: .withoutResponse)
            return
        }
        if linkID.hasPrefix("c:"),
           let uuid = UUID(uuidString: String(linkID.dropFirst(2))),
           let central = subscribed[uuid],
           let characteristic = meshCharacteristic {
            let chunk = queue.removeFirst()
            let sent = peripheral?.updateValue(chunk, for: characteristic, onSubscribedCentrals: [central]) ?? false
            if sent {
                pending[linkID] = queue
            } else {
                queue.insert(chunk, at: 0)
                pending[linkID] = queue
            }
        }
    }
}

extension NighthawkBLELink: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            applyDuty()
        } else {
            central.stopScan()
            scanning = false
            dutyTimer?.cancel()
            dutyTimer = nil
            let ids = admitted
            for id in ids {
                drop(linkID: id)
            }
        }
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        let restored = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] ?? []
        for peripheral in restored {
            peripheral.delegate = self
            peripherals[peripheral.identifier] = peripheral
            _ = admit(linkID(peripheral: peripheral))
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi _: NSNumber
    ) {
        let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data]
        let meshID = serviceData?[service]
        connect(peripheral, advertised: meshID)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([service])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        drop(linkID: linkID(peripheral: peripheral))
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        drop(linkID: linkID(peripheral: peripheral))
    }
}

extension NighthawkBLELink: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let gatt = peripheral.services?.first(where: { $0.uuid == service }) else { return }
        peripheral.discoverCharacteristics([characteristicUUID], for: gatt)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil,
              let characteristic = service.characteristics?.first(where: { $0.uuid == characteristicUUID })
        else { return }
        characteristics[peripheral.identifier] = characteristic
        peripheral.setNotifyValue(true, for: characteristic)
        let id = linkID(peripheral: peripheral)
        onReady?(id, advertisedIDs[peripheral.identifier])
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let value = characteristic.value else { return }
        onBytes?(linkID(peripheral: peripheral), value)
    }

    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        drain(linkID(peripheral: peripheral))
    }
}

extension NighthawkBLELink: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            ensureService()
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String: Any]) {
        serviceAdded = true
        let services = dict[CBPeripheralManagerRestoredStateServicesKey] as? [CBMutableService] ?? []
        meshCharacteristic = services
            .flatMap { $0.characteristics ?? [] }
            .compactMap { $0 as? CBMutableCharacteristic }
            .first { $0.uuid == characteristicUUID }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if error == nil { startAdvertising() }
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        let id = linkID(central: central)
        if let evicted = admit(id) { drop(linkID: evicted) }
        subscribed[central.identifier] = central
        onReady?(id, nil)
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        drop(linkID: linkID(central: central))
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            guard request.characteristic.uuid == characteristicUUID else { continue }
            let id = linkID(central: request.central)
            if subscribed[request.central.identifier] == nil {
                if let evicted = admit(id) { drop(linkID: evicted) }
                subscribed[request.central.identifier] = request.central
                onReady?(id, nil)
            }
            if let value = request.value, !value.isEmpty {
                onBytes?(id, value)
            }
            peripheral.respond(to: request, withResult: .success)
        }
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        for central in subscribed.values {
            drain(linkID(central: central))
        }
    }
}
