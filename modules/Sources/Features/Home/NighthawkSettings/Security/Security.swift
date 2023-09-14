//
//  Security.swift
//  secant
//
//  Created by Matthew Watt on 5/15/23.
//

import ComposableArchitecture
import Generated
import LocalAuthentication
import LocalAuthenticationClient
import UserPreferencesStorage

public struct Security: ReducerProtocol {
    public struct State: Equatable {
        @BindingState public var areBiometricsEnabled = false
        public var biometryType: LABiometryType = .none
        
        public init() {}
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case authenticationResponse(Bool)
        case noOp
        case onAppear
    }
    
    @Dependency(\.localAuthenticationContext) var localAuthenticationContext
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    
    public var body: some ReducerProtocolOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case let .authenticationResponse(authenticated):
                if authenticated {
                    userStoredPreferences.setAreBiometricsEnabled(state.areBiometricsEnabled)
                } else {
                    state.areBiometricsEnabled = !state.areBiometricsEnabled
                }
                return .none
            case .binding(\.$areBiometricsEnabled):
                return .task { [state] in
                    let reason: String
                    let context = localAuthenticationContext()
                    _ = try? context.canEvaluatePolicy(.deviceOwnerAuthentication)
                    switch context.biometryType() {
                    case .faceID:
                        reason = state.areBiometricsEnabled
                            ? L10n.Nighthawk.SettingsTab.Security.enableValidationReason("Face ID")
                            : L10n.Nighthawk.SettingsTab.Security.disableValidationReason("Face ID")
                    case .touchID:
                        reason = state.areBiometricsEnabled
                            ? L10n.Nighthawk.SettingsTab.Security.enableValidationReason("Touch ID")
                            : L10n.Nighthawk.SettingsTab.Security.disableValidationReason("Touch ID")
                    case .none:
                        return .noOp
                    @unknown default:
                        return .noOp
                    }
                                        
                    do {
                        if try context.canEvaluatePolicy(.deviceOwnerAuthentication) {
                            return try await .authenticationResponse(context.evaluatePolicy(.deviceOwnerAuthentication, reason))
                        } else {
                            return .authenticationResponse(false)
                        }
                    } catch {
                        return .authenticationResponse(false)
                    }
                }
            case .onAppear:
                state.areBiometricsEnabled = userStoredPreferences.areBiometricsEnabled()
                let context = localAuthenticationContext()
                _ = try? context.canEvaluatePolicy(.deviceOwnerAuthentication)
                state.biometryType = context.biometryType()
                return .none
            case .binding, .noOp:
                return .none
            }
        }
    }
    
    public init() {}
}

// MARK: - Placeholder
extension Security.State {
    public static var placeholder = Self()
}
