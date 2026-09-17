//
//  Receive.swift
//  stealth
//
//  DarkFi: Single privacy address only. One receive address per wallet.
//

import ComposableArchitecture
import Generated
import Pasteboard
import Utils

@Reducer
public struct Receive {
    @ObservableState
    public struct State: Equatable {
        public enum Toast {
            case copiedToClipboard
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
        case showQrCodeTapped

        public enum Delegate: Equatable {
            case showAddresses
        }
    }

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.pasteboard) var pasteboard

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
                let address = state.privacyAddress
                pasteboard.setString(address.redacted)
                state.toast = .copiedToClipboard
                return .none
            case .showQrCodeTapped:
                return .send(.delegate(.showAddresses))
            }
        }
    }

    public init () {}
}
