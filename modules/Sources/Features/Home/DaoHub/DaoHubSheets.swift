//
//  DaoHubSheets.swift
//  Home
//
//  Modal sheets for DAO Hub creation, import, token issuance, and role QR export.
//

import ComposableArchitecture
import CoreImage.CIFilterBuiltins
import Generated
import Pasteboard
import SwiftUI
import UIComponents
import UIKit

struct CreateGroupSheet: View {
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
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(L10n.Nighthawk.DaoHub.name)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                NighthawkTextField(placeholder: L10n.Nighthawk.DaoHub.name, text: $name)

                Text(L10n.Nighthawk.DaoHub.governanceToken)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                NighthawkTextField(placeholder: L10n.Nighthawk.DaoHub.governanceToken, text: $token)

                Text(L10n.Nighthawk.DaoHub.yesShare)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                NighthawkTextField(placeholder: L10n.Nighthawk.DaoHub.yesShare, text: $yesShare)
                    .keyboardType(.decimalPad)

                Text(L10n.Nighthawk.DaoHub.votesNeeded)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                NighthawkTextField(placeholder: L10n.Nighthawk.DaoHub.votesNeeded, text: $quorum)
                    .keyboardType(.decimalPad)

                Text(L10n.Nighthawk.DaoHub.proposerMinimum)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                NighthawkTextField(placeholder: L10n.Nighthawk.DaoHub.proposerMinimum, text: $proposerMinimum)
                    .keyboardType(.decimalPad)

                Text(L10n.Nighthawk.DaoHub.earlyQuorum)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                NighthawkTextField(placeholder: L10n.Nighthawk.DaoHub.earlyQuorum, text: $earlyQuorum)
                    .keyboardType(.decimalPad)

                Text(L10n.Nighthawk.DaoHub.earlyQuorumHint)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                Text(L10n.Nighthawk.DaoHub.allRolesHint)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)

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
                .buttonStyle(.nighthawkPrimary())
                .disabled(!canSubmit)
            }
            .padding(25)
        }
        .nighthawkTopBar(leading: .close, title: L10n.Nighthawk.DaoHub.startGroup) {
            dismiss()
        }
        .applyNighthawkBackground()
    }
}

struct ImportGroupSheet: View {
    var onSubmit: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var toml = ""

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !toml.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(L10n.Nighthawk.DaoHub.name)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                NighthawkTextField(placeholder: L10n.Nighthawk.DaoHub.name, text: $name)

                Text(L10n.Nighthawk.DaoHub.importToml)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                NighthawkTextEditor(placeholder: L10n.Nighthawk.DaoHub.importToml, text: $toml)
                    .frame(minHeight: 180)

                Button(L10n.Nighthawk.DaoHub.importGroup) {
                    onSubmit(name, toml)
                }
                .buttonStyle(.nighthawkPrimary())
                .disabled(!canSubmit)
            }
            .padding(25)
        }
        .nighthawkTopBar(leading: .close, title: L10n.Nighthawk.DaoHub.importGroup) {
            dismiss()
        }
        .applyNighthawkBackground()
    }
}

struct IssueTokenSheet: View {
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
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(L10n.Nighthawk.DaoHub.name)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                NighthawkTextField(placeholder: L10n.Nighthawk.DaoHub.name, text: $name)

                Text(L10n.Nighthawk.DaoHub.amount)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                NighthawkTextField(placeholder: L10n.Nighthawk.DaoHub.amount, text: $amount)
                    .keyboardType(.decimalPad)

                Text(L10n.Nighthawk.DaoHub.recipient)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                NighthawkTextField(placeholder: L10n.Nighthawk.DaoHub.recipient, text: $recipient)

                Text(L10n.Nighthawk.DaoHub.issueHint)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)

                Button(L10n.Nighthawk.DaoHub.issueToken) {
                    onSubmit(name, amount, recipient)
                }
                .buttonStyle(.nighthawkPrimary())
                .disabled(!canSubmit)
            }
            .padding(25)
        }
        .nighthawkTopBar(leading: .close, title: L10n.Nighthawk.DaoHub.issueToken) {
            dismiss()
        }
        .applyNighthawkBackground()
    }
}

struct AmountRecipientSheet: View {
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
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(tokenLabel)
                    .font(.custom(FontFamily.IbmPlexMono.regular.name, size: 13))
                    .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)

                Text(L10n.Nighthawk.DaoHub.amount)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                NighthawkTextField(placeholder: L10n.Nighthawk.DaoHub.amount, text: $amount)
                    .keyboardType(.decimalPad)

                Text(L10n.Nighthawk.DaoHub.recipient)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                NighthawkTextField(placeholder: L10n.Nighthawk.DaoHub.recipient, text: $recipient)

                Button(title) { onSubmit(amount, recipient) }
                    .buttonStyle(.nighthawkPrimary())
                    .disabled(!canSubmit)
            }
            .padding(25)
        }
        .nighthawkTopBar(leading: .close, title: title) {
            dismiss()
        }
        .applyNighthawkBackground()
    }
}

struct RoleQrSheet: View {
    var payload: String
    var onClose: () -> Void
    @Dependency(\.pasteboard) var pasteboard
    @State private var isCaptured = false

    var body: some View {
        VStack(spacing: 16) {
            Text(L10n.Nighthawk.DaoHub.roleExportTitle)
                .font(.custom(FontFamily.PulpDisplay.bold.name, size: 20))
                .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
            if isCaptured {
                Text(L10n.Nighthawk.DaoHub.captured)
                    .font(.custom(FontFamily.SourceSans3.regular.name, size: 14))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    .multilineTextAlignment(.center)
            } else if let image = roleQrImage(payload) {
                image
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 220, height: 220)
            }
            Text(L10n.Nighthawk.DaoHub.roleExportHint)
                .font(.custom(FontFamily.SourceSans3.regular.name, size: 14))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
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
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return Image(uiImage: UIImage(cgImage: cgImage))
    }
}

// MARK: - Fund & Propose Sheets
extension DaoHubView {
    var fundSheet: some View {
        let amountReady = DaoDecimalInput.normalizedPositive(store.fundAmount) != nil
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.Nighthawk.DaoHub.addFundsHint)
                    .paragraph(color: Asset.Colors.Nighthawk.parmaviolet.color)

                HStack {
                    Text(L10n.Nighthawk.DaoHub.token)
                        .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
                    Spacer()
                    Picker(L10n.Nighthawk.DaoHub.token, selection: Binding(
                        get: { store.fundTokenId ?? "" },
                        set: { store.send(.setFundTokenId($0.isEmpty ? nil : $0)) }
                    )) {
                        ForEach(fundTokenChoices(), id: \.id) { choice in
                            Text(choice.label).tag(choice.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Asset.Colors.Nighthawk.peach.color)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Asset.Colors.Nighthawk.navy.color)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Asset.Colors.Nighthawk.steelBorder.color, lineWidth: 1)
                )

                NighthawkTextField(
                    placeholder: L10n.Nighthawk.DaoHub.amount,
                    text: Binding(
                        get: { store.fundAmount },
                        set: { store.send(.setFundAmount($0)) }
                    )
                )
                .keyboardType(.decimalPad)

                Button(L10n.Nighthawk.DaoHub.addFunds) { store.send(.submitFund) }
                    .buttonStyle(.nighthawkPrimary())
                    .disabled(store.actionInProgress || !amountReady)
            }
            .padding(25)
        }
        .nighthawkTopBar(leading: .close, title: L10n.Nighthawk.DaoHub.addFunds) {
            store.send(.dismissFundSheet)
        }
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

    var proposeSheet: some View {
        let canSubmit = DaoDecimalInput.normalizedPositive(store.proposeAmount) != nil
            && !store.proposeRecipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.Nighthawk.DaoHub.recipient)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                NighthawkTextField(
                    placeholder: L10n.Nighthawk.DaoHub.recipientAddress,
                    text: Binding(
                        get: { store.proposeRecipient },
                        set: { store.send(.setProposeRecipient($0)) }
                    )
                )

                Text(L10n.Nighthawk.DaoHub.amount)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                NighthawkTextField(
                    placeholder: L10n.Nighthawk.DaoHub.amount,
                    text: Binding(
                        get: { store.proposeAmount },
                        set: { store.send(.setProposeAmount($0)) }
                    )
                )
                .keyboardType(.decimalPad)

                Text(L10n.Nighthawk.DaoHub.tokenOptional)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                NighthawkTextField(
                    placeholder: L10n.Nighthawk.DaoHub.tokenIdPlaceholder,
                    text: Binding(
                        get: { store.proposeTokenId },
                        set: { store.send(.setProposeTokenId($0)) }
                    )
                )

                Text(L10n.Nighthawk.DaoHub.duration)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                NighthawkTextField(
                    placeholder: L10n.Nighthawk.DaoHub.blockWindows,
                    text: Binding(
                        get: { store.proposeDuration },
                        set: { store.send(.setProposeDuration($0)) }
                    )
                )
                .keyboardType(.numberPad)

                Text(L10n.Nighthawk.DaoHub.proposeBroadcast)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)

                Button(L10n.Nighthawk.DaoHub.proposePayment) {
                    store.send(.submitProposal)
                }
                .buttonStyle(.nighthawkPrimary())
                .disabled(store.actionInProgress || !canSubmit)
            }
            .padding(25)
        }
        .nighthawkTopBar(leading: .close, title: L10n.Nighthawk.DaoHub.proposePayment) {
            store.send(.dismissProposeSheet)
        }
        .applyNighthawkBackground()
    }
}
