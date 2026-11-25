//
//  DaoHubView.swift
//  stealth
//
//  DAO Hub screens — matches Android's DaoScreens.kt
//  Hub list → DAO detail (+ propose) → Proposal detail (+ vote)
//

import ComposableArchitecture
import CoreImage.CIFilterBuiltins
import Generated
import SDKSynchronizer
import SwiftUI
import UIComponents
import UIKit

public struct DaoHubView: View {
    let store: StoreOf<DaoHub>
    let showsEmbeddedHeader: Bool
    @State private var showCreate = false
    @State private var showImport = false
    @State private var showIssue = false
    @State private var showAdmin = false
    @State private var showDaoDetails = false
    @State private var showProposalDetails = false
    @State private var mintTarget: MintAuthorityBrief?
    @State private var freezeTarget: MintAuthorityBrief?

    public init(store: StoreOf<DaoHub>, showsEmbeddedHeader: Bool = true) {
        self.store = store
        self.showsEmbeddedHeader = showsEmbeddedHeader
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
        .refreshable {
            await store.send(.loadHub).finish()
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
                // Match Settings / Transfer (Dex) screen-title inset.
                HStack {
                    Text(L10n.Nighthawk.DaoHub.title.uppercased())
                        .title(color: Asset.Colors.Nighthawk.textHeader.color)
                    Spacer()
                }
                .padding(.top, NighthawkLayout.wallpaperWordmarkClearance)
                .padding(.bottom, 13)
                .padding(.horizontal, 25)

                if store.isLoading {
                    daoLoading
                } else if let error = store.errorMessage {
                    daoMessage(error)
                    actionResultBanner
                } else if store.daos.isEmpty {
                    daoEmptyState
                } else {
                    Text(L10n.Nighthawk.DaoHub.hubIntro)
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                        .padding(.horizontal, 25)

                    ForEach(store.daos) { dao in
                        daoRow(dao)
                            .onTapGesture { store.send(.daoSelected(dao.name)) }
                    }

                    groupActions
                    actionResultBanner
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            CreateGroupSheet { name, limit, quorum, early, ratio, token in
                showCreate = false
                store.send(.submitCreate(name, limit, quorum, early, ratio, token))
            }
        }
        .sheet(isPresented: $showImport) {
            ImportGroupSheet { name, toml in
                showImport = false
                store.send(.submitImport(name, toml))
            }
        }
    }

    var groupActions: some View {
        VStack(spacing: 12) {
            Button(L10n.Nighthawk.DaoHub.startGroup) { showCreate = true }
                .buttonStyle(.nighthawkSecondary(width: 280))
                .disabled(store.actionInProgress)
            Button(L10n.Nighthawk.DaoHub.importGroup) { showImport = true }
                .buttonStyle(.nighthawkSecondary(width: 280))
                .disabled(store.actionInProgress)
        }
        .padding(.horizontal)
    }

    var daoEmptyState: some View {
        VStack(spacing: 16) {
            Text(L10n.Nighthawk.DaoHub.emptyTitle)
                .font(.custom(FontFamily.PulpDisplay.bold.name, size: 18))
                .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)

            Text(L10n.Nighthawk.DaoHub.emptyBody)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 14))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button(L10n.Nighthawk.DaoHub.refresh) {
                store.send(.loadHub)
            }
            .buttonStyle(.nighthawkPrimary())
            .disabled(store.actionInProgress)
            .padding(.horizontal)

            groupActions
            actionResultBanner
        }
        .frame(maxWidth: .infinity)
    }

    func daoRow(_ dao: DaoBrief) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(dao.name)
                        .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
                        .foregroundColor(Asset.Colors.Nighthawk.peach.color)

                    Spacer()
                }

                Text(dao.roleLine)
                    .font(.custom(FontFamily.IbmPlexMono.regular.name, size: 13))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
            }
            .padding(.vertical, 14)

            Divider()
                .frame(height: 1)
                .overlay(Asset.Colors.Nighthawk.steelBorder.color)
        }
        .padding(.horizontal, 25)
        .contentShape(Rectangle())
    }
}

// MARK: - DAO Detail Screen
private extension DaoHubView {
    var daoDetailScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if showsEmbeddedHeader {
                    daoScaffoldHeader(title: store.selectedDao?.name ?? L10n.Nighthawk.DaoHub.title)
                        .padding(.top, NighthawkLayout.wallpaperWordmarkClearance)
                }
                if store.isLoading {
                    daoLoading
                } else if let error = store.errorMessage {
                    daoMessage(error)
                } else if let dao = store.selectedDao {
                    Text(L10n.Nighthawk.DaoHub.treasury)
                        .font(.custom(FontFamily.PulpDisplay.bold.name, size: 18))
                        .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                        .padding(.horizontal)
                    Text(store.treasuryLine)
                        .font(.custom(FontFamily.IbmPlexMono.regular.name, size: 14))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                        .padding(.horizontal)
                    Text(L10n.Nighthawk.DaoHub.treasuryHint)
                        .font(.custom(FontFamily.SourceSans3.regular.name, size: 13))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                        .padding(.horizontal)
                    if dao.canPropose {
                        Button(L10n.Nighthawk.DaoHub.proposePayment) { store.send(.showProposeSheet) }
                            .buttonStyle(.nighthawkPrimary())
                            .disabled(store.actionInProgress)
                            .padding(.horizontal)
                    }
                    Button(L10n.Nighthawk.DaoHub.addFunds) { store.send(.showFundSheet) }
                        .buttonStyle(.nighthawkSecondary(width: 280))
                        .disabled(store.actionInProgress)
                        .padding(.horizontal)

                    Text(L10n.Nighthawk.DaoHub.votes)
                        .font(.custom(FontFamily.PulpDisplay.bold.name, size: 18))
                        .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                        .padding(.horizontal)

                    if store.proposals.isEmpty {
                        Text(L10n.Nighthawk.DaoHub.noVotes)
                            .font(.custom(FontFamily.PulpDisplay.regular.name, size: 14))
                            .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                            .padding(.horizontal)
                    } else {
                        ForEach(store.proposals) { proposal in
                            proposalRow(proposal)
                                .onTapGesture { store.send(.proposalSelected(proposal.proposalBullaB58)) }
                        }
                    }

                    Text(L10n.Nighthawk.DaoHub.tokens)
                        .font(.custom(FontFamily.PulpDisplay.bold.name, size: 18))
                        .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                        .padding(.horizontal)
                    Text(dao.govTokenId)
                        .font(.custom(FontFamily.IbmPlexMono.regular.name, size: 13))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                        .padding(.horizontal)
                    ForEach(store.mintAuthorities) { auth in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(auth.alias ?? auth.tokenId)
                                .font(.custom(FontFamily.IbmPlexMono.regular.name, size: 13))
                                .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                            if !auth.frozen {
                                Button(L10n.Nighthawk.DaoHub.issueMore) { mintTarget = auth }
                                    .buttonStyle(.nighthawkSecondary(width: 220))
                                    .disabled(store.actionInProgress)
                                Button(L10n.Nighthawk.DaoHub.freezeSupply) { freezeTarget = auth }
                                    .buttonStyle(.nighthawkSecondary(width: 220))
                                    .disabled(store.actionInProgress)
                            }
                        }
                        .padding(.horizontal)
                    }
                    Button(L10n.Nighthawk.DaoHub.issueToken) { showIssue = true }
                        .buttonStyle(.nighthawkSecondary(width: 280))
                        .disabled(store.actionInProgress)
                        .padding(.horizontal)

                    Button(L10n.Nighthawk.DaoHub.admin) { showAdmin.toggle() }
                        .buttonStyle(.plain)
                        .font(.custom(FontFamily.PulpDisplay.bold.name, size: 18))
                        .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                        .padding(.horizontal)
                    if showAdmin {
                        Text(dao.roleLine)
                            .font(.custom(FontFamily.IbmPlexMono.regular.name, size: 13))
                            .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                            .padding(.horizontal)
                        Button(L10n.Nighthawk.DaoHub.proposer) { store.send(.exportRole("proposer")) }
                            .buttonStyle(.nighthawkSecondary(width: 220))
                            .disabled(store.actionInProgress)
                            .padding(.horizontal)
                        Button(L10n.Nighthawk.DaoHub.voter) { store.send(.exportRole("voter")) }
                            .buttonStyle(.nighthawkSecondary(width: 220))
                            .disabled(store.actionInProgress)
                            .padding(.horizontal)
                        Button(L10n.Nighthawk.DaoHub.executor) { store.send(.exportRole("executor")) }
                            .buttonStyle(.nighthawkSecondary(width: 220))
                            .disabled(store.actionInProgress)
                            .padding(.horizontal)
                        Button(L10n.Nighthawk.DaoHub.fullCopy) { store.send(.exportRole("all")) }
                            .buttonStyle(.nighthawkSecondary(width: 220))
                            .disabled(store.actionInProgress)
                            .padding(.horizontal)
                        Button(L10n.Nighthawk.DaoHub.details) { showDaoDetails.toggle() }
                            .buttonStyle(.nighthawkLink())
                            .padding(.horizontal)
                        if showDaoDetails {
                            daoParamsCard(dao)
                            copyableDetailLine(label: L10n.Nighthawk.DaoHub.groupId, value: dao.bullaB58)
                                .padding(.horizontal)
                        }
                    }

                    actionResultBanner
                } else {
                    daoMessage(L10n.Nighthawk.DaoHub.daoNotFound)
                }
            }
            .padding(.top, 8)
        }
        .sheet(isPresented: Binding(
            get: { store.showProposeSheet },
            set: { _ in store.send(.dismissProposeSheet) }
        )) {
            proposeSheet
        }
        .sheet(isPresented: Binding(
            get: { store.showFundSheet },
            set: { _ in store.send(.dismissFundSheet) }
        )) {
            fundSheet
        }
        .sheet(isPresented: $showIssue) {
            IssueTokenSheet { alias, amount, recipient in
                showIssue = false
                store.send(.submitIssue(alias, amount, recipient))
            }
        }
        .sheet(item: $mintTarget) { auth in
            AmountRecipientSheet(title: L10n.Nighthawk.DaoHub.issueMore, tokenLabel: auth.alias ?? auth.tokenId) { amount, recipient in
                mintTarget = nil
                store.send(.submitMint(auth.tokenId, amount, recipient))
            }
        }
        .alert(
            L10n.Nighthawk.DaoHub.freezeSupply,
            isPresented: Binding(get: { freezeTarget != nil }, set: { if !$0 { freezeTarget = nil } })
        ) {
            Button(L10n.Nighthawk.DaoHub.freezeSupply, role: .destructive) {
                if let token = freezeTarget?.tokenId {
                    store.send(.submitFreeze(token))
                }
                freezeTarget = nil
            }
            .disabled(store.actionInProgress)
            Button(L10n.General.cancel, role: .cancel) { freezeTarget = nil }
        } message: {
            Text(freezeTarget?.tokenId ?? "")
        }
        .sheet(isPresented: Binding(get: { store.roleExport != nil }, set: { if !$0 { store.send(.clearRoleExport) } })) {
            RoleQrSheet(payload: store.roleExport ?? "") {
                store.send(.clearRoleExport)
            }
        }
    }

    func daoParamsCard(_ dao: DaoBrief) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            copyableDetailLine(label: L10n.Nighthawk.DaoHub.governanceToken, value: dao.govTokenId)
            detailLine(label: L10n.Nighthawk.DaoHub.votesNeeded, value: dao.quorumDisplay)
            detailLine(
                label: L10n.Nighthawk.DaoHub.yesShareRequired,
                value: "\(String(format: "%.0f", dao.approvalRatioPercent))%"
            )
            if let h = dao.mintHeight {
                detailLine(label: L10n.Nighthawk.DaoHub.mintHeight, value: "\(h)")
            }

            Text(dao.roleLine)
                .font(.custom(FontFamily.IbmPlexMono.regular.name, size: 13))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)

            Divider().overlay(Asset.Colors.Nighthawk.navy.color)
        }
        .padding(.horizontal)
    }

    func proposalRow(_ proposal: ProposalBrief) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                statusBadge(for: proposal)

                Text(paymentTitle(proposal))
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
            }
            .padding(.vertical, 14)

            Divider()
                .frame(height: 1)
                .overlay(Asset.Colors.Nighthawk.steelBorder.color)
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
                if showsEmbeddedHeader {
                    daoScaffoldHeader(title: L10n.Nighthawk.DaoHub.proposal)
                        .padding(.top, NighthawkLayout.wallpaperWordmarkClearance)
                }
                if store.isLoading {
                    daoLoading
                } else if let error = store.errorMessage {
                    daoMessage(error)
                } else if let detail = store.proposalDetail {
                    let p = detail.brief
                    detailLine(label: L10n.Nighthawk.DaoHub.dao, value: p.daoName)
                    statusBadge(for: p)
                    Text(paymentTitle(p))
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 16))
                        .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                    Text(L10n.Nighthawk.DaoHub.votingWindow(p.durationBlockwindows, p.durationBlockwindows * 4))
                        .font(.custom(FontFamily.SourceSans3.regular.name, size: 13))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    Button(L10n.Nighthawk.DaoHub.details) { showProposalDetails.toggle() }
                        .buttonStyle(.nighthawkLink())
                    if showProposalDetails {
                        copyableDetailLine(label: L10n.Nighthawk.DaoHub.proposalId, value: p.proposalBullaB58)
                        if let h = p.mintHeight {
                            detailLine(label: L10n.Nighthawk.DaoHub.mintHeight, value: "\(h)")
                        }
                        if let h = p.execHeight {
                            detailLine(label: L10n.Nighthawk.DaoHub.execHeight, value: "\(h)")
                        }
                        if let tx = detail.proposeTxHash {
                            copyableDetailLine(label: L10n.Nighthawk.DaoHub.proposeTx, value: tx)
                        }
                        if let tx = detail.execTxHash {
                            copyableDetailLine(label: L10n.Nighthawk.DaoHub.execTx, value: tx)
                        }
                    }

                    if store.selectedDao?.canVote == true && !p.isExecuted && p.mintHeight != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Button(L10n.General.yes) { store.send(.voteYes(p.proposalBullaB58)) }
                                .buttonStyle(.nighthawkPrimary())
                                .disabled(store.actionInProgress)
                            Button(L10n.General.no) { store.send(.voteNo(p.proposalBullaB58)) }
                                .buttonStyle(.nighthawkSecondary())
                                .disabled(store.actionInProgress)
                            Text(L10n.Nighthawk.DaoHub.voteWeight)
                                .font(.custom(FontFamily.SourceSans3.regular.name, size: 12))
                                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                        }
                        .padding(.top, 8)
                    }
                    if store.selectedDao?.canExec == true && !p.isExecuted && p.mintHeight != nil {
                        Button(L10n.Nighthawk.DaoHub.payFromTreasury) { store.send(.payFromTreasury(p.proposalBullaB58)) }
                            .buttonStyle(.nighthawkPrimary())
                            .disabled(store.actionInProgress)
                        Text(L10n.Nighthawk.DaoHub.payHint)
                            .font(.custom(FontFamily.SourceSans3.regular.name, size: 12))
                            .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    }

                    actionResultBanner
                } else {
                    daoMessage(L10n.Nighthawk.DaoHub.proposalNotFound)
                }
            }
            .padding(.top, 8)
            .padding(.horizontal)
        }
    }
}

// MARK: - Shared Components
private extension DaoHubView {
    func daoScaffoldHeader(title: String) -> some View {
        HStack(spacing: 8) {
            if store.screen != .hub {
                Button(action: { store.send(.backTapped) }) {
                    Asset.Assets.Icons.Nighthawk.chevronLeft.image
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 24, height: 24)
                        .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.General.back)
            }

            Text(title)
                .font(.custom(FontFamily.PulpDisplay.bold.name, size: 24))
                .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
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
                .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    func copyableDetailLine(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
            HStack(spacing: 4) {
                Text(value)
                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 14))
                    .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 11))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
            }
            .onTapGesture {
                UIPasteboard.general.setItems(
                    [[UIPasteboard.typeAutomatic: value]],
                    options: [
                        .localOnly: true,
                        .expirationDate: Date().addingTimeInterval(60)
                    ]
                )
            }
        }
    }

    func paymentTitle(_ proposal: ProposalBrief) -> String {
        if let range = proposal.summaryLine.range(of: "Pay ") {
            return String(proposal.summaryLine[range.lowerBound...])
        }
        return L10n.Nighthawk.DaoHub.onePayment
    }

    func statusBadge(for p: ProposalBrief) -> some View {
        let label = statusLabel(for: p)
        let color = Asset.Colors.Nighthawk.parmaviolet.color
        return Text(label)
            .font(.custom(FontFamily.PulpDisplay.medium.name, size: 13))
            .foregroundColor(color)
    }

    func statusLabel(for p: ProposalBrief) -> String {
        if p.isExecuted { return L10n.Nighthawk.DaoHub.paid }
        if p.mintHeight != nil { return L10n.Nighthawk.DaoHub.statusOpen }
        return L10n.Nighthawk.DaoHub.waiting
    }

    @ViewBuilder
    var actionResultBanner: some View {
        if let result = store.actionResult {
            HStack {
                switch result {
                case let .success(msg):
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(StealthTheme.Colors.statusSuccess)
                    Text(msg)
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                        .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                case let .error(msg):
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(StealthTheme.Colors.statusDanger)
                    Text(msg)
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                        .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                }
                Spacer()
                Button {
                    store.send(.clearActionResult)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Asset.Colors.Nighthawk.navy.color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Asset.Colors.Nighthawk.steelBorder.color, lineWidth: 1)
            )
            .padding(.horizontal)
        }
    }
}

private extension DaoBrief {
    var roleLine: String {
        var roles: [String] = []
        if canPropose { roles.append(L10n.Nighthawk.DaoHub.proposer) }
        if canVote { roles.append(L10n.Nighthawk.DaoHub.voter) }
        if canExec { roles.append(L10n.Nighthawk.DaoHub.executor) }
        return roles.isEmpty ? L10n.Nighthawk.DaoHub.observer : roles.joined(separator: ", ")
    }
}
