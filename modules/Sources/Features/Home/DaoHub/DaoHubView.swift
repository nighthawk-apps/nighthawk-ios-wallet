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
    @State private var showCreate = false
    @State private var showImport = false
    @State private var showIssue = false
    @State private var showAdmin = false
    @State private var showDaoDetails = false
    @State private var showProposalDetails = false
    @State private var mintTarget: MintAuthorityBrief?
    @State private var freezeTarget: MintAuthorityBrief?

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
                HStack(alignment: .center) {
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)

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
                        .padding(.horizontal)

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
                daoScaffoldHeader(title: store.selectedDao?.name ?? L10n.Nighthawk.DaoHub.title)

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
                        .font(.custom(FontFamily.Roboto.regular.name, size: 13))
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
                            .disabled(store.actionInProgress)
                            .padding(.horizontal)
                        Button(L10n.Nighthawk.DaoHub.voter) { store.send(.exportRole("voter")) }
                            .disabled(store.actionInProgress)
                            .padding(.horizontal)
                        Button(L10n.Nighthawk.DaoHub.executor) { store.send(.exportRole("executor")) }
                            .disabled(store.actionInProgress)
                            .padding(.horizontal)
                        Button(L10n.Nighthawk.DaoHub.fullCopy) { store.send(.exportRole("all")) }
                            .disabled(store.actionInProgress)
                            .padding(.horizontal)
                        Button(L10n.Nighthawk.DaoHub.details) { showDaoDetails.toggle() }
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

    var fundSheet: some View {
        let amountReady = DaoDecimalInput.normalizedPositive(store.fundAmount) != nil
        return VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Nighthawk.DaoHub.addFunds)
                .font(.custom(FontFamily.PulpDisplay.bold.name, size: 20))
            Text(L10n.Nighthawk.DaoHub.addFundsHint)
                .font(.custom(FontFamily.Roboto.regular.name, size: 14))
            Picker(L10n.Nighthawk.DaoHub.token, selection: Binding(
                get: { store.fundTokenId ?? "" },
                set: { store.send(.setFundTokenId($0.isEmpty ? nil : $0)) }
            )) {
                ForEach(fundTokenChoices(), id: \.id) { choice in
                    Text(choice.label).tag(choice.id)
                }
            }
            .pickerStyle(.menu)
            TextField(L10n.Nighthawk.DaoHub.amount, text: Binding(
                get: { store.fundAmount },
                set: { store.send(.setFundAmount($0)) }
            ))
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
            Button(L10n.Nighthawk.DaoHub.addFunds) { store.send(.submitFund) }
                .buttonStyle(.nighthawkPrimary())
                .disabled(store.actionInProgress || !amountReady)
        }
        .padding()
        .applyNighthawkBackground()
    }

    func fundTokenChoices() -> [(id: String, label: String)] {
        var seen = Set<String>()
        var rows: [(id: String, label: String)] = [("", L10n.Nighthawk.WalletTab.drk)]
        for balance in store.tokenBalances where !balance.tokenId.isEmpty && seen.insert(balance.tokenId).inserted {
            let label = balance.displayLabel.flatMap { $0.isEmpty ? nil : $0 } ?? balance.tokenId
            rows.append((balance.tokenId, label))
        }
        for auth in store.mintAuthorities where !auth.tokenId.isEmpty && seen.insert(auth.tokenId).inserted {
            let label = auth.alias.flatMap { $0.isEmpty ? nil : $0 } ?? auth.tokenId
            rows.append((auth.tokenId, label))
        }
        return rows
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
        VStack(alignment: .leading, spacing: 6) {
            statusBadge(for: proposal)

            Text(paymentTitle(proposal))
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
                daoScaffoldHeader(title: L10n.Nighthawk.DaoHub.proposal)

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
                        .font(.custom(FontFamily.Roboto.regular.name, size: 13))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    Button(L10n.Nighthawk.DaoHub.details) { showProposalDetails.toggle() }
                        .buttonStyle(.plain)
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
                                .font(.custom(FontFamily.Roboto.regular.name, size: 12))
                                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                        }
                        .padding(.top, 8)
                    }
                    if store.selectedDao?.canExec == true && !p.isExecuted && p.mintHeight != nil {
                        Button(L10n.Nighthawk.DaoHub.payFromTreasury) { store.send(.payFromTreasury(p.proposalBullaB58)) }
                            .buttonStyle(.nighthawkPrimary())
                            .disabled(store.actionInProgress)
                        Text(L10n.Nighthawk.DaoHub.payHint)
                            .font(.custom(FontFamily.Roboto.regular.name, size: 12))
                            .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    }

                    actionResultBanner
                } else {
                    daoMessage(L10n.Nighthawk.DaoHub.proposalNotFound)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Propose Sheet
private extension DaoHubView {
    var proposeSheet: some View {
        let canSubmit = DaoDecimalInput.normalizedPositive(store.proposeAmount) != nil
            && !store.proposeRecipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return NavigationView {
            Form {
                Section(L10n.Nighthawk.DaoHub.recipient) {
                    TextField(L10n.Nighthawk.DaoHub.recipientAddress, text: Binding(
                        get: { store.proposeRecipient },
                        set: { store.send(.setProposeRecipient($0)) }
                    ))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                }

                Section(L10n.Nighthawk.DaoHub.amount) {
                    TextField(L10n.Nighthawk.DaoHub.amount, text: Binding(
                        get: { store.proposeAmount },
                        set: { store.send(.setProposeAmount($0)) }
                    ))
                    .keyboardType(.decimalPad)
                }

                Section(L10n.Nighthawk.DaoHub.tokenOptional) {
                    TextField(L10n.Nighthawk.DaoHub.tokenIdPlaceholder, text: Binding(
                        get: { store.proposeTokenId },
                        set: { store.send(.setProposeTokenId($0)) }
                    ))
                    .autocapitalization(.none)
                }

                Section(L10n.Nighthawk.DaoHub.duration) {
                    TextField(L10n.Nighthawk.DaoHub.blockWindows, text: Binding(
                        get: { store.proposeDuration },
                        set: { store.send(.setProposeDuration($0)) }
                    ))
                    .keyboardType(.numberPad)
                }

                Section {
                    Text(L10n.Nighthawk.DaoHub.proposeBroadcast)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(L10n.Nighthawk.DaoHub.proposePayment)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.General.cancel) {
                        store.send(.dismissProposeSheet)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Nighthawk.DaoHub.proposePayment) {
                        store.send(.submitProposal)
                    }
                    .disabled(store.actionInProgress || !canSubmit)
                }
            }
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
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    Text(msg)
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                        .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                case let .error(msg):
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
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
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Asset.Colors.Nighthawk.navy.color)
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

private struct CreateGroupSheet: View {
    var onSubmit: (String, String, String, String, Double, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var token = ""
    @State private var yesShare = "0.67"
    @State private var quorum = "1"
    @State private var proposerMinimum = "1"
    @State private var earlyQuorum = ""

    private var proposerLimit: String? { DaoDecimalInput.normalizedPositive(proposerMinimum) }
    private var quorumValue: String? { DaoDecimalInput.normalizedPositive(quorum) }
    private var earlyValue: String? {
        let trimmed = earlyQuorum.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return quorumValue }
        return DaoDecimalInput.normalizedPositive(trimmed)
    }
    private var ratio: Double? { DaoDecimalInput.approvalRatio(yesShare) }
    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && proposerLimit != nil
            && quorumValue != nil
            && earlyValue != nil
            && ratio != nil
    }

    var body: some View {
        NavigationView {
            Form {
                TextField(L10n.Nighthawk.DaoHub.name, text: $name)
                TextField(L10n.Nighthawk.DaoHub.governanceToken, text: $token)
                    .autocapitalization(.none)
                TextField(L10n.Nighthawk.DaoHub.yesShare, text: $yesShare)
                    .keyboardType(.decimalPad)
                TextField(L10n.Nighthawk.DaoHub.votesNeeded, text: $quorum)
                    .keyboardType(.decimalPad)
                TextField(L10n.Nighthawk.DaoHub.proposerMinimum, text: $proposerMinimum)
                    .keyboardType(.decimalPad)
                TextField(L10n.Nighthawk.DaoHub.earlyQuorum, text: $earlyQuorum)
                    .keyboardType(.decimalPad)
                Text(L10n.Nighthawk.DaoHub.earlyQuorumHint)
                    .font(.custom(FontFamily.Roboto.regular.name, size: 13))
                Text(L10n.Nighthawk.DaoHub.allRolesHint)
                    .font(.custom(FontFamily.Roboto.regular.name, size: 13))
            }
            .navigationTitle(L10n.Nighthawk.DaoHub.startGroup)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.General.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Nighthawk.DaoHub.startGroup) {
                        guard let proposerLimit, let quorumValue, let earlyValue, let ratio else { return }
                        onSubmit(
                            name.trimmingCharacters(in: .whitespacesAndNewlines),
                            proposerLimit,
                            quorumValue,
                            earlyValue,
                            ratio,
                            token.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                    }
                    .disabled(!canSubmit)
                }
            }
        }
    }
}

private struct ImportGroupSheet: View {
    var onSubmit: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var toml = ""

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !toml.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                TextField(L10n.Nighthawk.DaoHub.name, text: $name)
                Section(L10n.Nighthawk.DaoHub.importToml) {
                    TextEditor(text: $toml)
                        .frame(minHeight: 180)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
            }
            .navigationTitle(L10n.Nighthawk.DaoHub.importGroup)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.General.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Nighthawk.DaoHub.importGroup) {
                        onSubmit(name, toml)
                    }
                    .disabled(!canSubmit)
                }
            }
        }
    }
}

private struct IssueTokenSheet: View {
    var onSubmit: (String, String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var amount = ""
    @State private var recipient = ""

    private var canSubmit: Bool {
        DaoDecimalInput.normalizedPositive(amount) != nil
            && !recipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                TextField(L10n.Nighthawk.DaoHub.name, text: $name)
                TextField(L10n.Nighthawk.DaoHub.amount, text: $amount)
                    .keyboardType(.decimalPad)
                TextField(L10n.Nighthawk.DaoHub.recipient, text: $recipient)
                    .autocapitalization(.none)
                Text(L10n.Nighthawk.DaoHub.issueHint)
                    .font(.custom(FontFamily.Roboto.regular.name, size: 13))
            }
            .navigationTitle(L10n.Nighthawk.DaoHub.issueToken)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.General.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Nighthawk.DaoHub.issueToken) {
                        onSubmit(name, amount, recipient)
                    }
                    .disabled(!canSubmit)
                }
            }
        }
    }
}

private struct AmountRecipientSheet: View {
    var title: String
    var tokenLabel: String
    var onSubmit: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var amount = ""
    @State private var recipient = ""

    private var canSubmit: Bool {
        DaoDecimalInput.normalizedPositive(amount) != nil
            && !recipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Text(tokenLabel)
                    .font(.custom(FontFamily.IbmPlexMono.regular.name, size: 13))
                TextField(L10n.Nighthawk.DaoHub.amount, text: $amount)
                    .keyboardType(.decimalPad)
                TextField(L10n.Nighthawk.DaoHub.recipient, text: $recipient)
                    .autocapitalization(.none)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.General.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(title) { onSubmit(amount, recipient) }
                        .disabled(!canSubmit)
                }
            }
        }
    }
}

private struct RoleQrSheet: View {
    var payload: String
    var onClose: () -> Void
    @Dependency(\.pasteboard) var pasteboard
    @State private var isCaptured = false

    var body: some View {
        VStack(spacing: 16) {
            Text(L10n.Nighthawk.DaoHub.roleExportTitle)
                .font(.custom(FontFamily.PulpDisplay.bold.name, size: 20))
            if isCaptured {
                Text(L10n.Nighthawk.DaoHub.captured)
                    .font(.custom(FontFamily.Roboto.regular.name, size: 14))
                    .multilineTextAlignment(.center)
            } else if let image = roleQrImage(payload) {
                image
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 220, height: 220)
            }
            Text(L10n.Nighthawk.DaoHub.roleExportHint)
                .font(.custom(FontFamily.Roboto.regular.name, size: 14))
                .multilineTextAlignment(.center)
            if !isCaptured {
                Button(L10n.Nighthawk.DaoHub.copy) {
                    pasteboard.setString(payload.redacted)
                }
                .buttonStyle(.nighthawkSecondary(width: 220))
            }
            Button(L10n.Nighthawk.DaoHub.close, action: onClose)
                .buttonStyle(.nighthawkPrimary())
        }
        .padding()
        .onAppear { isCaptured = UIScreen.main.isCaptured }
        .onReceive(NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)) { _ in
            isCaptured = UIScreen.main.isCaptured
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)) { _ in
            isCaptured = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                isCaptured = UIScreen.main.isCaptured
            }
        }
        .applyNighthawkBackground()
    }

    func roleQrImage(_ payload: String) -> Image? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        let context = CIContext()
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return Image(uiImage: UIImage(cgImage: cg))
    }
}
