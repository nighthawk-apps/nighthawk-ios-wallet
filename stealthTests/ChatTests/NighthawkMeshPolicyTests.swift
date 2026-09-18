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
        let c = NighthawkMeshController.shared
        c.handleScene(.active)
        XCTAssertEqual(c.gcsInterval, 15)
        c.handleScene(.background)
        XCTAssertEqual(c.gcsInterval, 60)
        XCTAssertTrue(c.backgroundDrainRequested)
        XCTAssertFalse(NighthawkMeshPolicy.mayStartUnifOmrBulk(
            sceneForeground: false, gatewayReady: true
        ))
        c.handleScene(.active)
        XCTAssertFalse(c.backgroundDrainRequested)
    }

    func testBackgroundDrainBudgetIsThirtySeconds() {
        XCTAssertEqual(NighthawkMeshPolicy.backgroundDrainBudgetSeconds, 30)
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
