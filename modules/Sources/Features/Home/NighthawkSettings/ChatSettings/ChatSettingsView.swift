//
//  ChatSettingsView.swift
//  stealth
//
//  Chat settings screen matching Android's ChatSettingsScreen.
//  E2E encryption, DAG sync, and embedded darkirc management.
//

import ComposableArchitecture
import Generated
import Models
import SwiftUI
import UIComponents
import Utils

public struct ChatSettingsView: View {
    @Bindable var store: StoreOf<ChatSettings>

    public init(store: StoreOf<ChatSettings>) {
        self.store = store
    }

    @State private var allowFud = FudPreferences.isEnabled()

    private var fudToggle: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: $allowFud) {
                Text(L10n.Nighthawk.SettingsTab.ChatSettings.allowFudTitle)
                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 15))
                    .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
            }
            .tint(Asset.Colors.Nighthawk.peach.color)
            .onChange(of: allowFud) { _, enabled in
                FudPreferences.setEnabled(enabled)
            }
            Text(L10n.Nighthawk.SettingsTab.ChatSettings.allowFudSubtitle)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
        }
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Embedded Node Sync section
                sectionHeader(L10n.Nighthawk.SettingsTab.ChatSettings.fileOffersSection)
                    .padding(.top, 8)
                fudToggle
                sectionHeader(L10n.Nighthawk.SettingsTab.ChatSettings.embeddedNodeSection)
                    .padding(.top, 8)

                toggleRow(
                    title: L10n.Nighthawk.SettingsTab.ChatSettings.useEmbeddedTitle,
                    subtitle: L10n.Nighthawk.SettingsTab.ChatSettings.useEmbeddedSubtitle,
                    isOn: Binding(
                        get: { store.useEmbeddedDarkirc },
                        set: { store.send(.toggleEmbeddedDarkirc($0)) }
                    )
                )

                if store.useEmbeddedDarkirc {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.Nighthawk.SettingsTab.ChatSettings.dagHistoryTitle)
                            .font(.custom(FontFamily.PulpDisplay.medium.name, size: 14))
                            .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)

                        Text(L10n.Nighthawk.SettingsTab.ChatSettings.dagHistorySubtitle)
                            .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                            .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)

                        HStack {
                            Slider(
                                value: Binding(
                                    get: { Double(store.dagHistoryHours) },
                                    set: { store.send(.setDagHistoryHours(Int($0))) }
                                ),
                                in: 1...24,
                                step: 1
                            )
                            .tint(Asset.Colors.Nighthawk.peach.color)

                            Text("\(store.dagHistoryHours)h")
                                .font(.custom(FontFamily.PulpDisplay.bold.name, size: 14))
                                .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                                .frame(width: 40)
                        }
                    }

                    toggleRow(
                        title: L10n.Nighthawk.SettingsTab.ChatSettings.fastSyncTitle,
                        subtitle: L10n.Nighthawk.SettingsTab.ChatSettings.fastSyncSubtitle,
                        isOn: Binding(
                            get: { store.fastSyncMode },
                            set: { store.send(.toggleFastSync($0)) }
                        )
                    )
                }

                Divider()
                    .frame(height: 1)
                    .overlay(Asset.Colors.Nighthawk.steelBorder.color)
                    .padding(.vertical, 8)

                // Channel privacy labelling — public #channels are plaintext on the wire.
                // Real shared-key / MLS channel E2E is not implemented; do not offer a fake lock.
                sectionHeader(L10n.Nighthawk.SettingsTab.ChatSettings.channelPrivacySection)
                Text(L10n.Nighthawk.SettingsTab.ChatSettings.channelPrivacyBody)
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 14))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)

                Divider()
                    .frame(height: 1)
                    .overlay(Asset.Colors.Nighthawk.steelBorder.color)
                    .padding(.vertical, 8)

                // Encrypted Contacts (DM) section
                sectionHeader(L10n.Nighthawk.SettingsTab.ChatSettings.encryptedContactsSection)

                // My public key
                if let publicKey = store.myDmPublicKey {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.Nighthawk.SettingsTab.ChatSettings.yourPublicKey)
                            .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                            .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)

                        HStack {
                            Text(publicKey)
                                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                                .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Button(action: { store.send(.copyPublicKeyTapped) }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 14))
                                    .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                            }
                        }
                        Text(L10n.Nighthawk.SettingsTab.ChatSettings.safetyNumber)
                            .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                            .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                        Text(
                            NighthawkContacts.safetyNumber(
                                dmPublicKey: publicKey,
                                walletAddress: store.myWalletAddress
                            )
                        )
                        .font(.custom(FontFamily.DejaVuSansMono.regular.name, size: 11))
                        .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)

                        if let inviteUri = store.myContactInviteUri {
                            contactInviteQrCard(inviteUri: inviteUri)
                                .padding(.top, 8)
                        }
                    }
                }

                Button(action: { store.send(.generateDmKeysTapped) }) {
                    HStack {
                        if store.isGeneratingKeys {
                            ProgressView()
                                .tint(Asset.Colors.Nighthawk.peach.color)
                        }
                        Image(systemName: "key.fill")
                        Text(L10n.Nighthawk.SettingsTab.ChatSettings.generateDmKeys)
                    }
                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 15))
                    .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                }
                .disabled(store.isGeneratingKeys)

                if store.encryptedContacts.isEmpty {
                    Text(L10n.Nighthawk.SettingsTab.ChatSettings.noContacts)
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 14))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                } else {
                    VStack(spacing: 0) {
                        ForEach(store.encryptedContacts) { contact in
                            VStack(spacing: 0) {
                                HStack {
                                    Text(contact.nick)
                                        .font(.custom(FontFamily.PulpDisplay.medium.name, size: 15))
                                        .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                                    Spacer()
                                    Button(action: { store.send(.removeContact(contact.id)) }) {
                                        Text(L10n.Nighthawk.SettingsTab.ChatSettings.remove)
                                            .font(.custom(FontFamily.PulpDisplay.medium.name, size: 13))
                                            .foregroundColor(StealthTheme.Colors.statusDanger)
                                    }
                                }
                                .padding(.vertical, 12)

                                Divider()
                                    .frame(height: 1)
                                    .overlay(Asset.Colors.Nighthawk.steelBorder.color)
                            }
                        }
                    }
                }

                Button(action: { store.send(.addContactTapped) }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(L10n.Nighthawk.SettingsTab.ChatSettings.addContact)
                    }
                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 15))
                    .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                }

                Divider()
                    .frame(height: 1)
                    .overlay(Asset.Colors.Nighthawk.steelBorder.color)
                    .padding(.vertical, 8)

                // Apply button
                Button(action: { store.send(.applyAndReconnect) }) {
                    Text(L10n.Nighthawk.SettingsTab.ChatSettings.applyReconnect)
                        .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
                }
                .buttonStyle(.nighthawkPrimary())

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 25)
        }
        .onAppear { store.send(.onAppear) }
        .sheet(
            item: $store.scope(
                state: \.addContactDialog,
                action: \.addContactDialog
            )
        ) { dialogStore in
            addContactSheet(dialogStore)
                .presentationDetents([.large])
        }
        .applyNighthawkBackground()
    }
}

// MARK: - Helpers
private extension ChatSettingsView {
    func contactInviteQrCard(inviteUri: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Nighthawk.SettingsTab.ChatSettings.inviteQrTitle)
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 13))
                .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)

            if let qrImage = QRCodeGenerator.generate(from: inviteUri, scale: 8) {
                HStack {
                    Spacer()
                    Image(decorative: qrImage, scale: 1)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 168, height: 168)
                        .padding(8)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Spacer()
                }
            }

            Button {
                store.send(.copyContactInviteTapped)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "doc.on.doc")
                    Text(L10n.Nighthawk.SettingsTab.ChatSettings.copyInviteUri)
                }
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 13))
                .foregroundColor(Asset.Colors.Nighthawk.peach.color)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Asset.Colors.Nighthawk.navy.color.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Asset.Colors.Nighthawk.steelBorder.color, lineWidth: 1)
        )
    }

    func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.custom(FontFamily.PulpDisplay.bold.name, size: 12))
            .foregroundColor(Asset.Colors.Nighthawk.peach.color)
            .tracking(1.5)
    }

    func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
                    .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)

                Text(subtitle)
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .tint(Asset.Colors.Nighthawk.peach.color)
                .labelsHidden()
        }
        .padding(.vertical, 8)
    }

    func addContactSheet(_ dialogStore: StoreOf<ChatSettings.AddContactDialog>) -> some View {
        @Bindable var dialog = dialogStore
        return NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        TextField(L10n.Nighthawk.SettingsTab.ChatSettings.pasteInvitePlaceholder, text: $dialog.inviteUriInput)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button(L10n.Nighthawk.SettingsTab.ChatSettings.fill) {
                            dialogStore.send(.parseInviteUriTapped)
                        }
                        .font(.custom(FontFamily.PulpDisplay.medium.name, size: 14))
                        .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                    }

                    TextField(L10n.Nighthawk.SettingsTab.ChatSettings.nickname, text: $dialog.contactNick)
                        .textFieldStyle(.roundedBorder)

                    TextField(L10n.Nighthawk.SettingsTab.ChatSettings.peerDmPubkeyPlaceholder, text: $dialog.theirPublicKey)
                        .textFieldStyle(.roundedBorder)

                    TextField(L10n.Nighthawk.SettingsTab.ChatSettings.myDmSecretPlaceholder, text: $dialog.mySecretKey)
                        .textFieldStyle(.roundedBorder)

                    Button(L10n.Nighthawk.SettingsTab.ChatSettings.generateKeypair) {
                        dialogStore.send(.generateKeysTapped)
                    }
                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 14))
                    .foregroundColor(Asset.Colors.Nighthawk.peach.color)

                    if !dialog.myPublicKey.isEmpty {
                        Text(L10n.Nighthawk.SettingsTab.ChatSettings.myPublicKeyValue(dialog.myPublicKey))
                            .font(.custom(FontFamily.DejaVuSansMono.regular.name, size: 11))
                            .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                            .lineLimit(2)
                    }

                    TextField(L10n.Nighthawk.SettingsTab.ChatSettings.walletAddressOptional, text: $dialog.walletAddress)
                        .textFieldStyle(.roundedBorder)

                    if let error = dialog.errorMessage {
                        Text(error)
                            .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                            .foregroundColor(StealthTheme.Colors.statusDanger)
                    }

                    Button(L10n.Nighthawk.SettingsTab.ChatSettings.addContactButton) {
                        dialogStore.send(.addTapped)
                    }
                    .buttonStyle(.nighthawkPrimary())
                }
                .padding(20)
            }
            .applyNighthawkBackground()
            .navigationTitle(L10n.Nighthawk.SettingsTab.ChatSettings.addContactSheetTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.General.cancel) { dialogStore.send(.cancelTapped) }
                }
            }
        }
    }
}
