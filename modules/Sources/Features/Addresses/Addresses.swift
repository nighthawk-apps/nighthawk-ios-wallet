//
//  Addresses.swift
//  stealth
//
//  DarkFi: one receive address.
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
        @CasePathable
        public enum Toast {
            case copiedToClipboard
        }

        public var toast: Toast?
        public var receiveAddress: DarkfiAddress?
        public var showCloseButton: Bool

        public var privacyAddress: String {
            receiveAddress?.stringEncoded ?? L10n.Nighthawk.WalletTab.Addresses.loading
        }

        public init(receiveAddress: DarkfiAddress?, showCloseButton: Bool = false) {
            self.receiveAddress = receiveAddress
            self.showCloseButton = showCloseButton
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case closeButtonTapped
        case copyTapped
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
                pasteboard.setString(state.privacyAddress.redacted)
                state.toast = .copiedToClipboard
                return .none
            }
        }
    }

    public init () {}
}
