import ComposableArchitecture
import Pasteboard
import SwiftUI
import UIComponents
import Utils

@Reducer
public struct RequestMoney {
    @ObservableState
    public struct State: Equatable {
        public var address: String
        public var amount: String = ""
        public var memo: String = ""
        public var showCloseButton: Bool

        public var uri: String {
            DrkPaymentUri.encode(
                address: address,
                amount: amount.isEmpty ? nil : amount,
                memo: memo.isEmpty ? nil : memo
            ) ?? ""
        }

        public init(address: String, showCloseButton: Bool = false) {
            self.address = address
            self.showCloseButton = showCloseButton
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case closeButtonTapped
        case copyUriTapped
    }

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.pasteboard) var pasteboard

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .closeButtonTapped:
                return .run { _ in await self.dismiss() }
            case .copyUriTapped:
                guard !state.uri.isEmpty else { return .none }
                pasteboard.setString(state.uri.redacted)
                return .none
            }
        }
    }

    public init() {}
}
