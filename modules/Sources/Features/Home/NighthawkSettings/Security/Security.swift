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

public struct Security: Reducer {
    public struct State: Equatable {
        @BindingState public var areBiometricsEnabled = false
        public var biometryType: LABiometryType = .none
        
        public init() {}
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case authenticationResponse(Bool)
        case onAppear
    }
    
    @Dependency(\.localAuthenticationContext) var localAuthenticationContext
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    
    public var body: some ReducerOf<Self> {
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
                return .run { [state] send in
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
                        return
                    @unknown default:
                        return
                    }
                                        
                    do {
                        if try context.canEvaluatePolicy(.deviceOwnerAuthentication) {
                            let response = try await context.evaluatePolicy(.deviceOwnerAuthentication, reason)
                            await send(.authenticationResponse(response))
                        } else {
                            await send(.authenticationResponse(false))
                        }
                    } catch {
                        await send(.authenticationResponse(false))
                    }
                }
            case .onAppear:
                state.areBiometricsEnabled = userStoredPreferences.areBiometricsEnabled()
                let context = localAuthenticationContext()
                _ = try? context.canEvaluatePolicy(.deviceOwnerAuthentication)
                state.biometryType = context.biometryType()
                return .none
            case .binding:
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
