//
//  ChatSettingsView.swift
//  stealth
//
//  Chat settings screen matching Android's ChatSettingsScreen.
//  E2E encryption, DAG sync, and embedded darkirc management.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

public struct ChatSettingsView: View {
    @Bindable var store: StoreOf<ChatSettings>
    @Environment(\.dismiss) private var dismiss
    
    public init(store: StoreOf<ChatSettings>) {
        self.store = store
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Asset.Assets.Icons.Nighthawk.chevronLeft.image
                            .resizable()
                            .renderingMode(.template)
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Chat Settings")
                        .font(.custom(FontFamily.PulpDisplay.bold.name, size: 20))
                        .foregroundColor(.white)
                    
                    Spacer()
                    Spacer().frame(width: 24)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                // Embedded Node Sync section
                sectionHeader("EMBEDDED NODE SYNC")
                
                toggleRow(
                    title: "Use embedded darkirc",
                    subtitle: "Run darkirc inside the app",
                    isOn: Binding(
                        get: { store.useEmbeddedDarkirc },
                        set: { store.send(.toggleEmbeddedDarkirc($0)) }
                    )
                )
                
                if store.useEmbeddedDarkirc {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DAG history hours (1–24)")
                            .font(.custom(FontFamily.PulpDisplay.medium.name, size: 14))
                            .foregroundColor(.white)
                        
                        Text("Each DAG is about one hour of channel history. Default is 8 (upstream darkirc).")
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
                    .padding(.horizontal)
                    
                    toggleRow(
                        title: "Fast sync (header-only)",
                        subtitle: "Matches upstream fast_mod: quicker DAG sync with less history fetch.",
                        isOn: Binding(
                            get: { store.fastSyncMode },
                            set: { store.send(.toggleFastSync($0)) }
                        )
                    )
                }
                
                Divider().overlay(Asset.Colors.Nighthawk.navy.color)
                
                // Encrypted Channels section
                sectionHeader("ENCRYPTED CHANNELS")
                
                if store.encryptedChannels.isEmpty {
                    Text("No encrypted channels configured.")
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 14))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                        .padding(.horizontal)
                } else {
                    ForEach(store.encryptedChannels) { channel in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(channel.name)
                                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 15))
                                    .foregroundColor(.white)
                                if !channel.topic.isEmpty {
                                    Text(channel.topic)
                                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                                }
                            }
                            Spacer()
                            Button(action: { store.send(.removeChannel(channel.id)) }) {
                                Text("Remove")
                                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 13))
                                    .foregroundColor(.red.opacity(0.8))
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Button(action: { store.send(.addChannelTapped) }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add encrypted channel")
                    }
                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 15))
                    .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                }
                .padding(.horizontal)
                
                Divider().overlay(Asset.Colors.Nighthawk.navy.color)
                
                // Encrypted Contacts (DM) section
                sectionHeader("ENCRYPTED CONTACTS (DM)")
                
                // My public key
                if let publicKey = store.myDmPublicKey {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your public key (share with contact):")
                            .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                            .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                        
                        HStack {
                            Text(publicKey)
                                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            
                            Button(action: { store.send(.copyPublicKeyTapped) }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 14))
                                    .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Button(action: { store.send(.generateDmKeysTapped) }) {
                    HStack {
                        if store.isGeneratingKeys {
                            ProgressView()
                                .tint(.white)
                        }
                        Image(systemName: "key.fill")
                        Text("Generate my DM keys")
                    }
                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 15))
                    .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                }
                .disabled(store.isGeneratingKeys)
                .padding(.horizontal)
                
                if store.encryptedContacts.isEmpty {
                    Text("No encrypted contacts configured.")
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 14))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                        .padding(.horizontal)
                } else {
                    ForEach(store.encryptedContacts) { contact in
                        HStack {
                            Text(contact.nick)
                                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 15))
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: { store.send(.removeContact(contact.id)) }) {
                                Text("Remove")
                                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 13))
                                    .foregroundColor(.red.opacity(0.8))
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Button(action: { store.send(.addContactTapped) }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add encrypted contact")
                    }
                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 15))
                    .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                }
                .padding(.horizontal)
                
                Divider().overlay(Asset.Colors.Nighthawk.navy.color)
                
                // Apply button
                Button(action: { store.send(.applyAndReconnect) }) {
                    Text("Apply & reconnect")
                        .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
                }
                .buttonStyle(.nighthawkPrimary())
                .padding(.horizontal)
                
                Spacer().frame(height: 40)
            }
        }
        .onAppear { store.send(.onAppear) }
        .applyNighthawkBackground()
    }
}

// MARK: - Helpers
private extension ChatSettingsView {
    func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.custom(FontFamily.PulpDisplay.bold.name, size: 12))
            .foregroundColor(Asset.Colors.Nighthawk.peach.color)
            .tracking(1.5)
            .padding(.horizontal)
    }
    
    func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .tint(Asset.Colors.Nighthawk.peach.color)
                .labelsHidden()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}
