//
//  SDKSynchronizerTest.swift
//  stealth
//
//  Test/preview stubs for SDKSynchronizerClient.
//

import Combine
import ComposableArchitecture
import Foundation
import Utils

extension SDKSynchronizerClient: TestDependencyKey {
    public static let previewValue: SDKSynchronizerClient = Self.mock()

    public static let testValue: SDKSynchronizerClient = Self(
        stateStream: unimplemented("\(Self.self).stateStream"),
        latestState: unimplemented("\(Self.self).latestState", placeholder: .zero),
        prepareWith: unimplemented("\(Self.self).prepareWith"),
        start: unimplemented("\(Self.self).start"),
        stop: unimplemented("\(Self.self).stop"),
        getConfirmedBalance: unimplemented("\(Self.self).getConfirmedBalance", placeholder: DrkAmount(0)),
        getUnifiedAddress: unimplemented("\(Self.self).getUnifiedAddress"),
        getAddress: unimplemented("\(Self.self).getAddress"),
        generateNewAddress: unimplemented("\(Self.self).generateNewAddress"),
        getAllTransactions: unimplemented("\(Self.self).getAllTransactions"),
        proposeTransfer: unimplemented("\(Self.self).proposeTransfer"),
        estimateFee: unimplemented("\(Self.self).estimateFee", placeholder: DrkAmount(10_000)),
        sendTransaction: unimplemented("\(Self.self).sendTransaction"),
        getTransactionMemo: unimplemented("\(Self.self).getTransactionMemo"),
        getTransactionRecipient: unimplemented("\(Self.self).getTransactionRecipient"),
        listDaos: unimplemented("\(Self.self).listDaos"),
        listProposals: unimplemented("\(Self.self).listProposals"),
        getProposal: unimplemented("\(Self.self).getProposal"),
        wipe: unimplemented("\(Self.self).wipe"),
        rewind: unimplemented("\(Self.self).rewind"),
        listTokenBalances: unimplemented("\(Self.self).listTokenBalances")
    )

    /// Test/preview client that does not emit synchronizer stream updates.
    public static let inert = SDKSynchronizerClient(
        stateStream: { Empty().eraseToAnyPublisher() },
        latestState: { .zero },
        prepareWith: { _, _, _ in },
        start: { _ in },
        stop: { },
        getConfirmedBalance: { DrkAmount(0) },
        getUnifiedAddress: { _ in nil },
        getAddress: { nil },
        generateNewAddress: { "" },
        getAllTransactions: { [] },
        proposeTransfer: { _, _, _, _ in Proposal(estimatedFee: 10_000) },
        estimateFee: { _, _ in 10_000 },
        sendTransaction: { _, _, _, _ in DarkfiTransactionOverview.mocks[0] },
        getTransactionMemo: { _ in nil },
        getTransactionRecipient: { _ in nil },
        listDaos: { [] },
        listProposals: { _ in [] },
        getProposal: { _ in nil },
        wipe: { },
        rewind: {
            Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
        },
        listTokenBalances: { [] }
    )

    /// Preview/mock value with sample data
    public static func mock(
        balance: DrkAmount = 1_2345_0000, // 1.2345 DRK
        transactions: [DarkfiTransactionOverview] = DarkfiTransactionOverview.mocks
    ) -> SDKSynchronizerClient {
        Self(
            stateStream: {
                Just(SynchronizerState(
                    syncStatus: .synced,
                    confirmedBalance: balance,
                    latestBlockHeight: 100_000
                ))
                .eraseToAnyPublisher()
            },
            latestState: {
                SynchronizerState(
                    syncStatus: .synced,
                    confirmedBalance: balance,
                    latestBlockHeight: 100_000
                )
            },
            prepareWith: { _, _, _ in },
            start: { _ in },
            stop: { },
            getConfirmedBalance: { balance },
            getUnifiedAddress: { _ in
                DarkfiAddress(stringEncoded: "darkfi1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqxpreview")
            },
            getAddress: {
                DarkfiAddress(stringEncoded: "darkfi1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqxpreview")
            },
            generateNewAddress: { "darkfi1new_preview_address" },
            getAllTransactions: { transactions },
            proposeTransfer: { _, _, _, _ in
                Proposal(estimatedFee: 10_000)
            },
            estimateFee: { _, _ in 10_000 },
            sendTransaction: { _, amount, recipient, memo in
                let recipientAddr: String? = {
                    if case let .address(addr) = recipient { return addr }
                    return nil
                }()
                return DarkfiTransactionOverview(
                    rawId: UUID().uuidString,
                    timestampEpochSeconds: Date().timeIntervalSince1970,
                    totalAtomicValue: amount,
                    fee: 10_000,
                    isSending: true,
                    status: "Broadcasted",
                    contractSummary: "Money::TransferV1",
                    recipientAddress: recipientAddr,
                    memo: memo?.text
                )
            },
            getTransactionMemo: { _ in nil },
            getTransactionRecipient: { _ in nil },
            listDaos: { [] },
            listProposals: { _ in [] },
            getProposal: { _ in nil },
            wipe: { },
            rewind: {
                Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
            },
            listTokenBalances: { [] }
        )
    }
}

// MARK: - Mock data

extension DarkfiTransactionOverview {
    public static let mocks: [DarkfiTransactionOverview] = [
        DarkfiTransactionOverview(
            rawId: "tx_001",
            minedHeight: 99_990,
            timestampEpochSeconds: Date().addingTimeInterval(-3600).timeIntervalSince1970,
            totalAtomicValue: 5000_0000,
            fee: 10_000,
            isSending: false,
            status: "Confirmed",
            contractSummary: "Money::TransferV1",
            recipientAddress: "darkfi1...",
            memo: "Payment received"
        ),
        DarkfiTransactionOverview(
            rawId: "tx_002",
            minedHeight: 99_985,
            timestampEpochSeconds: Date().addingTimeInterval(-7200).timeIntervalSince1970,
            totalAtomicValue: 2500_0000,
            fee: 10_000,
            isSending: true,
            status: "Broadcasted",
            contractSummary: "DAO::ProposeV1",
            recipientAddress: nil,
            memo: nil
        ),
        DarkfiTransactionOverview(
            rawId: "tx_003",
            minedHeight: 99_950,
            timestampEpochSeconds: Date().addingTimeInterval(-86400).timeIntervalSince1970,
            totalAtomicValue: 10_0000_0000,
            fee: 10_000,
            isSending: false,
            status: "Reverted",
            contractSummary: "Money::TransferV1",
            recipientAddress: nil,
            memo: "Welcome to DarkFi"
        )
    ]
}
