//
//  TopUpStore.swift
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

public typealias TopUpStore = Store<TopUpReducer.State, TopUpReducer.Action>
public typealias TopUpViewStore = ViewStore<TopUpReducer.State, TopUpReducer.Action>

public struct TopUpReducer: ReducerProtocol {
    public struct State: Equatable {
        @PresentationState public var alert: AlertState<Action>?

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
        case alert(PresentationAction<Action>)
        case onAppear
        case uAddressChanged(UnifiedAddress?)
        case showSideShiftInstructions
        case open(URL?)
        case showStealthExInstructions
    }
    
    @Dependency(\.partners) var partners
    @Dependency(\.pasteboard) var pasteboard
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    
    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .task {
                    return .uAddressChanged(try? await sdkSynchronizer.getUnifiedAddress(0))
                }

            case .uAddressChanged(let uAddress):
                state.uAddress = uAddress
                return .none
            case .alert(.presented(let action)):
                return EffectTask(value: action)
                
            case .alert(.dismiss):
                state.alert = nil
                return .none
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
            case .open(let url):
                if let url {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                return .none
            case .alert:
                return .none
            }
        }
    }
    
    public init() {}
}

// MARK: - Alerts
extension AlertState where Action == TopUpReducer.Action {
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
            ButtonState(role: .cancel, action: .alert(.dismiss)) {
                TextState(L10n.General.cancel)
            }
        } message: {
            TextState(L10n.Nighthawk.TransferTab.TopUpWallet.fundWalletAlertMessage(addressType, receivingCoin, partnerName, addressType))
        }
    }
}

// MARK: - Placeholder
extension TopUpReducer.State {
    public static var placeholder: Self {
        .init()
    }
}
