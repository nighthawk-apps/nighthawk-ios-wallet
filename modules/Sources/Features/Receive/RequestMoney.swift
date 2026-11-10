import ComposableArchitecture
import Models
import Pasteboard
import Utils

@Reducer
public struct RequestMoney {
    @ObservableState
    public struct State: Equatable {
        public var address: String
        public var amount: String = ""
        public var memo: String = ""
        public var showCloseButton: Bool
        public var copied = false

        public var invoice: String {
            PaymentRequestUri.build(
                address: address,
                amount: amount,
                memo: memo
            )
        }

        public init(address: String, showCloseButton: Bool = false) {
            self.address = address
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

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                state.copied = false
                return .none
            case .closeButtonTapped:
                return .run { _ in await self.dismiss() }
            case .copyTapped:
                pasteboard.setString(state.invoice.redacted)
                state.copied = true
                return .none
            }
        }
    }

    public init() {}
}
