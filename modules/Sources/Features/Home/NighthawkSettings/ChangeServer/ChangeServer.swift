//
//  ChangeServer.swift → AddServer.swift
//  stealth
//
//  DarkFi: Allows user to configure the DarkFi Lightwallet Server address.
//  The wallet connects to the lightwallet server for compact block sync
//  and OMR-based note detection.
//

import ComposableArchitecture
import DarkfiCore
import Foundation
import Generated
import MnemonicClient
import Models
import SDKSynchronizer
import UIComponents
import UserPreferencesStorage
import Utils
import WalletStorage

@Reducer
public struct ChangeServer {
    @ObservableState
    public struct State: Equatable {
        public enum ServerOption: String, Equatable, CaseIterable, Identifiable, Hashable {
            case `default`
            case custom

            public var id: String { rawValue }
        }

        public static let testnetTlsPreset = ServerPreset(
            id: "testnet-tls",
            title: L10n.Nighthawk.SettingsTab.ChangeServer.presetTestnet,
            subtitle: "https://epidermis-sandbox-marshland.ngrok-free.dev:443",
            endpoint: "https://epidermis-sandbox-marshland.ngrok-free.dev:443",
            useTls: true
        )

        public static let localPreset = ServerPreset(
            id: "local-lwd",
            title: L10n.Nighthawk.SettingsTab.ChangeServer.presetLocal,
            subtitle: "127.0.0.1:9067",
            endpoint: "127.0.0.1:9067",
            useTls: false
        )

        public static var presetsForActiveNetwork: [ServerPreset] {
            switch DarkfiNetwork.active() {
            case .mainnet:
                return [localPreset]
            case .testnet:
                return [testnetTlsPreset, localPreset]
            }
        }

        @Presents public var alert: AlertState<Action.Alert>?
        public var serverOption: ServerOption = .default
        public var customServerAddress: String = ""
        public var useTls: Bool = false
        public var defaultServerInfo = "127.0.0.1:9067 (lightwallet testnet)"
        public var isChangingServer = false
        /// Show warning when using a non-standard port
        public var showPortWarning = false
        public var presets: [ServerPreset] = State.presetsForActiveNetwork

        public var trimmedCustomAddress: String {
            customServerAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        public var isTlsEndpoint: Bool {
            let lower = trimmedCustomAddress.lowercased()
            return useTls || lower.hasPrefix("https://") || lower.hasPrefix("tcp+tls://")
        }

        /// Normalized endpoint string persisted to UserPreferencesStorage.
        public var effectiveCustomEndpoint: String {
            let trimmed = trimmedCustomAddress
            guard !trimmed.isEmpty else { return "" }
            let lower = trimmed.lowercased()
            if lower.hasPrefix("https://") || lower.hasPrefix("tcp+tls://") || lower.hasPrefix("http://") {
                return trimmed
            }
            let bare = Self.stripSupportedScheme(trimmed)
            if useTls {
                return "https://\(bare)"
            }
            return bare
        }

        public var isValidHostAndPort: Bool {
            if serverOption == .default { return true }
            let trimmed = trimmedCustomAddress
            guard !trimmed.isEmpty else { return false }

            let lower = trimmed.lowercased()
            if lower.contains("://") {
                let allowedSchemes = ["https://", "http://", "tcp://", "tcp+tls://"]
                guard allowedSchemes.contains(where: { lower.hasPrefix($0) }) else {
                    return false
                }
            }

            let authority = Self.stripSupportedScheme(trimmed)
                .split(separator: "/", maxSplits: 1)
                .first
                .map(String.init) ?? ""

            let parts = authority.split(separator: ":", omittingEmptySubsequences: false)
            guard parts.count == 2,
                  let host = parts.first, !host.isEmpty,
                  let portStr = parts.last, let port = Int(portStr),
                  (1...65_535).contains(port) else {
                return false
            }
            let hostLabels = host.split(separator: ".", omittingEmptySubsequences: false)
            return hostLabels.allSatisfy { label in
                guard !label.isEmpty, !label.hasPrefix("-"), !label.hasSuffix("-") else {
                    return false
                }
                return label.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") }
            }
        }

        /// DarkFi lightwallet default port is 9067 (or 443 for HTTPS/TLS endpoints).
        public var isExpectedDarkFiPort: Bool {
            guard serverOption == .custom else { return true }
            let authority = Self.stripSupportedScheme(trimmedCustomAddress)
                .split(separator: "/", maxSplits: 1)
                .first
                .map(String.init) ?? ""
            let components = authority.split(separator: ":")
            guard components.count == 2, let portStr = components.last, let port = Int(portStr) else {
                return false
            }
            if isTlsEndpoint && port == 443 {
                return true
            }
            return port == 9067
        }

        public var savedUsesCustom = false
        public var savedCustomServer = ""

        public var canSave: Bool {
            let currentEffective = serverOption == .custom ? effectiveCustomEndpoint : ""
            let isChanged = savedUsesCustom && serverOption == .default
                || !savedUsesCustom && serverOption == .custom
                || (serverOption == .custom && savedCustomServer != currentEffective)

            return isChanged && (serverOption == .default || isValidHostAndPort) && !isChangingServer
        }

        public init() {}

        static func stripSupportedScheme(_ raw: String) -> String {
            let lower = raw.lowercased()
            for prefix in ["https://", "http://", "tcp+tls://", "tcp://", "socks5://"] where lower.hasPrefix(prefix) {
                return String(raw.dropFirst(prefix.count))
            }
            return raw
        }
    }

    public enum Action: BindableAction, Equatable {
        case alert(PresentationAction<Alert>)
        case binding(BindingAction<State>)
        case onAppear
        case presetSelected(ServerPreset)
        case useTlsToggled(Bool)
        case saveTapped
        case portWarningConfirmed
        case portWarningCancelled
        case changeFailed(error: DarkFiError, previousIsUsingCustom: Bool, previousCustomServer: String?)
        case changeSucceeded(savedUsesCustom: Bool, savedCustomServer: String)

        public enum Alert: Equatable {}
    }

    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    @Dependency(\.walletStorage) var walletStorage
    @Dependency(\.mnemonic) var mnemonic

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .alert:
                return .none
            case .onAppear:
                state.savedUsesCustom = userStoredPreferences.isUsingCustomLightwalletd()
                state.savedCustomServer = userStoredPreferences.customLightwalletdServer() ?? ""
                state.defaultServerInfo = "127.0.0.1:9067 (lightwallet \(DarkfiNetwork.activeLabel))"
                state.presets = State.presetsForActiveNetwork
                if userStoredPreferences.isUsingCustomLightwalletd(),
                   let customServer = userStoredPreferences.customLightwalletdServer() {
                    state.serverOption = .custom
                    state.customServerAddress = customServer
                    let lower = customServer.lowercased()
                    state.useTls = lower.hasPrefix("https://") || lower.hasPrefix("tcp+tls://")
                } else {
                    state.serverOption = .default
                    state.useTls = false
                }
                return .none
            case let .presetSelected(preset):
                state.serverOption = .custom
                state.customServerAddress = preset.endpoint
                state.useTls = preset.useTls
                return .none
            case let .useTlsToggled(enabled):
                state.useTls = enabled
                let trimmed = state.trimmedCustomAddress
                guard !trimmed.isEmpty else { return .none }
                let bare = State.stripSupportedScheme(trimmed)
                state.customServerAddress = enabled ? "https://\(bare)" : bare
                return .none
            case .binding(\.customServerAddress):
                let lower = state.trimmedCustomAddress.lowercased()
                if lower.hasPrefix("https://") || lower.hasPrefix("tcp+tls://") {
                    state.useTls = true
                } else if lower.hasPrefix("http://") || lower.hasPrefix("tcp://") {
                    state.useTls = false
                }
                return .none
            case .saveTapped:
                guard state.canSave else { return .none }

                // Check for non-standard port and warn
                if state.serverOption == .custom && !state.isExpectedDarkFiPort {
                    state.showPortWarning = true
                    return .none
                }

                return .send(.portWarningConfirmed)

            case .portWarningCancelled:
                state.showPortWarning = false
                return .none

            case .portWarningConfirmed:
                state.showPortWarning = false
                state.isChangingServer = true

                let oldIsUsingCustom = userStoredPreferences.isUsingCustomLightwalletd()
                let oldCustomServer = userStoredPreferences.customLightwalletdServer()

                let isCustom = state.serverOption == .custom
                let persistedEndpoint = isCustom ? state.effectiveCustomEndpoint : ""

                userStoredPreferences.setIsUsingCustomLightwalletd(isCustom)
                userStoredPreferences.setCustomLightwalletdServer(
                    isCustom && !persistedEndpoint.isEmpty ? persistedEndpoint : nil
                )

                return .run { [userStoredPreferences, walletStorage, sdkSynchronizer, mnemonic] send in
                    if isCustom && !persistedEndpoint.isEmpty {
                        userStoredPreferences.setCustomLightwalletdServer(persistedEndpoint)
                    } else {
                        userStoredPreferences.setCustomLightwalletdServer(nil)
                    }

                    do {
                        try await WalletTransportReprepare.reprepareExisting(
                            walletStorage: walletStorage,
                            sdkSynchronizer: sdkSynchronizer,
                            mnemonic: mnemonic
                        )
                        await send(.changeSucceeded(savedUsesCustom: isCustom, savedCustomServer: persistedEndpoint))
                    } catch {
                        await send(.changeFailed(
                            error: error.toDarkFiError(),
                            previousIsUsingCustom: oldIsUsingCustom,
                            previousCustomServer: oldCustomServer
                        ))
                    }
                }
            case let .changeFailed(error, previousIsUsingCustom, previousCustomServer):
                state.isChangingServer = false
                userStoredPreferences.setIsUsingCustomLightwalletd(previousIsUsingCustom)
                userStoredPreferences.setCustomLightwalletdServer(previousCustomServer)
                state.alert = AlertState.serverChangeFailed(error)
                return .none
            case let .changeSucceeded(savedUsesCustom, savedCustomServer):
                state.isChangingServer = false
                state.savedUsesCustom = savedUsesCustom
                state.savedCustomServer = savedCustomServer
                if savedUsesCustom {
                    state.customServerAddress = savedCustomServer
                }
                return .none
            case .binding:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }

    public init() {}
}

public extension ChangeServer {
    struct ServerPreset: Equatable, Identifiable {
        public let id: String
        public let title: String
        public let subtitle: String
        public let endpoint: String
        public let useTls: Bool

        public init(id: String, title: String, subtitle: String, endpoint: String, useTls: Bool) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.endpoint = endpoint
            self.useTls = useTls
        }
    }
}

// MARK: - Alerts
extension AlertState where Action == ChangeServer.Action.Alert {
    public static func serverChangeFailed(_ error: DarkFiError) -> AlertState {
        AlertState {
            TextState(L10n.Nighthawk.SettingsTab.ChangeServer.Alert.ChangeServerFailed.title)
        } actions: {
            ButtonState {
                TextState(L10n.General.ok)
            }
        } message: {
            TextState(L10n.Nighthawk.SettingsTab.ChangeServer.Alert.ChangeServerFailed.message(error.message, 0))
        }
    }
}
