//
//  ChatSettings.swift
//  stealth
//
//  Chat settings reducer matching Android's ChatSettingsScreen.
//  Manages E2E encryption, DAG sync settings, and embedded darkirc node.
//

import ComposableArchitecture
import DarkfiCore
import Foundation
import Pasteboard
import UserPreferencesStorage
import Utils

@Reducer
public struct ChatSettings {
    @ObservableState
    public struct State: Equatable {
        // Embedded node settings
        public var useEmbeddedDarkirc: Bool = false
        public var dagHistoryHours: Int = 8
        public var fastSyncMode: Bool = false
        
        // E2E encrypted channels
        public struct EncryptedChannel: Equatable, Identifiable, Codable {
            public let id: String
            public var name: String  // e.g. "#dev"
            public var sharedSecret: String  // base58
            public var topic: String
        }
        public var encryptedChannels: [EncryptedChannel] = []
        
        // E2E encrypted contacts (DM)
        public struct EncryptedContact: Equatable, Identifiable, Codable {
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
            case secretGenerated(String)
            case cancelTapped
        }
        
        public var body: some ReducerOf<Self> {
            BindingReducer()
            Reduce { state, action in
                switch action {
                case .binding, .addTapped, .cancelTapped:
                    return .none
                case .generateSecretTapped:
                    return .run { send in
                        guard let keypair = DarkfiFfiSafe.generateDmKeypair() else { return }
                        await send(.secretGenerated(keypair.secretB58))
                    }
                case let .secretGenerated(secret):
                    state.sharedSecret = secret
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
    
    @Dependency(\.pasteboard) var pasteboard
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .onAppear:
                loadPreferences(into: &state)
                return .none
            case let .toggleEmbeddedDarkirc(enabled):
                state.useEmbeddedDarkirc = enabled
                userStoredPreferences.setRunEmbeddedDarkirc(enabled)
                return .none
            case let .setDagHistoryHours(hours):
                state.dagHistoryHours = min(max(hours, 1), 24)
                userStoredPreferences.setDarkircDagsCount(state.dagHistoryHours)
                return .none
            case let .toggleFastSync(enabled):
                state.fastSyncMode = enabled
                userStoredPreferences.setDarkircFastMode(enabled)
                return .none
            case .applyAndReconnect:
                savePreferences(from: state)
                return .run { _ in
                    DarkircDaemonManager.shared.stop()
                }
            case .addChannelTapped:
                state.addChannelDialog = AddChannelDialog.State()
                return .none
            case let .removeChannel(id):
                state.encryptedChannels.removeAll { $0.id == id }
                persistChannels(state.encryptedChannels)
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
                    persistChannels(state.encryptedChannels)
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
                persistContacts(state.encryptedContacts)
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
                    persistContacts(state.encryptedContacts)
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
                    guard let keypair = DarkfiFfiSafe.generateDmKeypair() else {
                        await send(.dmKeysGenerated(secret: "", publicKey: ""))
                        return
                    }
                    await send(.dmKeysGenerated(secret: keypair.secretB58, publicKey: keypair.publicB58))
                }
            case let .dmKeysGenerated(secret, publicKey):
                state.isGeneratingKeys = false
                guard !publicKey.isEmpty else { return .none }
                state.myDmPublicKey = publicKey
                userStoredPreferences.setDmPublicKey(publicKey)
                userStoredPreferences.setDmSecretKey(secret)
                return .none
            case .copyPublicKeyTapped:
                if let publicKey = state.myDmPublicKey {
                    pasteboard.setString(RedactableString(publicKey))
                }
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

// MARK: - Persistence
private extension ChatSettings {
    func loadPreferences(into state: inout State) {
        state.useEmbeddedDarkirc = userStoredPreferences.runEmbeddedDarkirc()
        state.dagHistoryHours = userStoredPreferences.darkircDagsCount()
        state.fastSyncMode = userStoredPreferences.darkircFastMode()
        state.myDmPublicKey = userStoredPreferences.dmPublicKey()
        state.encryptedChannels = decodeJSON(
            userStoredPreferences.encryptedChannelsJSON(),
            as: [State.EncryptedChannel].self
        ) ?? []
        state.encryptedContacts = decodeJSON(
            userStoredPreferences.encryptedContactsJSON(),
            as: [State.EncryptedContact].self
        ) ?? []
    }
    
    func savePreferences(from state: State) {
        userStoredPreferences.setRunEmbeddedDarkirc(state.useEmbeddedDarkirc)
        userStoredPreferences.setDarkircDagsCount(state.dagHistoryHours)
        userStoredPreferences.setDarkircFastMode(state.fastSyncMode)
        persistChannels(state.encryptedChannels)
        persistContacts(state.encryptedContacts)
    }
    
    func persistChannels(_ channels: [State.EncryptedChannel]) {
        userStoredPreferences.setEncryptedChannelsJSON(encodeJSON(channels))
    }
    
    func persistContacts(_ contacts: [State.EncryptedContact]) {
        userStoredPreferences.setEncryptedContactsJSON(encodeJSON(contacts))
    }
    
    func encodeJSON<T: Encodable>(_ value: T) -> String? {
        guard let data = try? JSONEncoder().encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func decodeJSON<T: Decodable>(_ json: String?, as type: T.Type) -> T? {
        guard let json, let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
