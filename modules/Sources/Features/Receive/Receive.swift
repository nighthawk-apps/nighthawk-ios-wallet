//
//  Receive.swift
//  stealth
//
//  DarkFi: Single privacy address only.
//  No transparent/sapling/unified distinction — DarkFi has one private address
//  with ability to generate more derived addresses.
//

import ComposableArchitecture
import Generated
import Pasteboard
import SDKSynchronizer
import Utils

@Reducer
public struct Receive {
    @ObservableState
    public struct State: Equatable {
        public enum Toast {
            case copiedToClipboard
            case newAddressGenerated
            case generateFailed
        }
        
        public var toast: Toast?
        
        /// DarkFi privacy address — the ONLY address type.
        public var privacyAddress: String {
            uAddress?.stringEncoded ?? "-"
        }
        
        /// Backward-compatible alias used in send flow
        public var unifiedAddress: String { privacyAddress }
        
        var uAddress: UnifiedAddress?
        var showCloseButton: Bool
        /// Newly generated address (shown below primary)
        public var generatedAddress: String?
        public var isGenerating: Bool = false
        
        public init(uAddress: UnifiedAddress?, showCloseButton: Bool = false) {
            self.uAddress = uAddress
            self.showCloseButton = showCloseButton
        }
    }
    
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case closeButtonTapped
        case copyAddressTapped
        case delegate(Delegate)
        case generateNewAddressTapped
        case newAddressGenerated(String)
        case generateAddressFailed
        case showQrCodeTapped
        
        public enum Delegate: Equatable {
            case showAddresses
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
            case .delegate:
                return .none
            case .closeButtonTapped:
                return .run { _ in await self.dismiss() }
            case .copyAddressTapped:
                let address = state.generatedAddress ?? state.privacyAddress
                pasteboard.setString(address.redacted)
                state.toast = .copiedToClipboard
                return .none
            case .generateNewAddressTapped:
                state.isGenerating = true
                return .run { send in
                    do {
                        let newAddr = try await sdkSynchronizer.generateNewAddress()
                        await send(.newAddressGenerated(newAddr))
                    } catch {
                        print("[Receive] Failed to generate new address: \(error)")
                        await send(.generateAddressFailed)
                    }
                }
            case let .newAddressGenerated(address):
                state.isGenerating = false
                state.generatedAddress = address
                state.toast = .newAddressGenerated
                return .none
            case .generateAddressFailed:
                state.isGenerating = false
                state.toast = .generateFailed
                return .none
            case .showQrCodeTapped:
                return .send(.delegate(.showAddresses))
            }
        }
    }
    
    public init () {}
}
