//
//  NHSendFlowStore.swift
//  
//
//  Created by Matthew Watt on 7/19/23.
//

import ComposableArchitecture
import DerivationTool
import Utils
import ZcashLightClientKit

public typealias NHSendFlowStore = Store<NHSendFlowReducer.State, NHSendFlowReducer.Action>
public typealias NHSendFlowViewStore = ViewStore<NHSendFlowReducer.State, NHSendFlowReducer.Action>

public struct NHSendFlowReducer: ReducerProtocol {
    let networkType: NetworkType
    
    public struct Path: ReducerProtocol {
        let networkType: NetworkType
        
        public enum State: Equatable {
            case addMemo(AddMemoReducer.State)
            case recipient(RecipientReducer.State)
            case review(ReviewReducer.State)
            case scan(NHScanReducer.State)
        }
        
        public enum Action: Equatable {
            case addMemo(AddMemoReducer.Action)
            case recipient(RecipientReducer.Action)
            case review(ReviewReducer.Action)
            case scan(NHScanReducer.Action)
        }
        
        public init(networkType: NetworkType) {
            self.networkType = networkType
        }
        
        public var body: some ReducerProtocol<State, Action> {
            Scope(state: /State.addMemo, action: /Action.addMemo) {
                AddMemoReducer()
            }
            
            Scope(state: /State.recipient, action: /Action.recipient) {
                RecipientReducer(networkType: networkType)
            }
            
            Scope(state: /State.review, action: /Action.review) {
                ReviewReducer()
            }
            
            Scope(state: /State.scan, action: /Action.scan) {
                NHScanReducer(networkType: networkType)
            }
        }
    }
    
    
    public struct State: Equatable {
        public var path = StackState<Path.State>()
        public var shieldedBalance: Balance = .zero
        
        @BindingState public var amountToSendInput = "0"
        public var recipient: RedactableString = "".redacted
        public var memo: RedactableString = "".redacted
        
        public var amountToSend: Zatoshi {
            Zatoshi.from(decimalString: amountToSendInput) ?? .zero
        }
        
        public var hasEnteredAmount: Bool {
            amountToSend > .zero
        }
        
        public var hasEnteredRecipient: Bool {
            !recipient.data.isEmpty
        }
        
        public var canSendEnteredAmount: Bool {
            true
            //            amountToSend <= shieldedBalance.data.verified
        }

        public init() {}
    }
    
    public enum Action: BindableAction, Equatable {
        case path(StackAction<Path.State, Path.Action>)
        case binding(BindingAction<State>)
        case topUpWalletTapped
        case continueTapped
        case scanCodeTapped
    }
    
    public init(networkType: NetworkType) {
        self.networkType = networkType
    }
    
    @Dependency(\.derivationTool) var derivationTool
    
    public var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case let .path(.element(id: id, action: .addMemo(.continueOrSkipTapped))):
                guard case let .addMemo(addMemoState) = state.path[id: id]
                else { return .none }
                state.memo = addMemoState.memo
                state.path.append(Path.State.recipient(.init()))
                return .none
            case .path(.element(id: _, action: .recipient(.continueTapped))):
                guard derivationTool.isZcashAddress(state.recipient.data, networkType) else { return .none }
                state.path.append(
                    Path.State.review(
                        .init(
                            amount: state.amountToSend,
                            memo: state.memo,
                            recipient: state.recipient
                        )
                    )
                )
                return .none
            case .path(.element(id: _, action: .recipient(.scanQRCodeTapped))):
                state.path.append(Path.State.scan(.init()))
                return .none
            case let .path(.element(id: _, action: .scan(.found(code)))):
                state.recipient = code
                state.path = StackState(
                    state.path.map { state in
                        if case var .recipient(recipientState) = state {
                            recipientState.recipient = code
                            return Path.State.recipient(recipientState)
                        }
                    
                        return state
                    }
                )
                let _ = state.path.popLast()
                return .none
            case .continueTapped:
                state.path.append(Path.State.addMemo(.init()))
                return .none
            case .scanCodeTapped:
                return .none
            case .topUpWalletTapped:
                return .none
            case .binding, .path:
                return .none
            }
        }
        .forEach(\.path, action: /Action.path) {
            Path(networkType: networkType)
        }
    }
}

// MARK: - Store
extension NHSendFlowStore {
    func stackStore() -> Store<
        StackState<NHSendFlowReducer.Path.State>,
        StackAction<NHSendFlowReducer.Path.State, NHSendFlowReducer.Path.Action>
    > {
        scope(state: \.path, action: { .path($0) })
    }
}

// MARK: - Placeholder
extension NHSendFlowReducer.State {
    public static var placeholder: Self {
        .init()
    }
}
