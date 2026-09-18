import Foundation
import Network
import UIKit
import Utils

/// Scene-phase + radio bridge. CoreBluetooth lives in [NHBLELinkLayer].
public final class NighthawkMeshController: NSObject, NHBLELinkSink, @unchecked Sendable {
    public static let shared = NighthawkMeshController()

    public private(set) var meshOn = false
    public private(set) var gatewayOptIn = false
    public private(set) var alwaysOn = true
    public private(set) var sceneForeground = true
    public private(set) var lastPowerForeground = true
    public private(set) var acceptedFrameCount = 0
    public private(set) var backgroundDrainRequested = false
    public private(set) var lastGatewayId: Data?
    public private(set) var lastGatewayCaps: UInt8 = 0
    public private(set) var radioState: NighthawkMeshPolicy.RadioUserState = .pending
    public let dag = MeshDagBridge()

    private let defaults: UserDefaults
    private let meshKey = "is_nighthawk_mesh_enabled"
    private let gatewayKey = "is_nighthawk_mesh_gateway"
    private let alwaysOnKey = "is_nighthawk_mesh_always_on"
    private var backgroundTask = UIBackgroundTaskIdentifier.invalid
    private let pathMonitor = NWPathMonitor()
    private let pathQueue = DispatchQueue(label: "com.nighthawkapps.mesh.path")
    private var unmeteredWifi = false
    private var pathSatisfied = true
    private var dagTimer: Timer?
    private var unreachableObserver: NSObjectProtocol?
    private var becomeActiveObserver: NSObjectProtocol?

    private override init() {
        defaults = .standard
        super.init()
        meshOn = defaults.bool(forKey: meshKey)
        gatewayOptIn = defaults.object(forKey: gatewayKey) as? Bool ?? false
        alwaysOn = defaults.object(forKey: alwaysOnKey) as? Bool ?? true
        UIDevice.current.isBatteryMonitoringEnabled = true
        pathMonitor.pathUpdateHandler = { [weak self] path in
            let wifi = path.usesInterfaceType(.wifi)
            let unmetered = path.status == .satisfied && wifi && !path.isExpensive && !path.isConstrained
            self?.unmeteredWifi = unmetered
            let satisfied = path.status == .satisfied
            if satisfied {
                self?.pathSatisfied = true
            } else if self?.pathSatisfied == true {
                self?.pathSatisfied = false
                self?.onInternetUnreachable(fromBgRefresh: false)
            }
            self?.pushPower()
        }
        pathMonitor.start(queue: pathQueue)
        unreachableObserver = NotificationCenter.default.addObserver(
            forName: .nighthawkLightwalletdUnreachable,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.onInternetUnreachable(fromBgRefresh: false)
        }
        becomeActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScene(.active)
            self?.restoreIfNeeded()
            NHBLELinkLayer.shared.resumeAfterForeground()
        }
    }

    public var peerCount: Int { NHBLELinkLayer.shared.peerCount }

    public func setMeshOn(_ on: Bool) {
        meshOn = on
        defaults.set(on, forKey: meshKey)
        if on {
            MeshEngineBridge.start()
            MeshEngineBridge.setGatewayEligible(false)
            NHBLELinkLayer.shared.sink = self
            NHBLELinkLayer.shared.start()
            NHBLELinkLayer.shared.setSceneForeground(sceneForeground, alwaysOn: alwaysOn)
            pushPower()
            restartDagTimer()
        } else {
            stopDagTimer()
            NHBLELinkLayer.shared.stop()
            MeshEngineBridge.stop()
            NHBulkLink.shared.stop()
            endBackgroundDrain()
            radioState = .pending
        }
    }

    public func setAlwaysOn(_ on: Bool) {
        alwaysOn = on
        defaults.set(on, forKey: alwaysOnKey)
        if meshOn {
            NHBLELinkLayer.shared.setSceneForeground(sceneForeground, alwaysOn: alwaysOn)
        }
    }

    public func setGatewayOptIn(_ on: Bool) {
        gatewayOptIn = false
        defaults.set(false, forKey: gatewayKey)
        MeshEngineBridge.setGatewayEligible(false)
        let _ = on
        pushPower()
    }

    public func restoreIfNeeded() {
        if meshOn {
            MeshEngineBridge.start()
            MeshEngineBridge.setGatewayEligible(false)
            NHBLELinkLayer.shared.sink = self
            NHBLELinkLayer.shared.start()
            NHBLELinkLayer.shared.setSceneForeground(sceneForeground, alwaysOn: alwaysOn)
            NHBLELinkLayer.shared.resumeAfterForeground()
            pushPower()
            restartDagTimer()
        }
    }

    public func handleScene(_ phase: MeshScenePhase) {
        switch phase {
        case .active:
            sceneForeground = true
            lastPowerForeground = true
            backgroundDrainRequested = false
            endBackgroundDrain()
            if meshOn {
                restoreIfNeeded()
                NHBLELinkLayer.shared.resumeAfterForeground()
            }
        case .inactive:
            sceneForeground = false
            lastPowerForeground = false
        case .background:
            sceneForeground = false
            lastPowerForeground = false
            backgroundDrainRequested = true
            beginBackgroundDrain()
        }
        if meshOn {
            NHBLELinkLayer.shared.setSceneForeground(sceneForeground, alwaysOn: alwaysOn)
            pushPower()
            restartDagTimer()
        }
        if phase == .background {
            _ = NighthawkMeshPolicy.mayStartUnifOmrBulk(
                sceneForeground: false,
                gatewayReady: false,
                fromBgRefresh: true
            )
        }
    }

    public var gcsInterval: TimeInterval {
        NighthawkMeshPolicy.gcsIntervalSeconds(sceneForeground: sceneForeground)
    }

    public func meshLinkDidReceive(_ frame: Data) {
        guard let pkt = MeshWireCodec.decode(frame) else { return }
        switch dag.consider(pkt) {
        case .rejectedOversized, .rejectedForbiddenLwd:
            return
        case .admitted, .ignored:
            break
        }
        switch pkt.type {
        case MeshWireCodec.noiseHs, MeshWireCodec.noiseEnc, MeshWireCodec.fragment,
             MeshWireCodec.ping, MeshWireCodec.pong:
            break
        default:
            return
        }
        acceptedFrameCount += 1
        MeshEngineBridge.ingest(frame)
        MeshEngineBridge.drainEvents()
        MeshEngineBridge.flushOutbound { NHBLELinkLayer.shared.send($0) }
    }

    public func meshLinkNeedsFlush() {
        MeshEngineBridge.flushOutbound { NHBLELinkLayer.shared.send($0) }
    }

    public func meshLinkRadioStateDidChange(_ centralRawValue: Int) {
        let next = NighthawkMeshPolicy.radioUserState(centralRawValue: centralRawValue)
        DispatchQueue.main.async { [weak self] in
            self?.radioState = next
        }
    }

    public func backgroundRefreshTick() {
        guard meshOn else { return }
        MeshEngineBridge.requestDagSync()
        MeshEngineBridge.flushOutbound { NHBLELinkLayer.shared.send($0) }
    }

    public var radioBanner: String? {
        switch radioState {
        case .ready, .pending:
            return nil
        case .poweredOff:
            return "Turn Bluetooth on so nearby Nighthawk chat can start."
        case .unauthorized:
            return "Bluetooth permission is needed for nearby chat. Enable it in Settings."
        case .unsupported:
            return "This device does not support Bluetooth mesh."
        }
    }

    public func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
    }

    public func onInternetUnreachable(fromBgRefresh: Bool) {
        let _ = fromBgRefresh
    }

    public func noteGatewayAnnounce(id: Data, caps: UInt8) {
        guard id.count == 8 else { return }
        lastGatewayId = id
        lastGatewayCaps = caps
    }

    public func clearGatewayHint() {
        lastGatewayId = nil
        lastGatewayCaps = 0
    }

    private func restartDagTimer() {
        stopDagTimer()
        guard meshOn else { return }
        let interval = gcsInterval
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            guard let self, self.meshOn else { return }
            MeshEngineBridge.requestDagSync()
            MeshEngineBridge.flushOutbound { NHBLELinkLayer.shared.send($0) }
        }
        RunLoop.main.add(timer, forMode: .common)
        dagTimer = timer
        MeshEngineBridge.requestDagSync()
        MeshEngineBridge.flushOutbound { NHBLELinkLayer.shared.send($0) }
    }

    private func stopDagTimer() {
        dagTimer?.invalidate()
        dagTimer = nil
    }

    private func pushPower() {
        let charging =
            UIDevice.current.batteryState == .charging ||
            UIDevice.current.batteryState == .full
        MeshEngineBridge.setPower(
            foreground: sceneForeground,
            charging: charging,
            unmetered: unmeteredWifi
        )
    }

    private func beginBackgroundDrain() {
        endBackgroundDrain()
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "nighthawk.mesh.drain") { [weak self] in
            self?.endBackgroundDrain()
        }
        // Keep already-connected GATT links. Never start UnifOMR here.
        _ = NighthawkMeshPolicy.mayStartUnifOmrBulk(
            sceneForeground: false,
            gatewayReady: false,
            fromBgRefresh: true
        )
    }

    private func endBackgroundDrain() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
}

public enum MeshScenePhase: Equatable {
    case active
    case inactive
    case background
}
