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
import Generated
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
        public var treasuryLine: String = L10n.Nighthawk.DaoHub.notScannedYet
        public var mintAuthorities: [MintAuthorityBrief] = []
        public var tokenBalances: [TokenBalanceInfo] = []
        public var roleExport: String?
        public var showProposeSheet: Bool = false
        public var showFundSheet: Bool = false
        public var fundAmount: String = ""
        public var fundTokenId: String?
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

    public enum Refresh: Equatable {
        case none
        case hub
        case proposals
        case treasury
        case authorities
        case governance
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
        case showFundSheet
        case dismissFundSheet
        case setFundAmount(String)
        case setFundTokenId(String?)
        case tokenBalancesLoaded([TokenBalanceInfo])
        case submitFund
        case treasuryLoaded(String)
        case authoritiesLoaded([MintAuthorityBrief])
        case proposalsRefreshed([ProposalBrief])
        case proposalRefreshed(ProposalFull)
        case payFromTreasury(String)
        case submitCreate(String, String, String, String, Double, String)
        case submitImport(String, String)
        case exportRole(String)
        case roleExported(String)
        case clearRoleExport
        case submitIssue(String, String, String)
        case submitMint(String, String, String)
        case submitFreeze(String)
        case setProposeRecipient(String)
        case setProposeAmount(String)
        case setProposeTokenId(String)
        case setProposeDuration(String)
        case submitProposal
        case proposalSubmitted(ActionResult, Refresh)

        // ── Vote ────────────────────────────────────────────────────────
        case voteYes(String)
        case voteNo(String)
        case voteSubmitted(ActionResult)

        case clearActionResult
    }

    private enum CancelID: Hashable {
        case daoLoad
        case daoResources
        case proposalLoad
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
                state.proposals = []
                state.treasuryLine = L10n.Nighthawk.DaoHub.notScannedYet
                state.mintAuthorities = []
                let dao = state.daos.first(where: { $0.name == name })
                return .concatenate(
                    .cancel(id: CancelID.daoLoad),
                    .cancel(id: CancelID.daoResources),
                    .run { send in
                        do {
                            let proposals = try await sdkSynchronizer.listProposals(name)
                            await send(.daoLoaded(dao, proposals))
                        } catch {
                            await send(.errorOccurred(error.localizedDescription))
                        }
                    }
                    .cancellable(id: CancelID.daoLoad, cancelInFlight: true)
                )
            case let .daoLoaded(dao, proposals):
                state.isLoading = false
                state.selectedDao = dao
                state.proposals = proposals
                if dao == nil {
                    state.errorMessage = L10n.Nighthawk.DaoHub.daoNotFound
                    return .none
                }
                let name = dao?.name ?? ""
                return loadDaoResources(name)
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
                .cancellable(id: CancelID.proposalLoad, cancelInFlight: true)
            case let .proposalLoaded(detail):
                state.isLoading = false
                state.proposalDetail = detail
                if detail == nil {
                    state.errorMessage = L10n.Nighthawk.DaoHub.proposalNotFound
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
            case .showFundSheet:
                state.showFundSheet = true
                state.fundAmount = ""
                state.fundTokenId = nil
                return .run { send in
                    let balances = (try? await sdkSynchronizer.listTokenBalances()) ?? []
                    await send(.tokenBalancesLoaded(balances))
                }
            case .dismissFundSheet:
                state.showFundSheet = false
                return .none
            case let .setFundAmount(value):
                state.fundAmount = value
                return .none
            case let .setFundTokenId(tokenId):
                state.fundTokenId = tokenId
                return .none
            case let .tokenBalancesLoaded(balances):
                state.tokenBalances = balances
                return .none
            case .submitFund:
                guard !state.actionInProgress else { return .none }
                guard let dao = state.selectedDao else { return .none }
                guard let amount = DaoDecimalInput.normalizedPositive(state.fundAmount) else { return .none }
                let name = dao.name
                let tokenId = state.fundTokenId
                state.showFundSheet = false
                state.actionInProgress = true
                state.actionResult = nil
                return .run { send in
                    do {
                        _ = try await sdkSynchronizer.daoFund(name, amount, tokenId)
                        await send(.proposalSubmitted(.success(L10n.Nighthawk.DaoHub.fundsSent), .treasury))
                    } catch {
                        await send(.proposalSubmitted(.error(error.localizedDescription), .none))
                    }
                }
            case let .treasuryLoaded(line):
                state.treasuryLine = line
                return .none
            case let .authoritiesLoaded(authorities):
                state.mintAuthorities = authorities
                return .none
            case let .proposalsRefreshed(proposals):
                state.proposals = proposals
                return .none
            case let .proposalRefreshed(detail):
                state.proposalDetail = detail
                return .none
            case let .payFromTreasury(bulla):
                guard !state.actionInProgress else { return .none }
                state.actionInProgress = true
                state.actionResult = nil
                return .run { send in
                    do {
                        _ = try await sdkSynchronizer.daoExec(bulla)
                        await send(.voteSubmitted(.success(L10n.Nighthawk.DaoHub.paymentSent)))
                    } catch {
                        await send(.voteSubmitted(.error(error.localizedDescription)))
                    }
                }
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
                guard !state.actionInProgress else { return .none }
                guard let dao = state.selectedDao else { return .none }
                guard DaoDecimalInput.normalizedPositive(state.proposeAmount) != nil else { return .none }
                let daoName = dao.name
                let recipient = state.proposeRecipient
                let amount = DaoDecimalInput.normalizedPositive(state.proposeAmount) ?? state.proposeAmount
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
                        await send(.proposalSubmitted(
                            .success(L10n.Nighthawk.DaoHub.proposalSubmitted(String(bulla.prefix(16)))),
                            .proposals
                        ))
                    } catch {
                        await send(.proposalSubmitted(.error(error.localizedDescription), .none))
                    }
                }
            case let .submitCreate(name, limit, quorum, early, ratio, token):
                guard !state.actionInProgress else { return .none }
                let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedName.isEmpty,
                      let proposerLimit = DaoDecimalInput.normalizedPositive(limit),
                      let quorumValue = DaoDecimalInput.normalizedPositive(quorum),
                      ratio > 0, ratio <= 1
                else { return .none }
                let earlyTrimmed = early.trimmingCharacters(in: .whitespacesAndNewlines)
                let earlyValue: String
                if earlyTrimmed.isEmpty {
                    earlyValue = quorumValue
                } else if let parsed = DaoDecimalInput.normalizedPositive(earlyTrimmed) {
                    earlyValue = parsed
                } else {
                    return .none
                }
                let tokenValue = token.trimmingCharacters(in: .whitespacesAndNewlines)
                let govToken = tokenValue.isEmpty ? "DRK" : tokenValue
                state.actionInProgress = true
                state.actionResult = nil
                return .run { send in
                    do {
                        _ = try await sdkSynchronizer.daoCreate(
                            trimmedName, proposerLimit, quorumValue, earlyValue, ratio, govToken
                        )
                        await send(.proposalSubmitted(.success(L10n.Nighthawk.DaoHub.groupSubmitted), .hub))
                    } catch {
                        await send(.proposalSubmitted(.error(error.localizedDescription), .none))
                    }
                }
            case let .submitImport(name, toml):
                guard !state.actionInProgress else { return .none }
                let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedToml = toml.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedName.isEmpty, !trimmedToml.isEmpty else { return .none }
                state.actionInProgress = true
                state.actionResult = nil
                return .run { send in
                    do {
                        _ = try await sdkSynchronizer.daoImport(trimmedName, trimmedToml)
                        await send(.proposalSubmitted(.success(L10n.Nighthawk.DaoHub.groupImported), .hub))
                    } catch {
                        await send(.proposalSubmitted(.error(error.localizedDescription), .none))
                    }
                }
            case let .exportRole(role):
                guard let dao = state.selectedDao else { return .none }
                let name = dao.name
                return .run { send in
                    do {
                        let payload = try await sdkSynchronizer.daoExportRole(name, role)
                        await send(.roleExported(payload))
                    } catch {
                        await send(.proposalSubmitted(.error(error.localizedDescription), .none))
                    }
                }
            case let .roleExported(payload):
                state.roleExport = payload
                return .none
            case .clearRoleExport:
                state.roleExport = nil
                return .none
            case let .submitIssue(alias, amount, recipient):
                guard !state.actionInProgress else { return .none }
                guard let amountValue = DaoDecimalInput.normalizedPositive(amount) else { return .none }
                let recipientValue = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !recipientValue.isEmpty else { return .none }
                let aliasValue = alias.trimmingCharacters(in: .whitespacesAndNewlines)
                state.actionInProgress = true
                state.actionResult = nil
                return .run { send in
                    do {
                        let tokenId = try await sdkSynchronizer.tokenGenerate(aliasValue.isEmpty ? nil : aliasValue)
                        _ = try await sdkSynchronizer.tokenMint(tokenId, amountValue, recipientValue)
                        await send(.proposalSubmitted(.success(L10n.Nighthawk.DaoHub.tokenCreated), .authorities))
                    } catch {
                        await send(.proposalSubmitted(.error(error.localizedDescription), .none))
                    }
                }
            case let .submitMint(tokenId, amount, recipient):
                guard !state.actionInProgress else { return .none }
                guard let amountValue = DaoDecimalInput.normalizedPositive(amount) else { return .none }
                let recipientValue = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !tokenId.isEmpty, !recipientValue.isEmpty else { return .none }
                state.actionInProgress = true
                state.actionResult = nil
                return .run { send in
                    do {
                        _ = try await sdkSynchronizer.tokenMint(tokenId, amountValue, recipientValue)
                        await send(.proposalSubmitted(.success(L10n.Nighthawk.DaoHub.tokensIssued), .authorities))
                    } catch {
                        await send(.proposalSubmitted(.error(error.localizedDescription), .none))
                    }
                }
            case let .submitFreeze(tokenId):
                guard !state.actionInProgress else { return .none }
                guard !tokenId.isEmpty else { return .none }
                state.actionInProgress = true
                state.actionResult = nil
                return .run { send in
                    do {
                        _ = try await sdkSynchronizer.tokenFreeze(tokenId)
                        await send(.proposalSubmitted(.success(L10n.Nighthawk.DaoHub.supplyFrozen), .authorities))
                    } catch {
                        await send(.proposalSubmitted(.error(error.localizedDescription), .none))
                    }
                }
            case let .proposalSubmitted(result, refresh):
                state.actionInProgress = false
                state.actionResult = result
                guard case .success = result else { return .none }
                return followUp(refresh, state: state)

            // ── Vote ────────────────────────────────────────────────────────
            case let .voteYes(bulla):
                guard !state.actionInProgress else { return .none }
                state.actionInProgress = true
                state.actionResult = nil
                return .run { send in
                    do {
                        let txHash = try await sdkSynchronizer.daoVote(bulla, true)
                        await send(.voteSubmitted(.success(L10n.Nighthawk.DaoHub.voteYesSubmitted(String(txHash.prefix(16))))))
                    } catch {
                        await send(.voteSubmitted(.error(error.localizedDescription)))
                    }
                }
            case let .voteNo(bulla):
                guard !state.actionInProgress else { return .none }
                state.actionInProgress = true
                state.actionResult = nil
                return .run { send in
                    do {
                        let txHash = try await sdkSynchronizer.daoVote(bulla, false)
                        await send(.voteSubmitted(.success(L10n.Nighthawk.DaoHub.voteNoSubmitted(String(txHash.prefix(16))))))
                    } catch {
                        await send(.voteSubmitted(.error(error.localizedDescription)))
                    }
                }
            case let .voteSubmitted(result):
                state.actionInProgress = false
                state.actionResult = result
                guard case .success = result else { return .none }
                return followUp(.governance, state: state)

            case .clearActionResult:
                state.actionResult = nil
                return .none
            }
        }
    }

    public init() {}

    private func followUp(_ refresh: Refresh, state: State) -> Effect<Action> {
        switch refresh {
        case .none:
            return .none
        case .hub:
            return .send(.loadHub)
        case .proposals:
            guard let dao = state.selectedDao else { return .none }
            return refreshProposals(dao.name)
        case .treasury:
            guard let dao = state.selectedDao else { return .none }
            return refreshTreasury(dao.name)
        case .authorities:
            return refreshAuthorities()
        case .governance:
            let daoName = state.selectedDao?.name
            let bulla: String?
            if case let .proposalDetail(id) = state.screen {
                bulla = id
            } else {
                bulla = nil
            }
            return refreshGovernance(daoName: daoName, proposalBulla: bulla)
        }
    }

    private func loadDaoResources(_ name: String) -> Effect<Action> {
        let sdk = sdkSynchronizer
        return .run { send in
            let line = (try? await sdk.daoTreasury(name)) ?? L10n.Nighthawk.DaoHub.notScannedYet
            await send(.treasuryLoaded(line))
            let authorities = (try? await sdk.listMintAuthorities()) ?? []
            await send(.authoritiesLoaded(authorities))
        }
        .cancellable(id: CancelID.daoResources, cancelInFlight: true)
    }

    private func refreshProposals(_ name: String) -> Effect<Action> {
        let sdk = sdkSynchronizer
        return .run { send in
            if let proposals = try? await sdk.listProposals(name) {
                await send(.proposalsRefreshed(proposals))
            }
        }
        .cancellable(id: CancelID.daoResources, cancelInFlight: true)
    }

    private func refreshTreasury(_ name: String) -> Effect<Action> {
        let sdk = sdkSynchronizer
        return .run { send in
            if let line = try? await sdk.daoTreasury(name) {
                await send(.treasuryLoaded(line))
            }
        }
        .cancellable(id: CancelID.daoResources, cancelInFlight: true)
    }

    private func refreshAuthorities() -> Effect<Action> {
        let sdk = sdkSynchronizer
        return .run { send in
            if let authorities = try? await sdk.listMintAuthorities() {
                await send(.authoritiesLoaded(authorities))
            }
        }
        .cancellable(id: CancelID.daoResources, cancelInFlight: true)
    }

    private func refreshGovernance(daoName: String?, proposalBulla: String?) -> Effect<Action> {
        let sdk = sdkSynchronizer
        return .run { send in
            if let daoName, let proposals = try? await sdk.listProposals(daoName) {
                await send(.proposalsRefreshed(proposals))
            }
            if let daoName, let line = try? await sdk.daoTreasury(daoName) {
                await send(.treasuryLoaded(line))
            }
            if let proposalBulla {
                do {
                    if let detail = try await sdk.getProposal(proposalBulla) {
                        await send(.proposalRefreshed(detail))
                    }
                } catch {
                    // Keep the open proposal if the refresh fails.
                }
            }
        }
        .cancellable(id: CancelID.daoResources, cancelInFlight: true)
    }
}

enum DaoDecimalInput {
    /// Positive finite amount. `.` and `,` are both decimal separators.
    /// Returns a dot-decimal string, or nil when the text is empty or not positive.
    static func normalizedPositive(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let normalized = normalizeSeparators(trimmed) else { return nil }
        guard let value = Double(normalized), value > 0, value.isFinite else { return nil }
        return normalized
    }

    /// Yes-share in (0, 1]. Nil when the text is empty or outside that range.
    static func approvalRatio(_ raw: String) -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let normalized = normalizeSeparators(trimmed) else { return nil }
        guard let value = Double(normalized), value > 0, value <= 1, value.isFinite else { return nil }
        return value
    }

    private static func normalizeSeparators(_ trimmed: String) -> String? {
        var working = trimmed
        if working.contains(","), working.contains(".") {
            guard let lastComma = working.lastIndex(of: ","),
                  let lastDot = working.lastIndex(of: ".")
            else { return nil }
            if lastComma > lastDot {
                working = working.replacingOccurrences(of: ".", with: "")
                working = working.replacingOccurrences(of: ",", with: ".")
            } else {
                working = working.replacingOccurrences(of: ",", with: "")
            }
        } else if working.contains(",") {
            guard working.filter({ $0 == "," }).count == 1 else { return nil }
            working = working.replacingOccurrences(of: ",", with: ".")
        } else if working.filter({ $0 == "." }).count > 1 {
            return nil
        }

        let parts = working.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 1 || parts.count == 2 else { return nil }
        guard parts.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isNumber) }) else { return nil }
        return working
    }
}

private extension DaoHub {
    static func walletNotReadyMessage(for status: DarkfiSyncStatus) -> String {
        switch status {
        case .unprepared:
            return L10n.Nighthawk.DaoHub.walletNotReady
        case .stopped:
            return L10n.Nighthawk.DaoHub.walletStopped
        case .syncing:
            return L10n.Nighthawk.DaoHub.walletSyncing
        case let .error(message):
            return L10n.Nighthawk.DaoHub.walletSyncFailed(message)
        case .upToDate:
            return ""
        }
    }
}
