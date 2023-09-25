//
//  Receive.swift
//  
//
//  Created by Matthew Watt on 7/15/23.
//

import ComposableArchitecture
import Generated
import Pasteboard
import SDKSynchronizer
import ZcashLightClientKit

public struct Receive: Reducer {
    public struct State: Equatable {
        public enum Toast {
            case copiedToClipboard
        }
        
        @BindingState public var toast: Toast?
        
        public var unifiedAddress: String {
            uAddress?.stringEncoded ?? "-"
        }
        
        public var transparentAddress: String {
            (try? uAddress?.transparentReceiver().stringEncoded) ?? "-"
        }

        public var saplingAddress: String {
            (try? uAddress?.saplingReceiver().stringEncoded) ?? "-"
        }
        
        var uAddress: UnifiedAddress?
        
        public init() {}
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case closeTapped
        case copyTransparentAddressTapped
        case copyUnifiedAddressTapped
        case delegate(Delegate)
        case onAppear
        case showQrCodeTapped
        case topUpWalletTapped
        case uAddressChanged(UnifiedAddress?)
        
        public enum Delegate: Equatable {
            case showAddresses
            case showPartners
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.pasteboard) var pasteboard
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .closeTapped:
                return .run { _ in await self.dismiss() }
            case .copyTransparentAddressTapped:
                pasteboard.setString(state.transparentAddress.redacted)
                state.toast = .copiedToClipboard
                return .none
            case .copyUnifiedAddressTapped:
                pasteboard.setString(state.unifiedAddress.redacted)
                state.toast = .copiedToClipboard
                return .none
            case .delegate:
                return .none
            case .onAppear:
                return .run { send in
                    let ua = try? await sdkSynchronizer.getUnifiedAddress(0)
                    await send(.uAddressChanged(ua))
                }
            case .showQrCodeTapped:
                return .send(.delegate(.showAddresses))
            case .topUpWalletTapped:
                return .send(.delegate(.showPartners))
            case .uAddressChanged(let uAddress):
                state.uAddress = uAddress
                return .none
            }
        }
    }
    
    public init () {}
}
