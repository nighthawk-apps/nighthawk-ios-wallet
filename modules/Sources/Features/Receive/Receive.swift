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
        
        public init(uAddress: UnifiedAddress?) {
            self.uAddress = uAddress
        }
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case copyTransparentAddressTapped
        case copyUnifiedAddressTapped
        case delegate(Delegate)
        case showQrCodeTapped
        case topUpWalletTapped
        
        public enum Delegate: Equatable {
            case showAddresses
            case showPartners
        }
    }
    
    @Dependency(\.pasteboard) var pasteboard
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .delegate:
                return .none
            case .copyTransparentAddressTapped:
                pasteboard.setString(state.transparentAddress.redacted)
                state.toast = .copiedToClipboard
                return .none
            case .copyUnifiedAddressTapped:
                pasteboard.setString(state.unifiedAddress.redacted)
                state.toast = .copiedToClipboard
                return .none
            case .showQrCodeTapped:
                return .send(.delegate(.showAddresses))
            case .topUpWalletTapped:
                return .send(.delegate(.showPartners))
            }
        }
    }
    
    public init () {}
}
