//
//  DaoHub.swift
//  stealth
//
//  DAO Hub reducer — read-only governance browser (M1).
//  Matches Android's DaoViewModel + DaoScreens.
//  All data is fetched from the Rust core via DarkfiWalletHandle.
//

import ComposableArchitecture
import Foundation
import SDKSynchronizer

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
        
        public init() {}
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
    }
    
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear, .loadHub:
                state.isLoading = true
                state.errorMessage = nil
                state.screen = .hub
                return .run { send in
                    do {
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
                // Find dao from loaded list
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
            }
        }
    }
    
    public init() {}
}
