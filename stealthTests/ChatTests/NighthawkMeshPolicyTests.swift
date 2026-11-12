import XCTest
import Home

final class NighthawkMeshPolicyTests: XCTestCase {
    func testGatewayRequiresChargingAndUnmetered() {
        XCTAssertFalse(NighthawkMeshPolicy.gatewayReady(
            meshOn: true, gatewayOptIn: true, charging: false, unmetered: true
        ))
        XCTAssertFalse(NighthawkMeshPolicy.gatewayReady(
            meshOn: true, gatewayOptIn: true, charging: true, unmetered: false
        ))
        XCTAssertTrue(NighthawkMeshPolicy.gatewayReady(
            meshOn: true, gatewayOptIn: true, charging: true, unmetered: true
        ))
    }

    func testWalletRefreshNeverStartsUnifOmr() {
        XCTAssertFalse(NighthawkMeshPolicy.backgroundTaskMayStartUnifOmr(
            taskIdentifier: NighthawkMeshPolicy.walletRefreshTaskId
        ))
        XCTAssertFalse(NighthawkMeshPolicy.backgroundTaskMayStartUnifOmr(
            taskIdentifier: NighthawkMeshPolicy.walletProcessingTaskId
        ))
    }

    func testBulkIsForegroundOnly() {
        XCTAssertFalse(NighthawkMeshPolicy.mayStartUnifOmrBulk(sceneForeground: false, gatewayReady: true))
        XCTAssertTrue(NighthawkMeshPolicy.mayStartUnifOmrBulk(sceneForeground: true, gatewayReady: true))
        XCTAssertFalse(NighthawkMeshPolicy.mayStartUnifOmrBulk(
            sceneForeground: true, gatewayReady: true, fromBgRefresh: true
        ))
        XCTAssertFalse(NHBulkPolicy.mayStart(
            sceneForeground: true, gatewayReady: true, fromBgRefresh: true
        ))
        XCTAssertFalse(NighthawkMeshPolicy.backgroundTaskMayStartUnifOmr(
            taskIdentifier: NighthawkMeshPolicy.walletRefreshTaskId
        ))
        XCTAssertEqual(NHBulkPolicy.maxBytes, 200 * 1024 * 1024)
        XCTAssertEqual(NHBulkPolicy.serviceType, "nighthawk-mesh")
    }

    func testLwdCtrlOriginateIsForegroundOnly() {
        XCTAssertFalse(NighthawkMeshPolicy.mayOriginateLwdCtrl(sceneForeground: false))
        XCTAssertTrue(NighthawkMeshPolicy.mayOriginateLwdCtrl(sceneForeground: true))
        XCTAssertTrue(NighthawkMeshPolicy.mayFinishInFlightCtrl(backgroundTaskActive: true))
        XCTAssertFalse(NighthawkMeshPolicy.mayFinishInFlightCtrl(backgroundTaskActive: false))
    }

    func testUuidsAreNotBitchat() {
        XCTAssertFalse(NighthawkMeshPolicy.isBitchatServiceUUID(NighthawkMeshPolicy.serviceUUIDString))
        XCTAssertTrue(NighthawkMeshPolicy.isBitchatServiceUUID("F47B5E2D-4A9E-4C5A-9B3F-8E1D2C3A4B5C"))
    }

    func testBackgroundGcsSlowsDown() {
        XCTAssertEqual(NighthawkMeshPolicy.gcsIntervalSeconds(sceneForeground: true), 15)
        XCTAssertEqual(NighthawkMeshPolicy.gcsIntervalSeconds(sceneForeground: false), 60)
    }

    func testRestoreIdsAreStable() {
        XCTAssertTrue(NighthawkMeshPolicy.bleCentralRestoreId.contains("nighthawkapps"))
        XCTAssertTrue(NighthawkMeshPolicy.blePeripheralRestoreId.contains("peripheral"))
    }

    func testControllerBackgroundSlowsGcs() {
        let controller = NighthawkMeshController.shared
        controller.handleScene(.active)
        XCTAssertEqual(controller.gcsInterval, 15)
        controller.handleScene(.background)
        XCTAssertEqual(controller.gcsInterval, 60)
        XCTAssertTrue(controller.backgroundDrainRequested)
        XCTAssertFalse(NighthawkMeshPolicy.mayStartUnifOmrBulk(
            sceneForeground: false, gatewayReady: true
        ))
        controller.handleScene(.active)
        XCTAssertFalse(controller.backgroundDrainRequested)
    }

    func testBackgroundDrainBudgetIsThirtySeconds() {
        XCTAssertEqual(NighthawkMeshPolicy.backgroundDrainBudgetSeconds, 30)
    }

    func testRedundantLinkKeepsNewestWritableRadio() {
        let older = Date(timeIntervalSince1970: 1_000)
        let newer = Date(timeIntervalSince1970: 2_000)
        let links = [
            NHBLERedundantLinkPolicy.Link(
                uuid: "old",
                peerID: "aa",
                isConnected: true,
                hasCharacteristic: true,
                lastConnectedAt: older
            ),
            NHBLERedundantLinkPolicy.Link(
                uuid: "new",
                peerID: "aa",
                isConnected: true,
                hasCharacteristic: true,
                lastConnectedAt: newer
            )
        ]
        XCTAssertEqual(
            NHBLERedundantLinkPolicy.keptUUID(
                ingressUUID: "old",
                mostRecentlyBoundUUID: "old",
                links: links,
                peerID: "aa"
            ),
            "new"
        )
        XCTAssertEqual(
            NHBLERedundantLinkPolicy.uuidsToRetire(links: links, peerID: "aa", keeping: "new"),
            ["old"]
        )
    }

    func testRedundantLinkDefersWhileNewestIsDiscovering() {
        let older = Date(timeIntervalSince1970: 1_000)
        let newer = Date(timeIntervalSince1970: 2_000)
        let links = [
            NHBLERedundantLinkPolicy.Link(
                uuid: "old",
                peerID: "aa",
                isConnected: true,
                hasCharacteristic: true,
                lastConnectedAt: older
            ),
            NHBLERedundantLinkPolicy.Link(
                uuid: "new",
                peerID: "aa",
                isConnected: true,
                hasCharacteristic: false,
                lastConnectedAt: newer
            )
        ]
        XCTAssertNil(
            NHBLERedundantLinkPolicy.keptUUID(
                ingressUUID: nil,
                mostRecentlyBoundUUID: "new",
                links: links,
                peerID: "aa"
            )
        )
    }

    func testScanDutyMatchesDenseQuietMesh() {
        XCTAssertEqual(
            NHBLEScanDutyPolicy.plan(
                dutyEnabled: true,
                appIsActive: true,
                connectedCount: 2,
                hasRecentTraffic: false
            ),
            .continuous
        )
        XCTAssertEqual(
            NHBLEScanDutyPolicy.plan(
                dutyEnabled: true,
                appIsActive: true,
                connectedCount: 4,
                hasRecentTraffic: true
            ),
            .continuous
        )
        XCTAssertEqual(
            NHBLEScanDutyPolicy.plan(
                dutyEnabled: true,
                appIsActive: true,
                connectedCount: 4,
                hasRecentTraffic: false
            ),
            .dutyCycle(onDuration: 5, offDuration: 10)
        )
        XCTAssertEqual(
            NHBLEScanDutyPolicy.plan(
                dutyEnabled: true,
                appIsActive: true,
                connectedCount: 6,
                hasRecentTraffic: false
            ),
            .dutyCycle(onDuration: 3, offDuration: 15)
        )
        XCTAssertTrue(NHBLEScanDutyPolicy.shouldConnect(rssi: -95, connectedCount: 0))
        XCTAssertFalse(NHBLEScanDutyPolicy.shouldConnect(rssi: -95, connectedCount: 1))
    }

    func testRadioUserStateMapsCoreBluetoothRawValues() {
        XCTAssertEqual(NighthawkMeshPolicy.radioUserState(centralRawValue: 5), .ready)
        XCTAssertEqual(NighthawkMeshPolicy.radioUserState(centralRawValue: 4), .poweredOff)
        XCTAssertEqual(NighthawkMeshPolicy.radioUserState(centralRawValue: 3), .unauthorized)
        XCTAssertEqual(NighthawkMeshPolicy.radioUserState(centralRawValue: 2), .unsupported)
        XCTAssertEqual(NighthawkMeshPolicy.radioUserState(centralRawValue: 0), .pending)
    }

    func testRestoredLinksNeedRediscoveryOrReconnect() {
        XCTAssertTrue(NighthawkMeshPolicy.shouldRediscoverRestoredLink(
            peripheralConnected: true, hasCharacteristic: false
        ))
        XCTAssertFalse(NighthawkMeshPolicy.shouldRediscoverRestoredLink(
            peripheralConnected: true, hasCharacteristic: true
        ))
        XCTAssertTrue(NighthawkMeshPolicy.shouldReconnectRestoredLink(peripheralConnected: false))
        XCTAssertFalse(NighthawkMeshPolicy.shouldReconnectRestoredLink(peripheralConnected: true))
    }

    func testOfflineRelayUnifOmrIsBulkJoinWhenForeground() {
        let dest = Data(repeating: 0x11, count: 8)
        let p = MeshOfflineRelay.plan(
            meshOn: true,
            internetUnreachable: true,
            needUnifOmr: true,
            sceneForeground: true,
            dest: dest,
            gatewayCaps: 0x03
        )
        XCTAssertEqual(p, .bulkJoin(dest: dest))
    }

    func testOfflineRelayGetLightInfoIsCtrl() {
        let dest = Data(repeating: 0x11, count: 8)
        let p = MeshOfflineRelay.plan(
            meshOn: true,
            internetUnreachable: true,
            needUnifOmr: false,
            sceneForeground: true,
            dest: dest,
            method: "GetLightInfo"
        )
        XCTAssertEqual(p, .ctrl(dest: dest, method: "GetLightInfo"))
    }

    func testOfflineRelayInternetUpAndForbiddenAreNone() {
        let dest = Data(repeating: 0x11, count: 8)
        XCTAssertEqual(
            MeshOfflineRelay.plan(
                meshOn: true,
                internetUnreachable: false,
                needUnifOmr: true,
                sceneForeground: true,
                dest: dest
            ),
            .none
        )
        XCTAssertEqual(
            MeshOfflineRelay.plan(
                meshOn: true,
                internetUnreachable: true,
                needUnifOmr: false,
                sceneForeground: true,
                dest: dest,
                method: "GetUnifOmrDigest"
            ),
            .none
        )
        XCTAssertEqual(
            MeshOfflineRelay.plan(
                meshOn: true,
                internetUnreachable: true,
                needUnifOmr: true,
                sceneForeground: false,
                dest: dest
            ),
            .none
        )
        XCTAssertEqual(
            MeshOfflineRelay.plan(
                meshOn: true,
                internetUnreachable: true,
                needUnifOmr: true,
                sceneForeground: true,
                fromBgRefresh: true,
                dest: dest
            ),
            .none
        )
    }
}
