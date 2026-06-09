//
//  ChatSettings.swift
//  stealth
//
//  Chat settings reducer matching Android's ChatSettingsScreen.
//  Manages E2E encryption, DAG sync settings, and embedded darkirc node.
//

import ComposableArchitecture
import Foundation

@Reducer
public struct ChatSettings {
    @ObservableState
    public struct State: Equatable {
        // Embedded node settings
        public var useEmbeddedDarkirc: Bool = false
        public var dagHistoryHours: Int = 8
        public var fastSyncMode: Bool = false
        
        // E2E encrypted channels
        public struct EncryptedChannel: Equatable, Identifiable {
            public let id: String
            public var name: String  // e.g. "#dev"
            public var sharedSecret: String  // base58
            public var topic: String
        }
        public var encryptedChannels: [EncryptedChannel] = []
        
        // E2E encrypted contacts (DM)
        public struct EncryptedContact: Equatable, Identifiable {
            public let id: String
            public var nick: String
            public var mySecretKey: String  // base58
            public var theirPublicKey: String  // base58
        }
        public var encryptedContacts: [EncryptedContact] = []
        
        // DM keypair
        public var myDmPublicKey: String?
        public var isGeneratingKeys: Bool = false
        
        // Alerts
        @Presents public var addChannelDialog: AddChannelDialog.State?
        @Presents public var addContactDialog: AddContactDialog.State?
        
        public init() {}
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        
        // Embedded node
        case toggleEmbeddedDarkirc(Bool)
        case setDagHistoryHours(Int)
        case toggleFastSync(Bool)
        case applyAndReconnect
        
        // E2E channels
        case addChannelTapped
        case removeChannel(String)
        case addChannelDialog(PresentationAction<AddChannelDialog.Action>)
        
        // E2E contacts
        case addContactTapped
        case removeContact(String)
        case addContactDialog(PresentationAction<AddContactDialog.Action>)
        
        // DM keys
        case generateDmKeysTapped
        case dmKeysGenerated(secret: String, publicKey: String)
        case copyPublicKeyTapped
    }
    
    @Reducer
    public struct AddChannelDialog {
        @ObservableState
        public struct State: Equatable {
            public var channelName: String = ""
            public var sharedSecret: String = ""
            public var topic: String = ""
            public init() {}
        }
        
        public enum Action: BindableAction, Equatable {
            case binding(BindingAction<State>)
            case addTapped
            case generateSecretTapped
            case cancelTapped
        }
        
        public var body: some ReducerOf<Self> {
            BindingReducer()
            Reduce { _, action in
                switch action {
                case .binding, .addTapped, .cancelTapped:
                    return .none
                case .generateSecretTapped:
                    // TODO: Generate random shared secret via UniFFI
                    return .none
                }
            }
        }
    }
    
    @Reducer
    public struct AddContactDialog {
        @ObservableState
        public struct State: Equatable {
            public var contactNick: String = ""
            public var mySecretKey: String = ""
            public var theirPublicKey: String = ""
            public init() {}
        }
        
        public enum Action: BindableAction, Equatable {
            case binding(BindingAction<State>)
            case addTapped
            case cancelTapped
        }
        
        public var body: some ReducerOf<Self> {
            BindingReducer()
            Reduce { _, action in
                switch action {
                case .binding, .addTapped, .cancelTapped:
                    return .none
                }
            }
        }
    }
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .onAppear:
                // TODO: Load from persistence
                return .none
            case let .toggleEmbeddedDarkirc(enabled):
                state.useEmbeddedDarkirc = enabled
                return .none
            case let .setDagHistoryHours(hours):
                state.dagHistoryHours = min(max(hours, 1), 24)
                return .none
            case let .toggleFastSync(enabled):
                state.fastSyncMode = enabled
                return .none
            case .applyAndReconnect:
                // TODO: Restart darkirc with new config
                return .none
            case .addChannelTapped:
                state.addChannelDialog = AddChannelDialog.State()
                return .none
            case let .removeChannel(id):
                state.encryptedChannels.removeAll { $0.id == id }
                return .none
            case .addChannelDialog(.presented(.addTapped)):
                if let dialog = state.addChannelDialog {
                    let channel = State.EncryptedChannel(
                        id: UUID().uuidString,
                        name: dialog.channelName,
                        sharedSecret: dialog.sharedSecret,
                        topic: dialog.topic
                    )
                    state.encryptedChannels.append(channel)
                }
                state.addChannelDialog = nil
                return .none
            case .addChannelDialog(.presented(.cancelTapped)):
                state.addChannelDialog = nil
                return .none
            case .addChannelDialog:
                return .none
            case .addContactTapped:
                state.addContactDialog = AddContactDialog.State()
                return .none
            case let .removeContact(id):
                state.encryptedContacts.removeAll { $0.id == id }
                return .none
            case .addContactDialog(.presented(.addTapped)):
                if let dialog = state.addContactDialog {
                    let contact = State.EncryptedContact(
                        id: UUID().uuidString,
                        nick: dialog.contactNick,
                        mySecretKey: dialog.mySecretKey,
                        theirPublicKey: dialog.theirPublicKey
                    )
                    state.encryptedContacts.append(contact)
                }
                state.addContactDialog = nil
                return .none
            case .addContactDialog(.presented(.cancelTapped)):
                state.addContactDialog = nil
                return .none
            case .addContactDialog:
                return .none
            case .generateDmKeysTapped:
                state.isGeneratingKeys = true
                return .run { send in
                    // Use UniFFI generate_dm_keypair()
                    // For now, generate placeholder until UniFFI bindings are compiled
                    // let keypair = generateDmKeypair()
                    // await send(.dmKeysGenerated(secret: keypair.secretB58, publicKey: keypair.publicB58))
                    try await Task.sleep(for: .seconds(0.5))
                    await send(.dmKeysGenerated(secret: "placeholder", publicKey: "placeholder"))
                }
            case let .dmKeysGenerated(_, publicKey):
                state.isGeneratingKeys = false
                state.myDmPublicKey = publicKey
                return .none
            case .copyPublicKeyTapped:
                // TODO: Copy to clipboard
                return .none
            }
        }
        .ifLet(\.$addChannelDialog, action: \.addChannelDialog) {
            AddChannelDialog()
        }
        .ifLet(\.$addContactDialog, action: \.addContactDialog) {
            AddContactDialog()
        }
    }
    
    public init() {}
}
