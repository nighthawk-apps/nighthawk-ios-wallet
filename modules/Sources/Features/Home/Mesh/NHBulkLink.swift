import Foundation
import MultipeerConnectivity
import NetworkExtension
import UIKit

/// iOS–iOS Multipeer bulk, or join an Android LocalOnlyHotspot.
/// Never started from `BGAppRefresh`. Does not bind the process to a network.
public final class NHBulkLink: NSObject, @unchecked Sendable {
    public static let shared = NHBulkLink()

    public private(set) var running = false
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var peerId: MCPeerID?
    private var startedAt: Date?
    private var bytes: UInt64 = 0

    private override init() {
        super.init()
    }

    public func startHostIfAllowed(fromBgRefresh: Bool) -> Bool {
        let charging =
            UIDevice.current.batteryState == .charging ||
            UIDevice.current.batteryState == .full
        let ready = NighthawkMeshPolicy.gatewayReady(
            meshOn: NighthawkMeshController.shared.meshOn,
            gatewayOptIn: NighthawkMeshController.shared.gatewayOptIn,
            charging: charging,
            unmetered: true
        )
        guard NHBulkPolicy.mayStart(
            sceneForeground: NighthawkMeshController.shared.sceneForeground,
            gatewayReady: ready,
            fromBgRefresh: fromBgRefresh
        ) else {
            return false
        }
        running = true
        startedAt = Date()
        bytes = 0
        let me = MCPeerID(displayName: "nh")
        peerId = me
        let session = MCSession(peer: me, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session
        let adv = MCNearbyServiceAdvertiser(
            peer: me,
            discoveryInfo: nil,
            serviceType: NHBulkPolicy.serviceType
        )
        adv.delegate = self
        advertiser = adv
        adv.startAdvertisingPeer()
        return true
    }

    public func joinAndroidSoftAP(ssid: String, psk: String, host: String, port: UInt16) {
        guard NHBulkPolicy.mayStart(
            sceneForeground: NighthawkMeshController.shared.sceneForeground,
            gatewayReady: true,
            fromBgRefresh: false
        ) else { return }
        let cfg = NEHotspotConfiguration(ssid: ssid, passphrase: psk, isWEP: false)
        cfg.joinOnce = true
        NEHotspotConfigurationManager.shared.apply(cfg) { error in
            if error == nil {
                MeshEngineBridge.setBulkTcp(host: host, port: Int32(port))
            }
        }
    }

    public func noteBytes(_ n: UInt64) -> Bool {
        guard running, let startedAt else { return false }
        if Date().timeIntervalSince(startedAt) > NHBulkPolicy.maxSeconds {
            stop()
            return false
        }
        bytes += n
        if bytes > NHBulkPolicy.maxBytes {
            stop()
            return false
        }
        return MeshEngineBridge.recordBulkBytes(n)
    }

    public func stop() {
        running = false
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        advertiser = nil
        browser = nil
        session = nil
        peerId = nil
        MeshEngineBridge.setBulkTcp(host: nil, port: 0)
    }
}

extension NHBulkLink: MCSessionDelegate {
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        _ = (session, peerID, state)
    }

    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        _ = (session, data, peerID)
        _ = noteBytes(UInt64(data.count))
    }

    public func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {
        _ = (session, stream, streamName, peerID)
    }

    public func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {
        _ = (session, resourceName, peerID, progress)
    }

    public func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: Error?
    ) {
        _ = (session, resourceName, peerID, localURL, error)
    }
}

extension NHBulkLink: MCNearbyServiceAdvertiserDelegate {
    public func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        _ = (advertiser, peerID, context)
        invitationHandler(true, session)
    }
}
