//
//  DaoHubView.swift
//  stealth
//
//  DAO Hub screens — matches Android's DaoScreens.kt
//  Hub list → DAO detail → Proposal detail
//

import ComposableArchitecture
import Generated
import SDKSynchronizer
import SwiftUI
import UIComponents

public struct DaoHubView: View {
    let store: StoreOf<DaoHub>
    
    public init(store: StoreOf<DaoHub>) {
        self.store = store
    }
    
    public var body: some View {
        Group {
            switch store.screen {
            case .hub:
                hubScreen
            case .daoDetail:
                daoDetailScreen
            case .proposalDetail:
                proposalDetailScreen
            }
        }
        .onAppear { store.send(.onAppear) }
        .applyNighthawkBackground()
    }
}

// MARK: - Hub Screen
private extension DaoHubView {
    var hubScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                daoScaffoldHeader(title: "DAO Hub")
                
                if store.isLoading {
                    daoLoading
                } else if let error = store.errorMessage {
                    daoMessage(error)
                } else if store.daos.isEmpty {
                    daoMessage("No DAOs found for this wallet. Import a wallet that participates in a DAO, or wait for sync to finish.")
                } else {
                    Text("Governance imported with your wallet. Voting and execution arrive in a later release.")
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                        .padding(.horizontal)
                    
                    ForEach(store.daos) { dao in
                        daoRow(dao)
                            .onTapGesture { store.send(.daoSelected(dao.name)) }
                    }
                }
            }
        }
    }
    
    func daoRow(_ dao: DaoBrief) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(dao.name)
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
                .foregroundColor(Asset.Colors.Nighthawk.peach.color)
            
            Text("Quorum \(dao.quorumDisplay) · Approval \(String(format: "%.0f", dao.approvalRatioPercent))%")

                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
            
            Divider().overlay(Asset.Colors.Nighthawk.navy.color)
        }
        .padding(.horizontal)
        .contentShape(Rectangle())
    }
}

// MARK: - DAO Detail Screen
private extension DaoHubView {
    var daoDetailScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                daoScaffoldHeader(title: store.selectedDao?.name ?? "DAO")
                
                if store.isLoading {
                    daoLoading
                } else if let error = store.errorMessage {
                    daoMessage(error)
                } else if let dao = store.selectedDao {
                    // DAO Parameters Card
                    daoParamsCard(dao)
                    
                    // Proposals section
                    Text("Proposals")
                        .font(.custom(FontFamily.PulpDisplay.bold.name, size: 18))
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    if store.proposals.isEmpty {
                        Text("No proposals for this DAO.")
                            .font(.custom(FontFamily.PulpDisplay.regular.name, size: 14))
                            .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                            .padding(.horizontal)
                    } else {
                        ForEach(store.proposals) { proposal in
                            proposalRow(proposal)
                                .onTapGesture { store.send(.proposalSelected(proposal.proposalBullaB58)) }
                        }
                    }
                } else {
                    daoMessage("DAO not found")
                }
            }
        }
    }
    
    func daoParamsCard(_ dao: DaoBrief) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            detailLine(label: "Governance token", value: dao.govTokenId)
            detailLine(label: "Quorum", value: dao.quorumDisplay)
            detailLine(label: "Proposer limit", value: dao.proposerLimitDisplay)
            detailLine(label: "Approval ratio", value: "\(String(format: "%.0f", dao.approvalRatioPercent))%")
            if let h = dao.mintHeight {
                detailLine(label: "Mint height", value: "\(h)")
            }
            detailLine(label: "Your roles", value: rolesLabel(for: dao))
            
            Divider().overlay(Asset.Colors.Nighthawk.navy.color)
        }
        .padding(.horizontal)
    }
    
    func proposalRow(_ proposal: ProposalBrief) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(statusLabel(for: proposal))
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 15))
                .foregroundColor(proposalStatusColor(statusLabel(for: proposal)))
            
            Text(proposal.summaryLine)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
            
            Divider().overlay(Asset.Colors.Nighthawk.navy.color)
        }
        .padding(.horizontal)
        .contentShape(Rectangle())
    }
}

// MARK: - Proposal Detail Screen
private extension DaoHubView {
    var proposalDetailScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                daoScaffoldHeader(title: "Proposal")
                
                if store.isLoading {
                    daoLoading
                } else if let error = store.errorMessage {
                    daoMessage(error)
                } else if let detail = store.proposalDetail {
                    let p = detail.brief
                    detailLine(label: "DAO", value: p.daoName)
                    detailLine(label: "Status", value: statusLabel(for: p))
                    detailLine(label: "Auth calls", value: "\(p.authCallCount)")
                    detailLine(label: "Duration (blocks)", value: "\(p.durationBlockwindows)")
                    if let h = p.mintHeight {
                        detailLine(label: "Mint height", value: "\(h)")
                    }
                    if let h = p.execHeight {
                        detailLine(label: "Exec height", value: "\(h)")
                    }
                    if let tx = detail.proposeTxHash {
                        detailLine(label: "Propose tx", value: tx)
                    }
                    if let tx = detail.execTxHash {
                        detailLine(label: "Exec tx", value: tx)
                    }
                    
                    Text("Read-only preview (M1). Propose, vote, and execute will be enabled after testnet validation.")
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                        .padding(.top, 12)
                } else {
                    daoMessage("Proposal not found")
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Shared Components
private extension DaoHubView {
    func daoScaffoldHeader(title: String) -> some View {
        HStack {
            if store.screen != .hub {
                Button(action: { store.send(.backTapped) }) {
                    Asset.Assets.Icons.Nighthawk.chevronLeft.image
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                }
            }
            
            Text(title)
                .font(.custom(FontFamily.PulpDisplay.bold.name, size: 24))
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }
    
    var daoLoading: some View {
        HStack {
            Spacer()
            ProgressView()
                .tint(Asset.Colors.Nighthawk.peach.color)
                .frame(height: 120)
            Spacer()
        }
    }
    
    func daoMessage(_ text: String) -> some View {
        Text(text)
            .font(.custom(FontFamily.PulpDisplay.regular.name, size: 14))
            .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
            .padding(.horizontal)
    }
    
    func detailLine(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
            Text(value)
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 14))
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
    
    func proposalStatusColor(_ status: String) -> Color {
        switch status {
        case "Executed": return .green
        case "Active": return Asset.Colors.Nighthawk.peach.color
        default: return Asset.Colors.Nighthawk.parmaviolet.color
        }
    }
    
    func rolesLabel(for dao: DaoBrief) -> String {
        var roles: [String] = []
        if dao.canPropose { roles.append("Proposer") }
        if dao.canVote { roles.append("Voter") }
        if dao.canExec { roles.append("Executor") }
        return roles.isEmpty ? "None" : roles.joined(separator: ", ")
    }
    
    func statusLabel(for p: ProposalBrief) -> String {
        if p.isExecuted { return "Executed" }
        if p.mintHeight != nil { return "Active" }
        return "Pending"
    }
}
