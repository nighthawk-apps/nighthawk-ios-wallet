//
//  TransactionAmountTextFieldStore.swift
//  secant-testnet
//
//  Created by Adam Stener on 4/5/22.
//

import ComposableArchitecture
import ZcashLightClientKit
import Foundation
import Utils
import NumberFormatter

typealias TransactionAmountTextFieldStore = Store<TransactionAmountTextFieldReducer.State, TransactionAmountTextFieldReducer.Action>

struct TransactionAmountTextFieldReducer: ReducerProtocol {
    struct State: Equatable {
        var amount = RedactableInt64(0)
        var currencySelectionState: CurrencySelectionReducer.State
        var maxValue = RedactableInt64(0)
        var textFieldState: TCATextFieldReducer.State
        // TODO: [#311] - Get the ZEC price from the SDK, https://github.com/zcash/secant-ios-wallet/issues/311
        var zecPrice = Decimal(140.0)

        var isMax: Bool {
            return amount == maxValue
        }
    }

    enum Action: Equatable {
        case clearValue
        case currencySelection(CurrencySelectionReducer.Action)
        case setMax
        case textField(TCATextFieldReducer.Action)
        case updateAmount
    }
    
    @Dependency(\.numberFormatter) var numberFormatter
    
    var body: some ReducerProtocol<State, Action> {
        Scope(state: \.currencySelectionState, action: /Action.currencySelection) {
            CurrencySelectionReducer()
        }

        Scope(state: \.textFieldState, action: /Action.textField) {
            TCATextFieldReducer()
        }

        Reduce { state, action in
            switch action {
            case .setMax:
                let maxValueAsZec = Decimal(state.maxValue.data) / Decimal(Zatoshi.Constants.oneZecInZatoshi)
                let currencyType = state.currencySelectionState.currencyType
                let maxCurrencyConvertedValue: NSDecimalNumber = currencyType == .zec ?
                NSDecimalNumber(decimal: maxValueAsZec).roundedZec :
                NSDecimalNumber(decimal: maxValueAsZec * state.zecPrice).roundedZec
                
                let decimalString = numberFormatter.string(maxCurrencyConvertedValue) ?? ""
                
                state.textFieldState.text = "\(decimalString)".redacted
                return EffectTask(value: .updateAmount)

            case .clearValue:
                state.textFieldState.text = "".redacted
                return .none

            case .textField(.set):
                return EffectTask(value: .updateAmount)
                
            case .updateAmount:
                guard let number = numberFormatter.number(state.textFieldState.text.data) else {
                    state.amount = Int64(0).redacted
                    return .none
                }
                switch state.currencySelectionState.currencyType {
                case .zec:
                    state.amount = NSDecimalNumber(
                        decimal: number.decimalValue * Decimal(Zatoshi.Constants.oneZecInZatoshi)
                    ).roundedZec.int64Value.redacted
                case .usd:
                    let decimal = (number.decimalValue / state.zecPrice) * Decimal(Zatoshi.Constants.oneZecInZatoshi)
                    state.amount = NSDecimalNumber(decimal: decimal).roundedZec.int64Value.redacted
                }
                return .none
                
            case .currencySelection:
                guard let number = numberFormatter.number(state.textFieldState.text.data) else {
                    state.amount = Int64(0).redacted
                    return .none
                }
                
                let currencyType = state.currencySelectionState.currencyType
                
                let newValue = currencyType == .zec ?
                number.decimalValue / state.zecPrice :
                number.decimalValue * state.zecPrice
                
                let decimalString = numberFormatter.string(NSDecimalNumber(decimal: newValue)) ?? ""
                state.textFieldState.text = "\(decimalString)".redacted
                return EffectTask(value: .updateAmount)
            }
        }
    }
}

// MARK: - Placeholders

extension TransactionAmountTextFieldReducer.State {
    static let placeholder = TransactionAmountTextFieldReducer.State(
        currencySelectionState: CurrencySelectionReducer.State(),
        textFieldState: .placeholder
    )

    static let amount = TransactionAmountTextFieldReducer.State(
        currencySelectionState: CurrencySelectionReducer.State(),
        textFieldState: .amount
    )
}

extension TransactionAmountTextFieldStore {
    static let placeholder = TransactionAmountTextFieldStore(
        initialState: .placeholder,
        reducer: TransactionAmountTextFieldReducer()
    )
}
