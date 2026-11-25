//
//  SendTests.swift
//  stealthTests
//

import XCTest
import ComposableArchitecture
import DerivationTool
import Home
import LocalAuthenticationClient
import Migrate
import Models
import SDKSynchronizer
import SendFlow
import Splash
import UserPreferencesStorage
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
        if FileManager.default.fileExists(atPath: "/tmp/studio-mined-wallet/seed_dummy_pass.db") {
            try? FileManager.default.copyItem(atPath: "/tmp/studio-mined-wallet/seed_dummy_pass.db", toPath: walletDbPath)
        }
        if FileManager.default.fileExists(atPath: "/tmp/studio-mined-wallet/cache_dummy") {
            try? FileManager.default.copyItem(atPath: "/tmp/studio-mined-wallet/cache_dummy", toPath: cachePath)
        } else {
            try? FileManager.default.createDirectory(atPath: cachePath, withIntermediateDirectories: true)
        }

        let config = DrkBootstrapConfig(
            network: "testnet",
            mnemonic: seedWords,
            walletDbPath: walletDbPath,
            cachePath: cachePath,
            walletPass: "dummy_wallet_pass",
            lightwalletServerUrl: "tcp://127.0.0.1:9067",
            birthdayHeight: 91808,
            lightwalletTlsPinSha256: nil,
            useTor: false,
            torSocksPort: 9050,
            useNym: false,
            nymSocksPort: 1080,
            darkfidRpcUrl: "tcp://127.0.0.1:18345",
            strictOmrOnly: false
        )

        let handle: DarkfiWalletHandle
        do {
            handle = try DarkfiWalletHandle(config: config)
        } catch {
            throw XCTSkip("LWD/wallet bootstrap unavailable: \(error)")
        }

        let tip: Int64
        do {
            tip = try Self.waitForLiveTip(handle)
            print("Testnet sync snapshot tip is \(tip), balance=\(try handle.confirmedBalanceAtomic())")
        } catch {
            XCTFail("Sync failed against the Studio lightwalletd: \(error)")
            return
        }
        XCTAssertGreaterThan(tip, 0, "Live test never observed the Studio chain tip")
        guard tip > 0 else { return }

        let addresses = try handle.listAddresses()
        print("WALLET_ADDRESS_DUMP: \(addresses.first ?? "none")")
        XCTAssertFalse(addresses.isEmpty, "Expected at least one receive address")

        let dummyRecipient = "fWnYMrPf2ACXemapSZtZUxsAwPXReYu9U5b2Nic2rEU4VS17EogCweNY"
        // Whole-DRK decimal string (not atomic Int64 string).
        let amountDecimal = "0.05"

        let fee: Int64
        do {
            fee = try handle.estimateTransferFee(
                recipientAddress: dummyRecipient,
                amount: amountDecimal,
                tokenId: nil as String?,
                paymentMemo: "nh-phase4-ios-sim-tailscale-e2e"
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
                    paymentMemo: "nh-phase4-ios-sim-tailscale-e2e"
                ),
                paymentMemo: "nh-phase4-ios-sim-tailscale-e2e",
                recipientAddress: dummyRecipient
            )
            print("TXID_DUMP: \(txHash)")
            print("E2E_EXPLORER: https://explorer.testnet.dark.fi/tx/\(txHash)")
            XCTAssertFalse(txHash.isEmpty)
        } catch let error as DarkfiWalletNativeError {
            if case .NativeDrkUnavailable(let message) = error,
               message.contains("Did not find any unspent coins"), tip > 0 {
                throw XCTSkip("Wallet unfunded after seeing tip \(tip): \(message)")
            }
            XCTFail("Unexpected broadcast error: \(error)")
        }
    }

    /// Background light sync fills the engine snapshot. A zero tip means this
    /// process never reached lightwalletd, which is a failure when the live flag is set.
    private static func waitForLiveTip(_ handle: DarkfiWalletHandle) throws -> Int64 {
        _ = try handle.refreshNow()
        let deadline = Date().addingTimeInterval(45)
        var tip = try handle.syncSnapshot().chainTip
        while tip <= 0 && Date() < deadline {
            Thread.sleep(forTimeInterval: 2)
            tip = try handle.syncSnapshot().chainTip
        }
        return tip
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

@MainActor
final class SendFlowAndSyncUnitTests: XCTestCase {
    func testCustomTokenBalanceValidationUsesSelectedTokenBalanceAndDrkFee() {
        var state = SendFlow.State(latestFiatPrice: nil)
        state.spendableBalance = 10_000 // 0.0001 DRK (enough for fee, less than token amount)
        state.availableTokens = [
            TokenBalanceInfo(tokenId: "tok_abc", displayLabel: "TEST", balanceAtomic: 500_000_000)
        ]
        state.selectedTokenId = "tok_abc"
        state.amountToSendInput = "2" // 200_000_000 atomic > DRK balance, <= token balance

        XCTAssertEqual(state.selectedSpendableBalance, 500_000_000)
        XCTAssertTrue(state.canSendEnteredAmount)

        state.amountToSendInput = "6" // > token balance
        XCTAssertFalse(state.canSendEnteredAmount)

        // Custom token requires >0 DRK for fee
        state.amountToSendInput = "1"
        state.spendableBalance = 0
        XCTAssertFalse(state.canSendEnteredAmount)

        state.spendableBalance = 1_000
        XCTAssertFalse(state.customTokenFeeIsCovered(Proposal(estimatedFee: 5_000_000)))
        state.spendableBalance = 5_000_000
        XCTAssertTrue(state.customTokenFeeIsCovered(Proposal(estimatedFee: 5_000_000)))
        state.selectedTokenId = nil
        state.spendableBalance = 1
        XCTAssertTrue(state.customTokenFeeIsCovered(Proposal(estimatedFee: 5_000_000)))
    }

    func testSendFlowProposeAndErrorPropagationIntoSendFailed() async {
        var initialState = SendFlow.State(latestFiatPrice: nil)
        initialState.spendableBalance = 500_000_000
        initialState.amountToSendInput = "0.5"
        initialState.recipient = "fRGoBKrJuxKutPqQVGu6Mpp94uEREg6yDG9MZponXoJ1KzMGEeSAtjxm"

        var capturedDecimalArg: String?
        let store = TestStore(
            initialState: initialState,
            reducer: SendFlow.init
        ) {
            $0.sdkSynchronizer = .inert
            $0.sdkSynchronizer.latestState = {
                SynchronizerState(
                    syncStatus: .upToDate,
                    confirmedBalance: 500_000_000,
                    latestBlockHeight: 42,
                    activeSyncMethod: .unifOmr,
                    lightwalletdConnected: true
                )
            }
            $0.sdkSynchronizer.proposeTransfer = { _, _, amount, _, _ in
                capturedDecimalArg = amount.inputDecimalString()
                return Proposal(estimatedFee: 10_000)
            }
            $0.sdkSynchronizer.sendTransaction = { _, _, _, _, _ in
                throw DarkfiError(message: "Insufficient mempool fee")
            }
            $0.derivationTool.isDarkFiAddress = { _, _ in false }
        }
        store.exhaustivity = .off

        await store.send(.continueTapped)
        await store.receive(.setProposal(Proposal(estimatedFee: 10_000)))
        await store.receive { action in
            if case let .review(reviewState) = action {
                return reviewState.syncMethod == .unifOmr && reviewState.zecAmount == 50_000_000
            }
            return false
        }
        XCTAssertEqual(capturedDecimalArg, "0.5")

        await store.send(.sendTransaction)
        await store.receive(.sendTransactionInProgress)
        await store.receive(.sendTransactionFailure("Insufficient mempool fee")) { state in
            state.isSendingTransaction = false
            XCTAssertEqual(
                state.path.last,
                SendFlow.Path.State.failed(.init(errorMessage: "Insufficient mempool fee"))
            )
        }
    }

    func testSyncStatusSnapshotPropagatesLightStatusMessage() {
        let syncState = SynchronizerState(
            syncStatus: .upToDate,
            confirmedBalance: 100_000_000,
            latestBlockHeight: 77,
            activeSyncMethod: .trialDecrypt,
            lightwalletdConnected: true,
            lightStatusMessage: "Synced · Block 77 — lightwalletd has not reached darkfid recently"
        )
        let snapshot = SyncStatusSnapshot.snapshotFor(state: syncState)
        XCTAssertEqual(
            snapshot.lightSyncStatusMessage,
            "Synced · Block 77 — lightwalletd has not reached darkfid recently"
        )
    }

    func testTransactionHistoryRefreshesWhenUpToDateBalanceChanges() async {
        let expectedTx = DarkfiTransactionOverview(
            rawId: "tx_live_refresh",
            minedHeight: 88,
            totalAtomicValue: 250_000_000,
            fee: 10_000,
            isSending: false
        )
        let store = TestStore(
            initialState: TransactionHistory.State(latestFiatPrice: nil),
            reducer: TransactionHistory.init
        ) {
            $0.sdkSynchronizer = .inert
            $0.sdkSynchronizer.latestState = {
                SynchronizerState(syncStatus: .upToDate, confirmedBalance: 250_000_000, latestBlockHeight: 88)
            }
            $0.sdkSynchronizer.getAllTransactions = { [expectedTx] }
        }
        store.exhaustivity = .off

        let first = SynchronizerState(syncStatus: .upToDate, confirmedBalance: 0, latestBlockHeight: 87)
        await store.send(.synchronizerStateChanged(first))
        let second = SynchronizerState(syncStatus: .upToDate, confirmedBalance: 250_000_000, latestBlockHeight: 88)
        await store.send(.synchronizerStateChanged(second))
        await store.receive { action in
            if case let .updateWalletEvents(events) = action {
                return events.first?.id == "tx_live_refresh"
            }
            return false
        }
        XCTAssertEqual(store.state.walletEvents.first?.id, "tx_live_refresh")
    }

    func testHomeWalletScanPassesBalanceAndAddressToSendFlow() async {
        await withDependencies {
            HomeTestSupport.configureDependencies(&$0)
        } operation: {
            var homeState = Home.State(receiveAddress: DarkfiAddress(stringEncoded: "drk1self"))
            homeState.walletInfo.balance = 333_000_000

            let store = TestStore(
                initialState: homeState,
                reducer: Home.init
            ) {
                HomeTestSupport.configureDependencies(&$0)
            }
            store.exhaustivity = .off

            await store.send(.wallet(.delegate(.scanPaymentRequest))) { state in
                if case let .send(sendState) = state.transfer.destination {
                    XCTAssertEqual(sendState.spendableBalance, 333_000_000)
                    XCTAssertEqual(sendState.receiveAddress?.stringEncoded, "drk1self")
                } else {
                    XCTFail("Expected SendFlow destination")
                }
            }
        }
    }

    func testMigrateRestoreManuallySendsImportManuallyDelegate() async {
        let store = TestStore(
            initialState: Migrate.State(),
            reducer: Migrate.init
        )
        await store.send(.restoreManuallyTapped)
        await store.receive(.delegate(.importManually))
    }

    func testSplashAuthenticateLaunchesWhenDeviceHasNoPasscode() async {
        SecurityPinStore.clearPin()
        var prefs = UserPreferencesStorageClient.liveValue
        prefs.areBiometricsEnabled = { false }
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let store = TestStore(
            initialState: Splash.State(),
            reducer: Splash.init
        ) {
            $0.date = .constant(now)
            $0.userStoredPreferences = prefs
            $0.localAuthenticationContext = LocalAuthenticationContextClientGenerator {
                LocalAuthenticationContextClient(
                    biometryType: { .none },
                    canEvaluatePolicy: { _ in false },
                    evaluatePolicy: { _, _ in false }
                )
            }
        }

        await store.send(.authenticate) { state in
            state.isAuthenticating = true
        }
        await store.receive(.authenticationResponse(true)) { state in
            state.hasAttemptedAuthentication = true
            state.isAuthenticating = false
            state.lastAuthenticatedTime = now
        }
        await store.receive(.delegate(.initializeSDKAndLaunchWallet))
    }
}
