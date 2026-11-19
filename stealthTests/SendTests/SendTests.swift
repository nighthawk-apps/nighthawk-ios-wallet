//
//  SendTests.swift
//  stealthTests
//

import XCTest
import DerivationTool
import Models
import Utils
@testable import DarkfiCore

/// Live-testnet transfer integration. Requires local LWD on :9067.
/// Unavailable endpoints → XCTSkip (never soft-pass as success).
final class SendTests: XCTestCase {
    func testAtomicAmountConvertsToWholeDrkDecimalForRustFfi() {
        // Rust estimateTransferFee/buildTransfer parse base-10 whole DRK (8 decimals).
        // Passing String(atomic) caused a 10^8× mismatch.
        let oneDrkAtomic: DrkAmount = 100_000_000
        XCTAssertEqual(oneDrkAtomic.inputDecimalString(), "1")

        let oneAtomic: DrkAmount = 1
        XCTAssertEqual(oneAtomic.inputDecimalString(), "0.00000001")

        let fractional: DrkAmount = 12_345_678
        XCTAssertEqual(fractional.inputDecimalString(), "0.12345678")
    }

    func testDarkFiAddressValidationRejectsUrisAndAcceptsBare() {
        let tool = DerivationToolClient.live()
        let addr = "fRGoBKrJuxKutPqQVGu6Mpp94uEREg6yDG9MZponXoJ1KzMGEeSAtjxm"
        XCTAssertTrue(tool.isDarkFiAddress(addr, "testnet"))
        XCTAssertFalse(tool.isDarkFiAddress("drk:\(addr)?amount=1", "testnet"))
        XCTAssertFalse(tool.isDarkFiAddress("not an address", "testnet"))
    }

    func testTransactionStateConfirmationsAndSignedAmount() {
        var tx = TransactionState.placeholder(amount: 1, status: .received)
        tx.minedHeight = 100
        XCTAssertEqual(tx.confirmationsWith(50), 0)
        XCTAssertEqual(tx.confirmationsWith(105), 5)

        let alreadyNegative = DarkfiTransactionOverview(
            rawId: "abc",
            totalAtomicValue: -50_000_000,
            fee: 10_000,
            isSending: true
        )
        XCTAssertEqual(TransactionState(from: alreadyNegative).zecAmount, -50_000_000)

        let freshPositive = DarkfiTransactionOverview(
            rawId: "def",
            totalAtomicValue: 25_000_000,
            fee: 10_000,
            isSending: true
        )
        XCTAssertEqual(TransactionState(from: freshPositive).zecAmount, -25_000_000)
    }

    func testFullTransactionSyncAndTransferLiveTestnet() throws {
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["NIGHTHAWK_LIVE_TESTNET"] != "1",
            "Set NIGHTHAWK_LIVE_TESTNET=1 with LWD on tcp://127.0.0.1:9067 to run"
        )

        let clockFailureOptions = XCTExpectedFailure.Options()
        clockFailureOptions.isStrict = false
        clockFailureOptions.issueMatcher = { issue in
            issue.compactDescription.contains("ContinuousClock")
        }
        XCTExpectFailure(
            "Host app ContinuousClock unimplemented during FFI e2e",
            options: clockFailureOptions
        )

        let seedWords = [String](repeating: "abandon", count: 22)
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let walletDbPath = docs.appendingPathComponent("darkfi_send_tests_wallet.db").path
        let cachePath = docs.appendingPathComponent("darkfi_send_tests_cache").path

        try? FileManager.default.removeItem(atPath: walletDbPath)
        try? FileManager.default.removeItem(atPath: cachePath)
        try? FileManager.default.createDirectory(atPath: cachePath, withIntermediateDirectories: true)

        let config = DrkBootstrapConfig(
            network: "testnet",
            mnemonic: seedWords,
            walletDbPath: walletDbPath,
            cachePath: cachePath,
            walletPass: "dummy_wallet_pass",
            lightwalletServerUrl: "tcp://127.0.0.1:9067",
            birthdayHeight: 22000,
            lightwalletTlsPinSha256: nil,
            useTor: false,
            torSocksPort: 9050,
            darkfidRpcUrl: "tcp://127.0.0.1:18345"
        )

        let handle: DarkfiWalletHandle
        do {
            handle = try DarkfiWalletHandle(config: config)
        } catch {
            throw XCTSkip("LWD/wallet bootstrap unavailable: \(error)")
        }

        do {
            let snapshot = try handle.refreshNow()
            print("Testnet sync snapshot: \(snapshot.scannedBlocks) blocks scanned, tip is \(snapshot.chainTip)")
        } catch {
            throw XCTSkip("Sync failed or node not ready: \(error)")
        }

        let addresses = try handle.listAddresses()
        print("WALLET_ADDRESS_DUMP: \(addresses.first ?? "none")")
        XCTAssertFalse(addresses.isEmpty, "Expected at least one receive address")

        let dummyRecipient = "fRGoBKrJuxKutPqQVGu6Mpp94uEREg6yDG9MZponXoJ1KzMGEeSAtjxm"
        // Whole-DRK decimal string (not atomic Int64 string).
        let amountDecimal = "0.1"

        let fee: Int64
        do {
            fee = try handle.estimateTransferFee(
                recipientAddress: dummyRecipient,
                amount: amountDecimal,
                tokenId: nil as String?,
                paymentMemo: nil as String?
            )
        } catch let error as DarkfiWalletNativeError {
            if case .NativeDrkUnavailable(let msg) = error,
               msg.contains("Did not find any unspent coins") ||
               msg.contains("state transition") ||
               msg.contains("0x5") {
                throw XCTSkip("Wallet unfunded / tip low: \(msg)")
            }
            XCTFail("estimateTransferFee failed: \(error)")
            return
        }

        print("Estimated fee: \(fee)")

        do {
            let txHash = try handle.broadcastTransfer(
                txBytes: try handle.buildTransfer(
                    recipientAddress: dummyRecipient,
                    amount: amountDecimal,
                    tokenId: nil as String?,
                    paymentMemo: nil as String?
                ),
                paymentMemo: nil as String?,
                recipientAddress: dummyRecipient
            )
            print("TXID_DUMP: \(txHash)")
            XCTAssertFalse(txHash.isEmpty)
        } catch let error as DarkfiWalletNativeError {
            if case .NativeDrkUnavailable(let message) = error,
               message.contains("Did not find any unspent coins") {
                throw XCTSkip("No unspent coins for broadcast: \(message)")
            }
            XCTFail("Unexpected broadcast error: \(error)")
        }
    }
}

final class ChatWalletLogicTests: XCTestCase {
    func testReceiptRoundTripAndInvoiceFind() {
        let receipt = ChatReceipt(
            id: "r1",
            phase: .pending,
            amount: "2",
            address: "addr",
            memo: "lunch"
        )
        let parsed = ChatReceiptCodec.parse(ChatReceiptCodec.encode(receipt))
        XCTAssertEqual(parsed?.phase, .pending)
        XCTAssertEqual(parsed?.memo, "lunch")
        XCTAssertEqual(parsed?.amount, "2")

        let invoice = PaymentRequestUri.find(in: "pay drk:abc?amount=1 thanks")
        XCTAssertEqual(invoice?.address, "abc")
        XCTAssertEqual(invoice?.amount, "1")
    }

    func testClearnetGuardAndDeliveryPrefixes() {
        XCTAssertTrue(ChatLinkGuard.isClearnetHttp("https://dark.fi/docs"))
        XCTAssertFalse(ChatLinkGuard.isClearnetHttp("fud://abc"))
        XCTAssertEqual(ChatLinkGuard.firstClearnet(in: "see https://dark.fi/docs."), "https://dark.fi/docs")
        XCTAssertEqual(ChatDeliveryLabel.from(eventId: "queued-1", isOutgoing: true), .queued)
        XCTAssertEqual(ChatDeliveryLabel.from(eventId: "local-1", isOutgoing: true), .sending)
        XCTAssertEqual(ChatDeliveryLabel.from(eventId: "failed-1", isOutgoing: true), .failed)
        XCTAssertEqual(ChatDeliveryLabel.from(eventId: "evt", isOutgoing: true), .relayed)
        XCTAssertNil(ChatDeliveryLabel.from(eventId: "evt", isOutgoing: false))
    }

    func testInviteRoundTripAndNotificationSkips() {
        let contact = NighthawkContact(id: "ada", nickname: "Ada", dmPublicKey: "pk", walletAddress: "drk1")
        XCTAssertEqual(NighthawkContacts.inviteUri(contact), "drk:drk1")
        let parsed = NighthawkContacts.parseInvite(NighthawkContacts.inviteUri(contact) ?? "")
        XCTAssertEqual(parsed?.walletAddress, "drk1")
        XCTAssertNil(NighthawkContacts.inviteUri(NighthawkContact(id: "ada", nickname: "Ada", dmPublicKey: "pk")))
        XCTAssertEqual(
            NighthawkContacts.safetyNumber(dmPublicKey: "pk", walletAddress: "drk1"),
            NighthawkContacts.safetyNumber(dmPublicKey: "pk", walletAddress: "drk1")
        )
        XCTAssertFalse(ChatNotificationPolicy.shouldAlert(
            isOutgoing: true,
            ownNick: "me",
            nick: "other",
            timestamp: Date()
        ))
        XCTAssertFalse(ChatNotificationPolicy.shouldAlert(
            isOutgoing: false,
            ownNick: "me",
            nick: "Me",
            timestamp: Date()
        ))
        XCTAssertFalse(ChatNotificationPolicy.shouldAlert(
            isOutgoing: false,
            ownNick: "me",
            nick: "other",
            timestamp: Date().addingTimeInterval(-120)
        ))
    }
}
