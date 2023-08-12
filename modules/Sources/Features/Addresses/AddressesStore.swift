//
//  AddressesStore.swift
//  
//
//  Created by Matthew Watt on 7/16/23.
//

import ComposableArchitecture
import Generated
import Pasteboard
import SDKSynchronizer
import ZcashLightClientKit

public typealias AddressesStore = Store<AddressesReducer.State, AddressesReducer.Action>
public typealias AddressesViewStore = ViewStore<AddressesReducer.State, AddressesReducer.Action>

public struct AddressesReducer: ReducerProtocol {
    public struct State: Equatable {
        public enum Destination: String, CaseIterable, Equatable, Hashable {
            case topUp
            case unified
            case sapling
            case transparent
        }
        
        public enum Toast {
            case copiedToClipboard
        }
        
        @BindingState public var toast: Toast?
        @BindingState public var destination: Destination = .unified
        public var uAddress: UnifiedAddress?

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
        
        public init(uAddress: UnifiedAddress? = nil) {
            self.uAddress = uAddress
        }
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case uAddressChanged(UnifiedAddress?)
        case copyTapped(State.Destination)
        case topUpWalletTapped
    }
    
    @Dependency(\.pasteboard) var pasteboard
    @Dependency(\.sdkSynchronizer) var sdkSynchronizer
    
    public init () {}
    
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
            case let .copyTapped(destination):
                switch destination {
                case .transparent:
                    pasteboard.setString(state.transparentAddress.redacted)
                    break
                case .unified:
                    pasteboard.setString(state.unifiedAddress.redacted)
                    break
                case .sapling:
                    pasteboard.setString(state.saplingAddress.redacted)
                    break
                default:
                    break
                }
                state.toast = .copiedToClipboard
                return .none
            case .binding, .topUpWalletTapped:
                return .none
            }
        }
    }
}

// MARK: - Placeholder
extension AddressesReducer.State {
    public static var placeholder: Self {
        .init()
    }
}
