//
//  DarkfiTransferTests.swift
//  stealthTests
//

import XCTest
@testable import DarkfiCore

/// Alternate live-testnet path (birthday 0). Soft-passes removed — skip when offline.
final class DarkfiTransferTests: XCTestCase {
    func testFullTransactionSyncAndTransferLiveTestnet() throws {
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["NIGHTHAWK_LIVE_TESTNET"] != "1",
            "Set NIGHTHAWK_LIVE_TESTNET=1 with LWD on tcp://127.0.0.1:9067 to run"
        )

        let seedWords = [String](repeating: "abandon", count: 22)
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let walletDbPath = docs.appendingPathComponent("darkfi_test_wallet_e2e.db").path
        let cachePath = docs.appendingPathComponent("darkfi_test_cache_e2e").path

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
            birthdayHeight: 0,
            lightwalletTlsPinSha256: nil,
            useTor: false,
            torSocksPort: 9050,
            useNym: false,
            nymSocksPort: 1080,
            darkfidRpcUrl: nil,
            strictOmrOnly: false
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

        let dummyRecipient = "fRGoBKrJuxKutPqQVGu6Mpp94uEREg6yDG9MZponXoJ1KzMGEeSAtjxm"

        do {
            let fee = try handle.estimateTransferFee(
                recipientAddress: dummyRecipient,
                amount: "0.1",
                tokenId: nil,
                paymentMemo: nil
            )
            print("Estimated fee: \(fee). Submitting transfer...")

            let txHash = try handle.broadcastTransfer(
                txBytes: try handle.buildTransfer(
                    recipientAddress: dummyRecipient,
                    amount: "0.1",
                    tokenId: nil,
                    paymentMemo: nil
                ),
                paymentMemo: nil,
                recipientAddress: dummyRecipient
            )
            print("TXID_DUMP: \(txHash)")
            XCTAssertFalse(txHash.isEmpty)
        } catch let error as DarkfiWalletNativeError {
            if case .NativeDrkUnavailable(let message) = error,
               message.contains("Did not find any unspent coins") {
                throw XCTSkip("Wallet unfunded: \(message)")
            }
            XCTFail("Unexpected error: \(error)")
        }
    }
}
