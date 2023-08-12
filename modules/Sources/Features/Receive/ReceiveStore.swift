//
//  ReceiveStore.swift
//  
//
//  Created by Matthew Watt on 7/15/23.
//

import ComposableArchitecture
import Generated
import Pasteboard
import SDKSynchronizer
import ZcashLightClientKit

public typealias ReceiveStore = Store<ReceiveReducer.State, ReceiveReducer.Action>
public typealias ReceiveViewStore = ViewStore<ReceiveReducer.State, ReceiveReducer.Action>

public struct ReceiveReducer: ReducerProtocol {
    public struct State: Equatable {
        public enum Toast {
            case copiedToClipboard
        }
        
        @BindingState public var toast: Toast?
        
        public var unifiedAddress: String {
            uAddress?.stringEncoded ?? L10n.AddressDetails.Error.cantExtractUnifiedAddress
        }
        
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
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case uAddressChanged(UnifiedAddress?)
        case showQrCodeTapped
        case copyUnifiedAddressTapped
        case topUpWalletTapped
        case copyTransparentAddressTapped
    }
    
    @Dependency(\.pasteboard) var pasteboard
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    
    public var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .task {
                    return .uAddressChanged(try? await sdkSynchronizer.getUnifiedAddress(0))
                }

            case .uAddressChanged(let uAddress):
                state.uAddress = uAddress
                return .none
            case .copyUnifiedAddressTapped:
                pasteboard.setString(state.unifiedAddress.redacted)
                state.toast = .copiedToClipboard
                return .none
            case .copyTransparentAddressTapped:
                pasteboard.setString(state.transparentAddress.redacted)
                state.toast = .copiedToClipboard
                return .none
            case .binding, .showQrCodeTapped, .topUpWalletTapped:
                return .none
            }
        }
    }
    
    public init () {}
}

// MARK: - Placeholder
public extension ReceiveReducer.State {
    static var placeholder: Self {
        .init()
    }
}
