//
//  Scan.swift
//
//
//  Created by Matthew Watt on 7/22/23.
//

import CaptureDevice
import ComposableArchitecture
import DerivationTool
import Models
import UIComponents
import URIParser
import Utils

@Reducer
public struct Scan {
    @ObservableState
    public struct State: Equatable {
        public var backButtonType: NighthawkBackButtonType
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
        case scan(RedactableString)
        case scanFailed

        public enum Delegate: Equatable {
            case goHome
            case handleParseResult(QRCodeParseResult)
        }
    }

    private enum CancelId { case timer }

    @Dependency(\.captureDevice) var captureDevice
    @Dependency(\.continuousClock) var clock
    @Dependency(\.derivationTool) var derivationTool
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.uriParser) var uriParser

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
            case .scanFailed:
                state.scanStatus = .failed
                return .none

            case .scan(let code):
                // the logic for the same scanned code is skipped until some new code
                if let prevCode = state.scannedValue, prevCode == code.data {
                    return .none
                }

                let network = DarkfiNetwork.activeLabel
                var parseResult = uriParser.parseZaddrOrZIP321(code.data, network)
                if let invite = NighthawkContacts.parseInvite(code.data),
                   code.data.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().hasPrefix("nighthawk://contact") {
                    _ = NighthawkContactStore.upsert(invite)
                    parseResult.contactInvite = invite
                    if let addr = invite.walletAddress, derivationTool.isDarkFiAddress(addr, network) {
                        parseResult.address = addr
                    }
                } else if derivationTool.isDarkFiAddress(code.data, network) {
                    parseResult.address = code.data
                }

                if !parseResult.address.isEmpty || parseResult.contactInvite != nil {
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
                    state.scanStatus = .failed
                    return .none
                }
            }
        }
    }

    public init() {}
}
