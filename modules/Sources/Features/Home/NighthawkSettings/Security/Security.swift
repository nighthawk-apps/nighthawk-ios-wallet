//
//  Security.swift
//  stealth
//
//  Created by Matthew Watt on 5/15/23.
//

import ComposableArchitecture
import Generated
import LocalAuthentication
import LocalAuthenticationClient
import Models
import UserPreferencesStorage

@Reducer
public struct Security {
    public enum PinFlowStep: Equatable {
        case idle
        case setupEnter
        case setupConfirm(firstPin: String)
        case changeVerifyCurrent
        case changeEnterNew
        case changeConfirmNew(firstPin: String)
        case disableVerifyCurrent
        case verifyOnly
    }

    @ObservableState
    public struct State: Equatable {
        public var areBiometricsEnabled = false
        public var biometryType: LABiometryType = .none
        public var isPinEnabled = false
        public var pinFlowStep: PinFlowStep = .idle
        public var pinInput = ""
        public var pinErrorMessage: String?
        public var pinStatusMessage: String?

        public var hasBiometricsHardware: Bool {
            biometryType == .faceID || biometryType == .touchID
        }

        public var pinPromptTitle: String {
            switch pinFlowStep {
            case .idle:
                return ""
            case .setupEnter:
                return L10n.Nighthawk.SettingsTab.Security.pinPromptSetupEnter
            case .setupConfirm:
                return L10n.Nighthawk.SettingsTab.Security.pinPromptSetupConfirm
            case .changeVerifyCurrent:
                return L10n.Nighthawk.SettingsTab.Security.pinPromptChangeCurrent
            case .changeEnterNew:
                return L10n.Nighthawk.SettingsTab.Security.pinPromptChangeNew
            case .changeConfirmNew:
                return L10n.Nighthawk.SettingsTab.Security.pinPromptChangeConfirm
            case .disableVerifyCurrent:
                return L10n.Nighthawk.SettingsTab.Security.pinPromptDisable
            case .verifyOnly:
                return L10n.Nighthawk.SettingsTab.Security.pinPromptVerify
            }
        }

        public init() {}
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case authenticationResponse(Bool)
        case onAppear
        case startSetupPinTapped
        case startChangePinTapped
        case startVerifyPinTapped
        case startDisablePinTapped
        case cancelPinFlowTapped
        case pinInputChanged(String)
        case submitPinTapped
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
                    state.areBiometricsEnabled.toggle()
                }
                return .none
            case .binding(\.areBiometricsEnabled):
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
                    case .none, .opticID:
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
                state.isPinEnabled = SecurityPinStore.isPinSet()
                return .none
            case .startSetupPinTapped:
                state.pinFlowStep = .setupEnter
                state.pinInput = ""
                state.pinErrorMessage = nil
                state.pinStatusMessage = nil
                return .none
            case .startChangePinTapped:
                state.pinFlowStep = .changeVerifyCurrent
                state.pinInput = ""
                state.pinErrorMessage = nil
                state.pinStatusMessage = nil
                return .none
            case .startVerifyPinTapped:
                state.pinFlowStep = .verifyOnly
                state.pinInput = ""
                state.pinErrorMessage = nil
                state.pinStatusMessage = nil
                return .none
            case .startDisablePinTapped:
                state.pinFlowStep = .disableVerifyCurrent
                state.pinInput = ""
                state.pinErrorMessage = nil
                state.pinStatusMessage = nil
                return .none
            case .cancelPinFlowTapped:
                state.pinFlowStep = .idle
                state.pinInput = ""
                state.pinErrorMessage = nil
                return .none
            case let .pinInputChanged(raw):
                let digits = String(raw.filter(\.isNumber).prefix(SecurityPinStore.pinLength))
                state.pinInput = digits
                state.pinErrorMessage = nil
                return .none
            case .submitPinTapped:
                return handlePinSubmit(&state)
            case .binding:
                return .none
            }
        }
    }

    private func handlePinSubmit(_ state: inout State) -> Effect<Action> {
        let pin = state.pinInput
        guard SecurityPinStore.isValidPinFormat(pin) else {
            state.pinErrorMessage = L10n.Nighthawk.SettingsTab.Security.pinErrorDigits(SecurityPinStore.pinLength)
            return .none
        }

        switch state.pinFlowStep {
        case .idle:
            return .none
        case .setupEnter:
            state.pinFlowStep = .setupConfirm(firstPin: pin)
            state.pinInput = ""
            state.pinErrorMessage = nil
        case let .setupConfirm(firstPin):
            completePinSetup(pin: pin, expectedPin: firstPin, isChange: false, state: &state)
        case .changeVerifyCurrent:
            verifyCurrentPin(pin: pin, nextStep: .changeEnterNew, state: &state)
        case .changeEnterNew:
            state.pinFlowStep = .changeConfirmNew(firstPin: pin)
            state.pinInput = ""
            state.pinErrorMessage = nil
        case let .changeConfirmNew(firstPin):
            completePinSetup(pin: pin, expectedPin: firstPin, isChange: true, state: &state)
        case .disableVerifyCurrent:
            disablePinIfVerified(pin: pin, state: &state)
        case .verifyOnly:
            verifyPinOnly(pin: pin, state: &state)
        }
        return .none
    }

    private func completePinSetup(
        pin: String,
        expectedPin: String,
        isChange: Bool,
        state: inout State
    ) {
        guard pin == expectedPin else {
            state.pinErrorMessage = isChange
                ? L10n.Nighthawk.SettingsTab.Security.pinErrorNewMismatch
                : L10n.Nighthawk.SettingsTab.Security.pinErrorMismatch
            state.pinInput = ""
            return
        }
        guard SecurityPinStore.setPin(pin) else {
            state.pinErrorMessage = isChange
                ? L10n.Nighthawk.SettingsTab.Security.pinErrorUpdateKeychain
                : L10n.Nighthawk.SettingsTab.Security.pinErrorStoreKeychain
            return
        }
        state.isPinEnabled = true
        state.pinFlowStep = .idle
        state.pinInput = ""
        state.pinStatusMessage = isChange
            ? L10n.Nighthawk.SettingsTab.Security.pinStatusUpdated
            : L10n.Nighthawk.SettingsTab.Security.pinStatusEnabled
    }

    private func verifyCurrentPin(pin: String, nextStep: PinFlowStep, state: inout State) {
        guard SecurityPinStore.verifyPin(pin) else {
            state.pinErrorMessage = L10n.Nighthawk.SettingsTab.Security.pinErrorCurrentIncorrect
            state.pinInput = ""
            return
        }
        state.pinFlowStep = nextStep
        state.pinInput = ""
        state.pinErrorMessage = nil
    }

    private func disablePinIfVerified(pin: String, state: inout State) {
        guard SecurityPinStore.verifyPin(pin) else {
            state.pinErrorMessage = L10n.Nighthawk.SettingsTab.Security.pinErrorCurrentIncorrect
            state.pinInput = ""
            return
        }
        SecurityPinStore.clearPin()
        state.isPinEnabled = false
        state.pinFlowStep = .idle
        state.pinInput = ""
        state.pinStatusMessage = L10n.Nighthawk.SettingsTab.Security.pinStatusDisabled
    }

    private func verifyPinOnly(pin: String, state: inout State) {
        guard SecurityPinStore.verifyPin(pin) else {
            state.pinErrorMessage = L10n.Nighthawk.SettingsTab.Security.pinErrorIncorrect
            state.pinInput = ""
            return
        }
        state.pinFlowStep = .idle
        state.pinInput = ""
        state.pinStatusMessage = L10n.Nighthawk.SettingsTab.Security.pinStatusVerified
    }

    public init() {}
}
