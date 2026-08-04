//
//  ChangeServer.swift → AddServer.swift
//  stealth
//
//  DarkFi: Allows user to configure the DarkFi Lightwallet Server address.
//  The wallet connects to the lightwallet server for compact block sync
//  and OMR-based note detection.
//

import ComposableArchitecture
import Foundation
import Generated
import Models
import UIComponents
import UserPreferencesStorage
import Utils

@Reducer
public struct ChangeServer {
    @ObservableState
    public struct State: Equatable {
        public enum ServerOption: String, Equatable, CaseIterable, Identifiable, Hashable {
            case `default`
            case custom

            public var id: String { rawValue }
        }

        @Presents public var alert: AlertState<Action.Alert>?
        public var serverOption: ServerOption = .default
        public var customServerAddress: String = ""
        public var defaultServerInfo = "DarkFi Lightwallet Server (automatic)"
        public var isChangingServer = false
        /// Show warning when using a non-standard port
        public var showPortWarning = false

        public var isValidHostAndPort: Bool {
            if serverOption == .default { return true }

            let validHostAndPort = #/^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9]):([1-9][0-9]{0,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$/#

            return customServerAddress.contains(validHostAndPort)
        }

        /// DarkFi lightwallet ports: 9067 (gRPC), 9068 (alt), 443 (TLS terminator).
        public var isExpectedDarkFiPort: Bool {
            guard serverOption == .custom else { return true }
            let components = customServerAddress.split(separator: ":")
            guard let portStr = components.last, let port = Int(portStr) else { return false }
            return [9067, 9068, 443].contains(port)
        }

        /// Reject RFC1918 / loopback hosts for remote custom servers (SSRF guard).
        public var isPrivateOrLoopbackHost: Bool {
            guard serverOption == .custom else { return false }
            let host = customServerAddress.split(separator: ":").first.map(String.init) ?? ""
            let lower = host.lowercased()
            if lower == "localhost" || lower == "::1" { return true }
            if lower.hasPrefix("127.") || lower.hasPrefix("10.") { return true }
            if lower.hasPrefix("192.168.") { return true }
            if lower.hasPrefix("172.") {
                let parts = lower.split(separator: ".")
                if parts.count >= 2, let second = Int(parts[1]), (16...31).contains(second) {
                    return true
                }
            }
            return false
        }

        public var canSave: Bool {
            @Dependency(\.userStoredPreferences) var userStoredPreferences
            let isChanged = userStoredPreferences.isUsingCustomLightwalletd() && serverOption == .default
                || !userStoredPreferences.isUsingCustomLightwalletd() && serverOption == .custom
                || (serverOption == .custom && userStoredPreferences.customLightwalletdServer() != customServerAddress)

            return isChanged
                && (serverOption == .default || (isValidHostAndPort && isExpectedDarkFiPort && !isPrivateOrLoopbackHost))
                && !isChangingServer
        }

        public init() {}
    }

    public enum Action: BindableAction, Equatable {
        case alert(PresentationAction<Alert>)
        case binding(BindingAction<State>)
        case onAppear
        case saveTapped
        case portWarningConfirmed
        case portWarningCancelled
        case changeFailed(error: DarkFiError, previousIsUsingCustom: Bool, previousCustomServer: String?)
        case changeSucceeded

        public enum Alert: Equatable {}
    }

    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .alert:
                return .none
            case .onAppear:
                state.defaultServerInfo =
                    "epidermis-sandbox-marshland.ngrok-free.dev (Studio testnet LWD)"
                if userStoredPreferences.isUsingCustomLightwalletd(),
                   let customServer = userStoredPreferences.customLightwalletdServer() {
                    state.serverOption = .custom
                    state.customServerAddress = customServer
                } else {
                    state.serverOption = .default
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

                userStoredPreferences.setIsUsingCustomLightwalletd(state.serverOption == .custom)
                userStoredPreferences.setCustomLightwalletdServer(state.serverOption == .custom ? state.customServerAddress : nil)

                let isCustom = state.serverOption == .custom
                let customAddress = state.customServerAddress

                return .run { [userStoredPreferences] send in
                    // The endpoint is persisted through UserPreferencesStorage
                    // so WalletHandleManager picks it up on next prepare.
                    if isCustom && !customAddress.isEmpty {
                        let endpoint = "tcp://\(customAddress)"
                        userStoredPreferences.setCustomLightwalletdServer(endpoint)
                    } else {
                        userStoredPreferences.setCustomLightwalletdServer(nil)
                    }

                    try await mainQueue.sleep(for: .seconds(0.5))
                    await send(.changeSucceeded)
                }
            case let .changeFailed(error, previousIsUsingCustom, previousCustomServer):
                state.isChangingServer = false
                userStoredPreferences.setIsUsingCustomLightwalletd(previousIsUsingCustom)
                userStoredPreferences.setCustomLightwalletdServer(previousCustomServer)
                state.alert = AlertState.serverChangeFailed(error)
                return .none
            case .changeSucceeded:
                state.isChangingServer = false
                return .none
            case .binding:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }

    public init() {}
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
