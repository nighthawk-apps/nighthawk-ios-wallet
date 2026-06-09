//
//  Addresses.swift
//  stealth
//
//  DarkFi: Single privacy address only.
//

import ComposableArchitecture
import Generated
import Pasteboard
import SDKSynchronizer
import UIComponents
import Utils

@Reducer
public struct Addresses {
    @ObservableState
    public struct State: Equatable {
        public enum Destination: String, CaseIterable, Equatable, Hashable {
            case topUp
            case unified
            case sapling
            case transparent
        }
        
        @CasePathable
        public enum Toast {
            case copiedToClipboard
        }
        
        public var toast: Toast?
        public var destination: Destination = .unified
        public var uAddress: UnifiedAddress?
        public var showCloseButton: Bool
        
        /// DarkFi privacy address — the ONLY address type.
        public var privacyAddress: String {
            uAddress?.stringEncoded ?? L10n.Nighthawk.WalletTab.Addresses.loading
        }
        
        // All address types return the same privacy address
        public var unifiedAddress: String { privacyAddress }
        public var transparentAddress: String { privacyAddress }
        public var saplingAddress: String { privacyAddress }
        
        public init(uAddress: UnifiedAddress?, showCloseButton: Bool = false) {
            self.uAddress = uAddress
            self.showCloseButton = showCloseButton
        }
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case closeButtonTapped
        case copyTapped(State.Destination)
        case delegate(Delegate)
        case topUpWalletTapped
        
        public enum Delegate: Equatable {
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
            case .closeButtonTapped:
                return .run { _ in await self.dismiss() }
            case .copyTapped:
                // All address types are the same DarkFi privacy address
                pasteboard.setString(state.privacyAddress.redacted)
                state.toast = .copiedToClipboard
                return .none
            case .delegate:
                return .none
            case .topUpWalletTapped:
                return .send(.delegate(.showPartners))
            }
        }
    }
    
    public init () {}
}
