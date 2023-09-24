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
            do {
                let address = try uAddress?.transparentReceiver().stringEncoded ?? L10n.AddressDetails.Error.cantExtractTransparentAddress
                return address
            } catch {
                return L10n.AddressDetails.Error.cantExtractTransparentAddress
            }
        }

        public var saplingAddress: String {
            do {
                let address = try uAddress?.saplingReceiver().stringEncoded ?? L10n.AddressDetails.Error.cantExtractSaplingAddress
                return address
            } catch {
                return L10n.AddressDetails.Error.cantExtractSaplingAddress
            }
        }
        
        var uAddress: UnifiedAddress?
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case alert(PresentationAction<Alert>)
        case onAppear
        case uAddressChanged(UnifiedAddress?)
        case showSideShiftInstructions
        case showStealthExInstructions
        
        public enum Alert: Equatable {
            case open(URL?)
        }
    }
    
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
            case .onAppear:
                return .run { send in
                    let ua = try? await sdkSynchronizer.getUnifiedAddress(0)
                    await send(.uAddressChanged(ua))
                }
            case .showSideShiftInstructions:
                pasteboard.setString(state.saplingAddress.redacted)
                state.alert = AlertState.showPartnerInstructions(
                    url: partners.sideshiftURL(),
                    partnerName: "SideShift.ai",
                    addressType: "Z-Address",
                    receivingCoin: "Zcash (Shielded)"
                )
                return .none
            case .showStealthExInstructions:
                pasteboard.setString(state.transparentAddress.redacted)
                state.alert = AlertState.showPartnerInstructions(
                    url: partners.stealthexURL(),
                    partnerName: "StealthEx.io",
                    addressType: "T-Address",
                    receivingCoin: "Zcash"
                )
                return .none
            case .uAddressChanged(let uAddress):
                state.uAddress = uAddress
                return .none
            }
        }
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