//
//  NewDmConversationView.swift
//  stealth
//
//  Bottom sheet for creating a new DM conversation.
//  Port of Android's ChatNewDmSheet.
//
//  Flow:
//  1. User enters a contact label ("alice")
//  2. User pastes peer's public key (or scans QR)
//  3. User taps "Generate My Keys" to create a ChaCha20 keypair
//  4. User copies their public key to share with peer
//  5. User taps "Start DM" to save the contact and begin chatting
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

@Reducer
public struct NewDmConversation {
    @ObservableState
    public struct State: Equatable {
        public var contactLabel: String = ""
        public var theirPublicKey: String = ""
        public var myPublicKey: String = ""
        public var mySecretKey: String = ""
        public var isBusy: Bool = false
        public var showPasteConfirm: Bool = false
        public var errorMessage: String?
        
        public init(initialPeerPublicKey: String? = nil) {
            if let key = initialPeerPublicKey {
                self.theirPublicKey = key
            }
        }
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case generateKeysTapped
        case keysGenerated(secretB58: String, publicB58: String)
        case keyGenerationFailed
        case pasteFromClipboardTapped
        case pasteConfirmed
        case pasteCancelled
        case copyMyPublicKeyTapped
        case startDmTapped
        case contactSaved(DmContact)
        case saveFailed(String)
        case dismiss
    }
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .generateKeysTapped:
                state.isBusy = true
                return .run { send in
                    if let kp = DarkircContactManager.generateKeypair() {
                        await send(.keysGenerated(secretB58: kp.secretB58, publicB58: kp.publicB58))
                    } else {
                        await send(.keyGenerationFailed)
                    }
                }
                
            case let .keysGenerated(secret, publicKey):
                state.isBusy = false
                state.mySecretKey = secret
                state.myPublicKey = publicKey
                return .none
                
            case .keyGenerationFailed:
                state.isBusy = false
                state.errorMessage = "Failed to generate DM keypair"
                return .none
                
            case .pasteFromClipboardTapped:
                state.showPasteConfirm = true
                return .none
                
            case .pasteConfirmed:
                state.showPasteConfirm = false
                if let clip = UIPasteboard.general.string {
                    if let key = DarkircDmPubkeyParser.extractFromText(clip) {
                        state.theirPublicKey = key
                    } else {
                        // Validate raw paste as base58: must be ≥32 chars and
                        // contain only valid base58 alphabet (no 0, O, I, l).
                        let trimmed = clip.trimmingCharacters(in: .whitespacesAndNewlines)
                        let base58Charset = CharacterSet(
                            charactersIn: "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
                        )
                        let isBase58 = trimmed.count >= 32
                            && trimmed.unicodeScalars.allSatisfy { base58Charset.contains($0) }
                        if isBase58 {
                            state.theirPublicKey = trimmed
                        } else {
                            state.errorMessage = "Clipboard does not contain a valid base58 public key."
                        }
                    }
                }
                return .none
                
            case .pasteCancelled:
                state.showPasteConfirm = false
                return .none
                
            case .copyMyPublicKeyTapped:
                let shareText = DarkircDmPubkeyParser.formatForSharing(state.myPublicKey)
                UIPasteboard.general.setItems(
                    [[UIPasteboard.typeAutomatic: shareText]],
                    options: [.expirationDate: Date().addingTimeInterval(60)]
                )
                return .none
                
            case .startDmTapped:
                state.isBusy = true
                let label = state.contactLabel
                let theirPub = state.theirPublicKey
                let mySecret = state.mySecretKey
                let myPublic = state.myPublicKey
                
                return .run { send in
                    let contact = await DarkircCryptoStore.shared.addContact(
                        contactLabel: label,
                        theirPublicB58: theirPub,
                        mySecretB58: mySecret,
                        myPublicB58: myPublic
                    )
                    await send(.contactSaved(contact))
                }
                
            case .contactSaved:
                state.isBusy = false
                return .send(.dismiss)
                
            case let .saveFailed(message):
                state.isBusy = false
                state.errorMessage = message
                return .none
                
            case .dismiss:
                return .none
            }
        }
    }
    
    public init() {}
}

// MARK: - View

struct NewDmConversationView: View {
    @Bindable var store: StoreOf<NewDmConversation>
    
    private var canStart: Bool {
        !store.contactLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !store.theirPublicKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !store.mySecretKey.isEmpty &&
        !store.isBusy
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    Text("New DM Conversation")
                        .font(.custom(FontFamily.PulpDisplay.bold.name, size: 22))
                        .foregroundColor(.white)
                    
                    Text("Exchange public keys with your peer to start an end-to-end encrypted DM using ChaCha20.")
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 14))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    
                    // Contact label
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CONTACT LABEL")
                            .font(.custom(FontFamily.PulpDisplay.medium.name, size: 11))
                            .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                            .tracking(1.5)
                        
                        TextField("e.g. alice", text: $store.contactLabel)
                            .font(.custom(FontFamily.PulpDisplay.regular.name, size: 16))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Asset.Colors.Nighthawk.navy.color)
                            )
                            .disabled(store.isBusy)
                    }
                    
                    // Peer public key
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PEER'S PUBLIC KEY")
                            .font(.custom(FontFamily.PulpDisplay.medium.name, size: 11))
                            .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                            .tracking(1.5)
                        
                        TextField("Base58 public key", text: $store.theirPublicKey, axis: .vertical)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.white)
                            .lineLimit(3)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Asset.Colors.Nighthawk.navy.color)
                            )
                            .disabled(store.isBusy)
                        
                        Button("Paste from Clipboard") {
                            store.send(.pasteFromClipboardTapped)
                        }
                        .font(.custom(FontFamily.PulpDisplay.medium.name, size: 13))
                        .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                    }
                    
                    // Generate my keys
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MY KEYPAIR")
                            .font(.custom(FontFamily.PulpDisplay.medium.name, size: 11))
                            .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                            .tracking(1.5)
                        
                        if store.myPublicKey.isEmpty {
                            Button(action: { store.send(.generateKeysTapped) }) {
                                HStack(spacing: 8) {
                                    if store.isBusy {
                                        ProgressView().tint(.white)
                                    }
                                    Image(systemName: "key.fill")
                                        .foregroundColor(.white)
                                    Text("Generate My Keys")
                                        .font(.custom(FontFamily.PulpDisplay.medium.name, size: 15))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Asset.Colors.Nighthawk.peach.color.opacity(0.3))
                                )
                            }
                            .disabled(store.isBusy)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("My Public Key:")
                                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 13))
                                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                                
                                Text(store.myPublicKey)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Asset.Colors.Nighthawk.navy.color)
                                    )
                                
                                Button(action: { store.send(.copyMyPublicKeyTapped) }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "doc.on.doc")
                                            .font(.system(size: 13))
                                        Text("Copy to Share")
                                            .font(.custom(FontFamily.PulpDisplay.medium.name, size: 13))
                                    }
                                    .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                                }
                                
                                Text("Share this key with your peer so they can message you.")
                                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color.opacity(0.7))
                            }
                        }
                    }
                    
                    // Error message
                    if let error = store.errorMessage {
                        Text(error)
                            .font(.custom(FontFamily.PulpDisplay.regular.name, size: 13))
                            .foregroundColor(.red)
                    }
                    
                    Spacer().frame(height: 8)
                    
                    // Start DM button
                    Button(action: { store.send(.startDmTapped) }) {
                        HStack {
                            if store.isBusy {
                                ProgressView().tint(.white)
                            }
                            Text("Start DM")
                                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(canStart ? Asset.Colors.Nighthawk.peach.color : Asset.Colors.Nighthawk.navy.color)
                        )
                    }
                    .disabled(!canStart)
                }
                .padding(20)
            }
            .applyNighthawkBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        store.send(.dismiss)
                    }
                    .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                }
            }
        }
        .alert("Paste Public Key", isPresented: $store.showPasteConfirm) {
            Button("Paste", action: { store.send(.pasteConfirmed) })
            Button("Cancel", role: .cancel, action: { store.send(.pasteCancelled) })
        } message: {
            Text("Paste the DM public key from clipboard? The key will be extracted from !darkfi-dm-pubkey: format if present.")
        }
    }
}
