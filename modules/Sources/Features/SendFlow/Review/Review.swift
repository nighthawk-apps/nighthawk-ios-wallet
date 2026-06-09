//
//  Review.swift
//  
//
//  Created by Matthew Watt on 7/22/23.
//

import ComposableArchitecture
import DerivationTool
import Generated
import LocalAuthenticationClient
import Models
import UIKit
import UserPreferencesStorage
import Utils

@Reducer
public struct Review {
    @ObservableState
    public struct State: Equatable {
        @Presents public var alert: AlertState<Action.Alert>?
        
        public var zecAmount: DrkAmount
        public var proposal: Proposal
        public var fee: DrkAmount { proposal.totalFeeRequired() }
        public var memo: RedactableString?
        public var recipient: String
        public var recipientIsTransparent = false
        public var total: DrkAmount { zecAmount + fee }
        public var preferredCurrency: NighthawkSetting.FiatCurrency {
            @Dependency(\.userStoredPreferences) var userStoredPreferences
            return userStoredPreferences.fiatCurrency()
        }
        public var latestFiatPrice: Double?
        public var fiatConversion: (NighthawkSetting.FiatCurrency, Double)? {
            if let latestFiatPrice, preferredCurrency != .off {
                (preferredCurrency, latestFiatPrice)
            } else {
                nil
            }
        }
        
        public var tokenName: String {
            return "DRK"
        }
        
        public init(
            zecAmount: DrkAmount,
            memo: RedactableString?,
            recipient: String,
            latestFiatPrice: Double?,
            proposal: Proposal
        ) {
            self.zecAmount = zecAmount
            self.memo = memo
            self.recipient = recipient
            self.latestFiatPrice = latestFiatPrice
            self.proposal = proposal
        }
    }
    
    public enum Action: Equatable {
        case alert(PresentationAction<Alert>)
        case authenticationResponse(Bool)
        case backButtonTapped
        case delegate(Delegate)
        case onAppear
        case sendDrkTapped
        case warnBeforeLeavingApp(URL?)
        
        public enum Alert: Equatable {
            case openBlockExplorer(URL?)
        }
        
        public enum Delegate: Equatable {
            case goBack
            case sendDrk
        }
    }
    
    @Dependency(\.derivationTool) var derivationTool
    @Dependency(\.localAuthenticationContext) var localAuthenticationContext
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .alert(.presented(.openBlockExplorer(blockExplorerURL))):
                if let url = blockExplorerURL {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                return .none
            case .alert(.dismiss):
                return .none
            case let .authenticationResponse(authenticated):
                if authenticated {
                    return .send(.delegate(.sendDrk))
                }
                return .none
            case .backButtonTapped:
                return .send(.delegate(.goBack))
            case .delegate:
                return .none
            case .onAppear:
                state.recipientIsTransparent = derivationTool.isTransparentAddress(state.recipient, "testnet")
                return .none
            case .sendDrkTapped:
                if userStoredPreferences.areBiometricsEnabled() {
                    return .run { send in
                        let context = localAuthenticationContext()
                        
                        do {
                            if try context.canEvaluatePolicy(.deviceOwnerAuthentication) {
                                let response = try await context.evaluatePolicy(
                                    .deviceOwnerAuthentication,
                                    L10n.Nighthawk.LocalAuthentication.sendFundsReason
                                )
                                await send(.authenticationResponse(response))
                            } else {
                                await send(.authenticationResponse(false))
                            }
                        } catch {
                            await send(.authenticationResponse(false))
                        }
                    }
                } else {
                    return .send(.delegate(.sendDrk))
                }
            case let .warnBeforeLeavingApp(blockExplorerURL):
                state.alert = AlertState.warnBeforeLeavingApp(blockExplorerURL)
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
    
    public init() {}
}

// MARK: Alerts

extension AlertState where Action == Review.Action.Alert {
    public static func warnBeforeLeavingApp(_ blockExplorerURL: URL?) -> AlertState {
        AlertState {
            TextState(L10n.Nighthawk.TransactionDetails.leavingWallet)
        } actions: {
            ButtonState(action: .openBlockExplorer(blockExplorerURL)) {
                TextState(L10n.Nighthawk.TransactionDetails.viewTxDetails)
            }
            ButtonState(role: .cancel) {
                TextState(L10n.General.cancel)
            }
        } message: {
            TextState(L10n.Nighthawk.TransactionDetails.leavingWarning(blockExplorerURL?.host() ?? ""))
        }
    }
}
