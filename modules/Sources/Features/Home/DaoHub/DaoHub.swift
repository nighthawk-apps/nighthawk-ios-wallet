//
//  DaoHub.swift
//  stealth
//
//  DAO Hub reducer — governance browser with propose + vote support.
//  Matches Android's DaoViewModel + DaoScreens.
//  All data is fetched from the Rust core via DarkfiWalletHandle.
//

import ComposableArchitecture
import Foundation
import SDKSynchronizer
import Utils

@Reducer
public struct DaoHub {
    @ObservableState
    public struct State: Equatable {
        // ── Navigation ─────────────────────────────────────────────────

        public enum Screen: Equatable {
            case hub
            case daoDetail(String)
            case proposalDetail(String)
        }

        public var screen: Screen = .hub
        public var isLoading: Bool = false
        public var errorMessage: String?

        // Hub
        public var daos: [DaoBrief] = []

        // DAO Detail
        public var selectedDao: DaoBrief?
        public var proposals: [ProposalBrief] = []

        // Proposal Detail
        public var proposalDetail: ProposalFull?

        // ── Action state ────────────────────────────────────────────────
        public var actionInProgress: Bool = false
        public var actionResult: ActionResult?

        // ── Propose form ────────────────────────────────────────────────
        public var showProposeSheet: Bool = false
        public var proposeRecipient: String = ""
        public var proposeAmount: String = ""
        public var proposeTokenId: String = ""
        public var proposeDuration: String = "10"

        public init() {}
    }

    public enum ActionResult: Equatable {
        case success(String)
        case error(String)
    }

    public enum Action: Equatable {
        case onAppear
        case loadHub
        case hubLoaded([DaoBrief])
        case daoSelected(String)
        case daoLoaded(DaoBrief?, [ProposalBrief])
        case proposalSelected(String)
        case proposalLoaded(ProposalFull?)
        case backTapped
        case errorOccurred(String)

        // ── Propose ─────────────────────────────────────────────────────
        case showProposeSheet
        case dismissProposeSheet
        case setProposeRecipient(String)
        case setProposeAmount(String)
        case setProposeTokenId(String)
        case setProposeDuration(String)
        case submitProposal
        case proposalSubmitted(ActionResult)

        // ── Vote ────────────────────────────────────────────────────────
        case voteYes(String)
        case voteNo(String)
        case voteSubmitted(ActionResult)

        case clearActionResult
    }

    @Dependency(\.sdkSynchronizer) var sdkSynchronizer

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear, .loadHub:
                guard sdkSynchronizer.isWalletPrepared() else {
                    state.isLoading = false
                    state.errorMessage = Self.walletNotReadyMessage(for: .unprepared)
                    return .none
                }

                let syncStatus = sdkSynchronizer.latestState().syncStatus
                switch syncStatus {
                case .unprepared, .stopped:
                    state.isLoading = false
                    state.errorMessage = Self.walletNotReadyMessage(for: syncStatus)
                    return .none
                case .syncing, .upToDate, .error:
                    break
                }

                state.isLoading = true
                state.errorMessage = nil
                state.screen = .hub
                return .run { send in
                    do {
                        try await sdkSynchronizer.refreshNow()
                        let daos = try await sdkSynchronizer.listDaos()
                        await send(.hubLoaded(daos))
                    } catch {
                        await send(.errorOccurred(error.localizedDescription))
                    }
                }
            case let .hubLoaded(daos):
                state.isLoading = false
                state.daos = daos
                return .none
            case let .daoSelected(name):
                state.isLoading = true
                state.screen = .daoDetail(name)
                let dao = state.daos.first(where: { $0.name == name })
                return .run { send in
                    do {
                        let proposals = try await sdkSynchronizer.listProposals(name)
                        await send(.daoLoaded(dao, proposals))
                    } catch {
                        await send(.errorOccurred(error.localizedDescription))
                    }
                }
            case let .daoLoaded(dao, proposals):
                state.isLoading = false
                state.selectedDao = dao
                state.proposals = proposals
                if dao == nil {
                    state.errorMessage = "DAO not found"
                }
                return .none
            case let .proposalSelected(bulla):
                state.isLoading = true
                state.screen = .proposalDetail(bulla)
                return .run { send in
                    do {
                        let detail = try await sdkSynchronizer.getProposal(bulla)
                        await send(.proposalLoaded(detail))
                    } catch {
                        await send(.errorOccurred(error.localizedDescription))
                    }
                }
            case let .proposalLoaded(detail):
                state.isLoading = false
                state.proposalDetail = detail
                if detail == nil {
                    state.errorMessage = "Proposal not found"
                }
                return .none
            case .backTapped:
                switch state.screen {
                case .proposalDetail:
                    if let dao = state.selectedDao {
                        state.screen = .daoDetail(dao.name)
                    } else {
                        state.screen = .hub
                    }
                case .daoDetail:
                    state.screen = .hub
                case .hub:
                    break
                }
                return .none
            case let .errorOccurred(msg):
                state.isLoading = false
                state.errorMessage = msg
                return .none

            // ── Propose ─────────────────────────────────────────────────────
            case .showProposeSheet:
                state.showProposeSheet = true
                state.proposeRecipient = ""
                state.proposeAmount = ""
                state.proposeTokenId = ""
                state.proposeDuration = "10"
                return .none
            case .dismissProposeSheet:
                state.showProposeSheet = false
                return .none
            case let .setProposeRecipient(v):
                state.proposeRecipient = v
                return .none
            case let .setProposeAmount(v):
                state.proposeAmount = v
                return .none
            case let .setProposeTokenId(v):
                state.proposeTokenId = v
                return .none
            case let .setProposeDuration(v):
                state.proposeDuration = v
                return .none
            case .submitProposal:
                guard let dao = state.selectedDao else { return .none }
                let daoName = dao.name
                let recipient = state.proposeRecipient
                let amount = state.proposeAmount
                let tokenId = state.proposeTokenId.isEmpty ? nil : state.proposeTokenId
                let duration = UInt64(state.proposeDuration) ?? 10
                state.showProposeSheet = false
                state.actionInProgress = true
                state.actionResult = nil
                return .run { send in
                    do {
                        let bulla = try await sdkSynchronizer.daoProposeTransfer(
                            daoName,
                            duration,
                            amount,
                            tokenId,
                            recipient
                        )
                        await send(.proposalSubmitted(.success("Proposal submitted! \(bulla.prefix(16))…")))
                    } catch {
                        await send(.proposalSubmitted(.error(error.localizedDescription)))
                    }
                }
            case let .proposalSubmitted(result):
                state.actionInProgress = false
                state.actionResult = result
                if case .success = result, let dao = state.selectedDao {
                    // Refresh proposals
                    return .run { send in
                        do {
                            let proposals = try await sdkSynchronizer.listProposals(dao.name)
                            await send(.daoLoaded(dao, proposals))
                        } catch {
                            // swallow
                        }
                    }
                }
                return .none

            // ── Vote ────────────────────────────────────────────────────────
            case let .voteYes(bulla):
                state.actionInProgress = true
                state.actionResult = nil
                return .run { send in
                    do {
                        let txHash = try await sdkSynchronizer.daoVote(bulla, true)
                        await send(.voteSubmitted(.success("Vote YES submitted! TX: \(txHash.prefix(16))…")))
                    } catch {
                        await send(.voteSubmitted(.error(error.localizedDescription)))
                    }
                }
            case let .voteNo(bulla):
                state.actionInProgress = true
                state.actionResult = nil
                return .run { send in
                    do {
                        let txHash = try await sdkSynchronizer.daoVote(bulla, false)
                        await send(.voteSubmitted(.success("Vote NO submitted! TX: \(txHash.prefix(16))…")))
                    } catch {
                        await send(.voteSubmitted(.error(error.localizedDescription)))
                    }
                }
            case let .voteSubmitted(result):
                state.actionInProgress = false
                state.actionResult = result
                return .none

            case .clearActionResult:
                state.actionResult = nil
                return .none
            }
        }
    }

    public init() {}
}

private extension DaoHub {
    static func walletNotReadyMessage(for status: DarkfiSyncStatus) -> String {
        switch status {
        case .unprepared:
            return "Wallet is not ready yet. Finish setup or wait for the wallet to initialize."
        case .stopped:
            return "Wallet sync is stopped. Resume sync from the Wallet tab, then open DAO Hub again."
        case .syncing:
            return "Wallet sync is still in progress. Open DAO Hub again once your wallet is up to date."
        case let .error(message):
            return "Wallet sync failed: \(message)"
        case .upToDate:
            return ""
        }
    }
}
