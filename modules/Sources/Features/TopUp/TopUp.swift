//
//  TopUp.swift
//  
//
//  Created by Matthew Watt on 7/17/23.
//

import ComposableArchitecture
import Foundation
import Generated
import Partners
import Pasteboard
import SDKSynchronizer
import UIKit
import ZcashLightClientKit

public struct TopUp: Reducer {
    public struct State: Equatable {
        @PresentationState public var alert: AlertState<Action.Alert>?

        public var transparentAddress: String {
            (try? unifiedAddress?.transparentReceiver().stringEncoded) ?? L10n.Nighthawk.WalletTab.Addresses.loading
        }

        public var saplingAddress: String {
            (try? unifiedAddress?.saplingReceiver().stringEncoded) ?? L10n.Nighthawk.WalletTab.Addresses.loading
        }
        
        var unifiedAddress: UnifiedAddress?
        var showCloseButton: Bool
        
        public init(unifiedAddress: UnifiedAddress?, showCloseButton: Bool = false) {
            self.unifiedAddress = unifiedAddress
            self.showCloseButton = showCloseButton
        }
    }
    
    public enum Action: Equatable {
        case alert(PresentationAction<Alert>)
        case closeButtonTapped
        case showStealthExInstructions
        
        public enum Alert: Equatable {
            case open(URL?)
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.partners) var partners
    @Dependency(\.pasteboard) var pasteboard
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .alert(.presented(.open(url))):
                if let url {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                return .none
            case .alert(.dismiss):
                return .none
            case .closeButtonTapped:
                return .run { _ in await self.dismiss() }
            case .showStealthExInstructions:
                pasteboard.setString(state.transparentAddress.redacted)
                state.alert = AlertState.showPartnerInstructions(
                    url: partners.stealthexURL(),
                    partnerName: "StealthEx.io",
                    addressType: "T-Address",
                    receivingCoin: "Zcash"
                )
                return .none
            }
        }
        .ifLet(\.$alert, action: /Action.alert)
    }
    
    public init() {}
}

// MARK: - Alerts
extension AlertState where Action == TopUp.Action.Alert {
    public static func showPartnerInstructions(
        url: URL?,
        partnerName: String,
        addressType: String,
        receivingCoin: String
    ) -> AlertState {
        AlertState {
            TextState(L10n.Nighthawk.TransferTab.TopUpWallet.fundWalletAlertTitle(partnerName))
        } actions: {
            ButtonState(action: .open(url)) {
                TextState(L10n.Nighthawk.TransferTab.TopUpWallet.openBrowser)
            }
            ButtonState(role: .cancel) {
                TextState(L10n.General.cancel)
            }
        } message: {
            TextState(L10n.Nighthawk.TransferTab.TopUpWallet.fundWalletAlertMessage(addressType, receivingCoin, partnerName, addressType))
        }
    }
}
