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
import Generated
import Models
import Pasteboard
import SDKSynchronizer
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

        // DM keypair & contact invite QR
        public var myDmPublicKey: String?
        public var myNickname: String = ""
        public var myWalletAddress: String?
        public var isGeneratingKeys: Bool = false

        public var myContactInviteUri: String? {
            let dmKey = myDmPublicKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let addr = myWalletAddress?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !dmKey.isEmpty || (addr?.isEmpty == false) else { return nil }
            let nick = myNickname.trimmingCharacters(in: .whitespacesAndNewlines)
            return NighthawkContacts.contactInviteUri(
                NighthawkContact(
                    id: nick.isEmpty ? dmKey : nick.lowercased(),
                    nickname: nick,
                    dmPublicKey: dmKey,
                    walletAddress: addr,
                    ratchetCapable: !dmKey.isEmpty
                )
            )
        }

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
        case syncDmContacts([DmContact])
        case addContactDialog(PresentationAction<AddContactDialog.Action>)

        // DM keys & Contact Invite QR
        case generateDmKeysTapped
        case dmKeysGenerated(secret: String, publicKey: String)
        case copyPublicKeyTapped
        case copyContactInviteTapped
        case walletAddressLoaded(String?)
    }

    @Dependency(\.pasteboard) var pasteboard
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    @Dependency(\.userStoredPreferences) var userStoredPreferences

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .onAppear:
                loadPreferences(into: &state)
                state.myNickname = DarkfiChatDefaults.persistentNickname()
                return .run { send in
                    let dmContacts = await DarkircCryptoStore.shared.allContacts()
                    await send(.syncDmContacts(dmContacts))
                    let address = try? await sdkSynchronizer.getAddress()?.stringEncoded
                    await send(.walletAddressLoaded(address))
                }
            case let .syncDmContacts(dmContacts):
                var changed = false
                for contact in dmContacts where !state.encryptedContacts.contains(where: {
                    $0.nick.caseInsensitiveCompare(contact.contactLabel) == .orderedSame
                }) {
                    state.encryptedContacts.append(
                        State.EncryptedContact(
                            id: contact.id,
                            nick: contact.contactLabel,
                            mySecretKey: contact.mySecretB58,
                            theirPublicKey: contact.theirPublicB58
                        )
                    )
                    changed = true
                }
                if changed {
                    persistContacts(state.encryptedContacts)
                }
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
                var dialog = AddContactDialog.State()
                dialog.mySecretKey = userStoredPreferences.dmSecretKey() ?? ""
                dialog.myPublicKey = userStoredPreferences.dmPublicKey() ?? ""
                state.addContactDialog = dialog
                return .none
            case let .removeContact(id):
                let removed = state.encryptedContacts.first { $0.id == id }
                state.encryptedContacts.removeAll { $0.id == id }
                persistContacts(state.encryptedContacts)
                return .run { _ in
                    if let removed {
                        await DarkircCryptoStore.shared.removeContact(id: removed.id)
                        await DarkircCryptoStore.shared.removeContact(byLabel: removed.nick)
                    }
                }
            case .addContactDialog(.presented(.addTapped)):
                return handleAddContactTapped(&state)
            case .addContactDialog(.presented(.cancelTapped)):
                state.addContactDialog = nil
                return .none
            case .addContactDialog:
                return .none
            case .generateDmKeysTapped:
                state.isGeneratingKeys = true
                return .run { send in
                    let keypair = generateDmKeypair()
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
            case .copyContactInviteTapped:
                if let uri = state.myContactInviteUri {
                    pasteboard.setString(RedactableString(uri))
                }
                return .none
            case let .walletAddressLoaded(address):
                state.myWalletAddress = address
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

// MARK: - Dialog Reducers
public extension ChatSettings {
    @Reducer
    struct AddChannelDialog {
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
                        let keypair = generateDmKeypair()
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
    struct AddContactDialog {
        @ObservableState
        public struct State: Equatable {
            public var inviteUriInput: String = ""
            public var contactNick: String = ""
            public var mySecretKey: String = ""
            public var myPublicKey: String = ""
            public var theirPublicKey: String = ""
            public var walletAddress: String = ""
            public var ratchetCapable: Bool = false
            public var errorMessage: String?
            public init() {}
        }

        public enum Action: BindableAction, Equatable {
            case binding(BindingAction<State>)
            case parseInviteUriTapped
            case generateKeysTapped
            case keysGenerated(secret: String, publicKey: String)
            case addTapped
            case cancelTapped
        }

        public var body: some ReducerOf<Self> {
            BindingReducer()
            Reduce { state, action in
                switch action {
                case .binding:
                    state.errorMessage = nil
                    return .none
                case .parseInviteUriTapped:
                    let raw = state.inviteUriInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard let contact = NighthawkContacts.parseInvite(raw) else {
                        state.errorMessage = L10n.Nighthawk.SettingsTab.ChatSettings.errorInvalidInvite
                        return .none
                    }
                    if !contact.nickname.isEmpty {
                        state.contactNick = contact.nickname
                    }
                    if !contact.dmPublicKey.isEmpty {
                        state.theirPublicKey = contact.dmPublicKey
                    }
                    if let addr = contact.walletAddress, !addr.isEmpty {
                        state.walletAddress = addr
                    }
                    state.ratchetCapable = contact.ratchetCapable
                    state.errorMessage = nil
                    return .none
                case .generateKeysTapped:
                    return .run { send in
                        let keypair = generateDmKeypair()
                        await send(.keysGenerated(secret: keypair.secretB58, publicKey: keypair.publicB58))
                    }
                case let .keysGenerated(secret, publicKey):
                    state.mySecretKey = secret
                    state.myPublicKey = publicKey
                    return .none
                case .addTapped, .cancelTapped:
                    return .none
                }
            }
        }
    }
}

// MARK: - Persistence
private extension ChatSettings {
    func handleAddContactTapped(_ state: inout State) -> Effect<Action> {
        guard var dialog = state.addContactDialog else {
            state.addContactDialog = nil
            return .none
        }
        let nick = dialog.contactNick.trimmingCharacters(in: .whitespacesAndNewlines)
        let mySecret = dialog.mySecretKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let myPublic = dialog.myPublicKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let theirPublic = dialog.theirPublicKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let walletAddr = dialog.walletAddress.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !nick.isEmpty, !nick.hasPrefix("#") else {
            dialog.errorMessage = L10n.Nighthawk.SettingsTab.ChatSettings.errorInvalidNick
            state.addContactDialog = dialog
            return .none
        }

        let hasDmKeys = !mySecret.isEmpty || !theirPublic.isEmpty
        if hasDmKeys {
            guard let secretBytes = Base58.decode(mySecret), secretBytes.count == 32,
                  let publicBytes = Base58.decode(theirPublic), publicBytes.count == 32 else {
                dialog.errorMessage = L10n.Nighthawk.SettingsTab.ChatSettings.errorInvalidDmKeys
                state.addContactDialog = dialog
                return .none
            }
            let contact = State.EncryptedContact(
                id: UUID().uuidString,
                nick: nick,
                mySecretKey: mySecret,
                theirPublicKey: theirPublic
            )
            state.encryptedContacts.removeAll {
                $0.nick.caseInsensitiveCompare(nick) == .orderedSame
            }
            state.encryptedContacts.append(contact)
            persistContacts(state.encryptedContacts)
            state.addContactDialog = nil
            return .run { _ in
                do {
                    _ = try await DarkircCryptoStore.shared.addContact(
                        contactLabel: nick,
                        theirPublicB58: theirPublic,
                        mySecretB58: mySecret,
                        myPublicB58: myPublic,
                        ratchetCapable: dialog.ratchetCapable
                    )
                } catch {
                    return
                }
                if !walletAddr.isEmpty {
                    _ = NighthawkContactStore.upsert(
                        NighthawkContact(
                            id: nick.lowercased(),
                            nickname: nick,
                            dmPublicKey: theirPublic,
                            walletAddress: walletAddr
                        )
                    )
                }
            }
        } else if !walletAddr.isEmpty {
            _ = NighthawkContactStore.upsert(
                NighthawkContact(
                    id: nick.lowercased(),
                    nickname: nick,
                    dmPublicKey: "",
                    walletAddress: walletAddr
                )
            )
            state.addContactDialog = nil
            return .none
        } else {
            dialog.errorMessage = L10n.Nighthawk.SettingsTab.ChatSettings.errorMissingContactData
            state.addContactDialog = dialog
            return .none
        }
    }
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
