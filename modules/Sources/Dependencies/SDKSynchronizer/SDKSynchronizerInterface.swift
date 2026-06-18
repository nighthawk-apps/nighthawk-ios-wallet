//
//  SDKSynchronizerInterface.swift
//  stealth
//
//  Wallet-facing sync API matching Android DarkfiSynchronizer.
//  All operations route to Rust core via UniFFI.
//

import Combine
import ComposableArchitecture
import Foundation
import Utils

extension DependencyValues {
    public var sdkSynchronizer: SDKSynchronizerClient {
        get { self[SDKSynchronizerClient.self] }
        set { self[SDKSynchronizerClient.self] = newValue }
    }
}

/// Matches Android `DarkfiSynchronizer` interface.
/// Balance is a single atomic DRK value from the DarkFi wallet layer
/// (no transparent vs shielded split — all consensus transfers are private).
public struct SDKSynchronizerClient {
    // MARK: - Streams

    /// Synchronizer state stream (status + balance + block height)
    public var stateStream: () -> AnyPublisher<SynchronizerState, Never>

    /// Get the latest synchronizer state (snapshot)
    public var latestState: () -> SynchronizerState

    // MARK: - Lifecycle

    /// Prepare the synchronizer (init wallet from seed)
    public var prepareWith: ([UInt8], BlockHeight, WalletInitMode) async throws -> Void

    /// Start syncing
    public var start: (_ retry: Bool) async throws -> Void

    /// Stop syncing
    public var stop: () -> Void

    /// Whether the Rust wallet handle was created (prepare succeeded).
    public var isWalletPrepared: () -> Bool

    /// Scan blocks from darkfid and refresh local wallet state (required before DAO list is current).
    public var refreshNow: () async throws -> Void

    // MARK: - Balance (single atomic value from Rust)

    /// Confirmed spendable balance in smallest DRK units
    public var getConfirmedBalance: () -> DrkAmount

    // MARK: - Address (single privacy address from Rust)

    /// Get the wallet's DarkFi privacy address (account-based)
    public var getUnifiedAddress: (_ account: Int) async throws -> UnifiedAddress?

    /// Convenience: get address for default account (0)
    public var getAddress: () async throws -> DarkfiAddress?
    
    /// Generate a new derived address
    public var generateNewAddress: () async throws -> String

    // MARK: - Transactions (from Rust core)

    /// Get all transactions
    public var getAllTransactions: () async throws -> [DarkfiTransactionOverview]

    /// Propose a transfer (estimate fees, validate) before sending
    public var proposeTransfer: (Int, Recipient, DrkAmount, Memo?) async throws -> Proposal

    /// Estimate fee for a transfer
    public var estimateFee: (DarkfiAddress, DrkAmount) async throws -> DrkAmount

    // MARK: - Send (via Rust core `drk` plugin)

    /// Send a transaction. Accepts spending key, amount, recipient, memo.
    public var sendTransaction: (Any, DrkAmount, Recipient, Memo?) async throws -> DarkfiTransactionOverview

    // MARK: - Transaction details

    /// Retrieve decrypted payment memo for a transaction
    public var getTransactionMemo: (_ txHash: String) async throws -> String?
    
    /// Retrieve recipient address for a transaction
    public var getTransactionRecipient: (_ txHash: String) async throws -> String?

    // MARK: - DAO Hub (read-only governance)

    /// List all DAOs the wallet is aware of
    public var listDaos: () async throws -> [DaoBrief]
    
    /// List proposals for a DAO (or all DAOs if name is nil)
    public var listProposals: (_ daoName: String?) async throws -> [ProposalBrief]
    
    /// Get full detail for a specific proposal
    public var getProposal: (_ proposalBullaB58: String) async throws -> ProposalFull?

    // MARK: - Wallet management

    /// Wipe wallet data
    public var wipe: () async throws -> Void

    /// Rewind the wallet
    public var rewind: () -> AnyPublisher<Void, Error>
    
    // MARK: - Token balances
    
    /// List all token balances in the wallet (DRK native + any custom tokens)
    public var listTokenBalances: () async throws -> [TokenBalanceInfo]
}

// MARK: - DAO Hub models (thin wrappers for UI)

public struct DaoBrief: Equatable, Identifiable {
    public let id: String
    public let name: String
    public let bullaB58: String
    public let govTokenId: String
    public let quorumDisplay: String
    public let proposerLimitDisplay: String
    public let approvalRatioPercent: Double
    public let mintHeight: Int64?
    public let canPropose: Bool
    public let canVote: Bool
    public let canExec: Bool
    
    public init(
        name: String, bullaB58: String, govTokenId: String,
        quorumDisplay: String, proposerLimitDisplay: String,
        approvalRatioPercent: Double, mintHeight: Int64?,
        canPropose: Bool, canVote: Bool, canExec: Bool
    ) {
        self.id = bullaB58
        self.name = name
        self.bullaB58 = bullaB58
        self.govTokenId = govTokenId
        self.quorumDisplay = quorumDisplay
        self.proposerLimitDisplay = proposerLimitDisplay
        self.approvalRatioPercent = approvalRatioPercent
        self.mintHeight = mintHeight
        self.canPropose = canPropose
        self.canVote = canVote
        self.canExec = canExec
    }
}

public struct ProposalBrief: Equatable, Identifiable {
    public let id: String
    public let proposalBullaB58: String
    public let daoName: String
    public let daoBullaB58: String
    public let authCallCount: Int
    public let durationBlockwindows: Int64
    public let creationBlockwindow: Int64
    public let mintHeight: Int64?
    public let execHeight: Int64?
    public let isExecuted: Bool
    public let summaryLine: String
    
    public init(
        proposalBullaB58: String, daoName: String, daoBullaB58: String,
        authCallCount: Int, durationBlockwindows: Int64, creationBlockwindow: Int64,
        mintHeight: Int64?, execHeight: Int64?, isExecuted: Bool, summaryLine: String
    ) {
        self.id = proposalBullaB58
        self.proposalBullaB58 = proposalBullaB58
        self.daoName = daoName
        self.daoBullaB58 = daoBullaB58
        self.authCallCount = authCallCount
        self.durationBlockwindows = durationBlockwindows
        self.creationBlockwindow = creationBlockwindow
        self.mintHeight = mintHeight
        self.execHeight = execHeight
        self.isExecuted = isExecuted
        self.summaryLine = summaryLine
    }
}

public struct ProposalFull: Equatable {
    public let brief: ProposalBrief
    public let proposeTxHash: String?
    public let execTxHash: String?
    public let hasPlaintextData: Bool
    
    public init(brief: ProposalBrief, proposeTxHash: String?, execTxHash: String?, hasPlaintextData: Bool) {
        self.brief = brief
        self.proposeTxHash = proposeTxHash
        self.execTxHash = execTxHash
        self.hasPlaintextData = hasPlaintextData
    }
}

/// Token balance info for UI (wraps FFI DrkTokenBalance)
public struct TokenBalanceInfo: Equatable, Identifiable {
    public let id: String
    public let tokenId: String
    public let displayLabel: String?
    public let balanceAtomic: Int64
    
    public var balanceFormatted: String {
        let drk = Double(balanceAtomic) / 100_000_000.0
        return String(format: "%.8f", drk)
    }
    
    public init(tokenId: String, displayLabel: String?, balanceAtomic: Int64) {
        self.id = tokenId
        self.tokenId = tokenId
        self.displayLabel = displayLabel
        self.balanceAtomic = balanceAtomic
    }
}
