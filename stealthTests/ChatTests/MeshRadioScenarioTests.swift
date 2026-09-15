import Home
import XCTest

final class MeshRadioScenarioTests: XCTestCase {
    func testThreePhoneConnectChatLostReconnectReset() {
        XCTAssertEqual(
            MeshRadioScenario.runThreePhoneScript(),
            ["connect a-r-g", "chat", "dag-sync", "lost", "reconnect", "reset"]
        )
    }

    func testLostLinkDropsFrames() {
        let a = MeshRadioScenario.Phone(id: "a")
        var r = MeshRadioScenario.Phone(id: "r")
        r.meshOn = false
        let frame = MeshRadioScenario.chatFrame(from: Data(repeating: 1, count: 8), body: "nope")
        XCTAssertFalse(MeshRadioScenario.deliver(from: a, to: &r, frame: frame))
        XCTAssertTrue(r.inbox.isEmpty)
    }

    func testForbiddenLwdDroppedOnRadio() {
        let a = MeshRadioScenario.Phone(id: "a")
        var r = MeshRadioScenario.Phone(id: "r")
        let frame = MeshWireCodec.encode(MeshWirePacket(
            type: MeshWireCodec.lwdCtrl,
            ttl: 0,
            flags: 0,
            timestampMs: 0,
            sender: Data(repeating: 2, count: 8),
            recipient: nil,
            payload: Data("GetUnifOmrDigest\n".utf8)
        ))!
        XCTAssertFalse(MeshRadioScenario.deliver(from: a, to: &r, frame: frame))
        XCTAssertTrue(r.inbox.isEmpty)
    }

    func testTwoPhonePolicyUuidsAreNotBitchat() {
        XCTAssertFalse(NighthawkMeshPolicy.isBitchatServiceUUID(NighthawkMeshPolicy.serviceUUIDString))
        XCTAssertEqual(NHBLELinkPolicy.scanServices().count, 1)
        XCTAssertFalse(NighthawkMeshPolicy.backgroundTaskMayStartUnifOmr(
            taskIdentifier: NighthawkMeshPolicy.walletRefreshTaskId
        ))
    }
}
