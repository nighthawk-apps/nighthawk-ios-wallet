//
//  Scan.swift
//  
//
//  Created by Matthew Watt on 7/22/23.
//

import CaptureDevice
import ComposableArchitecture
import DerivationTool
import UIComponents
import UNSClient
import URIParser
import UserPreferencesStorage
import Utils
import ZcashLightClientKit

@Reducer
public struct Scan {
    public struct State: Equatable {
        public var backButtonType: NighthawkBackButtonType
        public var isResolvingUNS = false
        public var scanStatus: ScanStatus = .unknown
        public var scannedValue: String? {
            guard case let .value(scannedValue) = scanStatus else {
                return nil
            }
            
            return scannedValue.data
        }
        
        public enum ScanStatus: Equatable {
            case failed
            case value(RedactableString)
            case unknown
        }
        
        public init(backButtonType: NighthawkBackButtonType = .back) {
            self.backButtonType = backButtonType
        }
    }
    
    public enum Action: Equatable {
        case backButtonTapped
        case delegate(Delegate)
        case onAppear
        case resolveUNSFinished
        case resolveUNSRequest
        case resolveUNSSuccess(String)
        case scan(RedactableString)
        case scanFailed
        
        public enum Delegate: Equatable {
            case goHome
            case handleParseResult(QRCodeParseResult)
        }
    }
    
    private enum CancelId { case timer }
    
    let networkType: NetworkType
    @Dependency(\.captureDevice) var captureDevice
    @Dependency(\.continuousClock) var clock
    @Dependency(\.derivationTool) var derivationTool
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.unsClient) var unsClient
    @Dependency(\.uriParser) var uriParser
    @Dependency(\.userStoredPreferences) var userStoredPreferences
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                if state.backButtonType == .back {
                    return .run { _ in await self.dismiss() }
                } else {
                    return .send(.delegate(.goHome))
                }
            case .delegate:
                return .none
            case .onAppear:
                // reset the values
                state.scanStatus = .unknown
                return .none
                
            case .resolveUNSFinished:
                state.isResolvingUNS = false
                state.scanStatus = .failed
                return .none
            case .resolveUNSRequest:
                state.isResolvingUNS = true
                return .none
            case let .resolveUNSSuccess(resolved):
                state.isResolvingUNS = false
                if derivationTool.isZcashAddress(resolved, networkType) {
                    state.scanStatus = .value(resolved.redacted)
                    let result = QRCodeParseResult(memo: nil, amount: nil, address: resolved)
                    // once valid URI is scanned *and* resolved we want to start the timer to deliver the code
                    // any new code cancels the schedule and fires new one
                    return .concatenate(
                        .cancel(id: CancelId.timer),
                        .run { send in
                            try await clock.sleep(for: .seconds(1))
                            await send(.delegate(.handleParseResult(result)))
                        }
                        .cancellable(id: CancelId.timer, cancelInFlight: true)
                    )
                } else {
                    state.scanStatus = .failed
                }
                return .none
            case .scanFailed:
                state.scanStatus = .failed
                return .none
                
            case .scan(let code):
                // the logic for the same scanned code is skipped until some new code
                if let prevCode = state.scannedValue, prevCode == code.data {
                    return .none
                }
                
                var parseResult = uriParser.parseZaddrOrZIP321(code.data, networkType)
                if derivationTool.isZcashAddress(code.data, networkType) {
                    parseResult.address = code.data
                }
                
                if !parseResult.address.isEmpty {
                    state.scanStatus = .value(code)
                    // once valid URI is scanned we want to start the timer to deliver the code
                    // any new code cancels the schedule and fires new one
                    return .concatenate(
                        .cancel(id: CancelId.timer),
                        .run { [parseResult] send in
                            try await clock.sleep(for: .seconds(1))
                            await send(.delegate(.handleParseResult(parseResult)))
                        }
                        .cancellable(id: CancelId.timer, cancelInFlight: true)
                    )
                } else {
                    if userStoredPreferences.isUnstoppableDomainsEnabled() {
                        return .run { send in
                            enum CancelID { case resolveUNSDebounce }
                            try await withTaskCancellation(id: CancelID.resolveUNSDebounce, cancelInFlight: true) {
                                try await clock.sleep(for: .seconds(1))
                                await send(.resolveUNSRequest)
                                if let resolved = try? await unsClient.resolveUNSAddress(code.data) {
                                    await send(.resolveUNSSuccess(resolved))
                                    return
                                }
                                
                                await send(.resolveUNSFinished)
                            }
                        }
                    } else {
                        state.scanStatus = .failed
                        return .none
                    }
                }
            }
        }
    }
    
    public init(networkType: NetworkType) {
        self.networkType = networkType
    }
}
