//
//  TransactionDetail.swift
//  
//
//  Created by Matthew Watt on 7/14/23.
//

import ComposableArchitecture
import Foundation
import Generated
import Models
import UIComponents
import UIKit
import ZcashLightClientKit

public struct TransactionDetail: ReducerProtocol {
    public struct State: Equatable {
        @PresentationState public var alert: AlertState<Action>?
        public var latestMinedHeight: BlockHeight? = .zero
        public var requiredTransactionConfirmations: Int = .zero
        public var transaction: TransactionState = .placeholder()
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case alert(PresentationAction<Action>)
        case warnBeforeLeavingApp(URL?)
        case openBlockExplorer(URL?)
        case onAppear
    }
    
    public init () {}
    
    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .alert(.presented(let action)):
                return EffectTask(value: action)

            case .alert(.dismiss):
                state.alert = nil
                return .none

            case .alert:
                return .none
            case .warnBeforeLeavingApp(let blockExplorerURL):
                state.alert = AlertState.warnBeforeLeavingApp(blockExplorerURL)
                return .none
            case .openBlockExplorer(let blockExplorerURL):
                if let url = blockExplorerURL {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                return .none
            case .onAppear:
                return .none
            }
        }
    }
}

// MARK: Alerts

extension AlertState where Action == TransactionDetail.Action {
    public static func warnBeforeLeavingApp(_ blockExplorerURL: URL?) -> AlertState {
        AlertState {
            TextState(L10n.Nighthawk.TransactionDetails.leavingWallet)
        } actions: {
            ButtonState(action: .openBlockExplorer(blockExplorerURL)) {
                TextState(L10n.Nighthawk.TransactionDetails.viewTxDetails)
            }
            ButtonState(role: .cancel, action: .alert(.dismiss)) {
                TextState(L10n.General.cancel)
            }
        } message: {
            TextState(L10n.Nighthawk.TransactionDetails.leavingWarning(blockExplorerURL?.host() ?? ""))
        }
    }
}
