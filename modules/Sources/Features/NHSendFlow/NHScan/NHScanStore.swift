//
//  NHScanStore.swift
//  
//
//  Created by Matthew Watt on 7/22/23.
//

import CaptureDevice
import ComposableArchitecture
import URIParser
import Utils
import ZcashLightClientKit

public typealias NHScanStore = Store<NHScanReducer.State, NHScanReducer.Action>
public typealias NHScanViewStore = ViewStore<NHScanReducer.State, NHScanReducer.Action>

public struct NHScanReducer: ReducerProtocol {
    public struct State: Equatable {
        public enum ScanStatus: Equatable {
            case failed
            case value(RedactableString)
            case unknown
        }
        
        public var scanStatus: ScanStatus = .unknown
        public var scannedValue: String? {
            guard case let .value(scannedValue) = scanStatus else {
                return nil
            }
            
            return scannedValue.data
        }
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case backButtonTapped
        case onAppear
        case onDisappear
        case found(RedactableString)
        case scanFailed
        case scan(RedactableString)
    }
    
    private enum CancelId { case timer }
    
    let networkType: NetworkType
    @Dependency(\.captureDevice) var captureDevice
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.uriParser) var uriParser
    
    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .run { _ in await self.dismiss() }
            case .onAppear:
                // reset the values
                state.scanStatus = .unknown
                return .none
                
            case .onDisappear:
                return .cancel(id: CancelId.timer)
                
            case .found:
                return .none
                
            case .scanFailed:
                state.scanStatus = .failed
                return .none
                
            case .scan(let code):
                // the logic for the same scanned code is skipped until some new code
                if let prevCode = state.scannedValue, prevCode == code.data {
                    return .none
                }
                if uriParser.isValidURI(code.data, networkType) {
                    state.scanStatus = .value(code)
                    // once valid URI is scanned we want to start the timer to deliver the code
                    // any new code cancels the schedule and fires new one
                    return .concatenate(
                        EffectTask.cancel(id: CancelId.timer),
                        EffectTask(value: .found(code))
                            .delay(for: 1.0, scheduler: mainQueue)
                            .eraseToEffect()
                            .cancellable(id: CancelId.timer, cancelInFlight: true)
                    )
                } else {
                    state.scanStatus = .failed
                }
                return .cancel(id: CancelId.timer)
            }
        }
    }
    
    public init(networkType: NetworkType) {
        self.networkType = networkType
    }
}