//
//  HomeTestSupport.swift
//  stealthTests
//
//  Shared dependency overrides for Home reducer and UI tests.
//

import AppVersion
import ComposableArchitecture
import DatabaseFiles
import DiskSpaceChecker
import FileManager
import Foundation
import Home
import LocalAuthenticationClient
import SDKSynchronizer

enum HomeTestSupport {
    static func configureDependencies(_ dependencies: inout DependencyValues) {
        dependencies.dataManager = .mock()
        dependencies.walletStorage = .noOp
        dependencies.databaseFiles = .noOp
        dependencies.fileManager = FileManagerClient(
            url: { _, _, _, _ in URL(fileURLWithPath: NSTemporaryDirectory()) },
            fileExists: { _ in false },
            removeItem: { _ in }
        )
        dependencies.sdkSynchronizer = .inert
        dependencies.diskSpaceChecker = .mockEmptyDisk
        dependencies.mainQueue = .main
        dependencies.continuousClock = ImmediateClock()
        dependencies.date = .constant(Date(timeIntervalSince1970: 1_700_000_000))
        dependencies.uuid = .incrementing
        dependencies.processInfo = .testValue
        dependencies.userStoredPreferences = .liveValue
        dependencies.appVersion = .mock
        dependencies.localAuthenticationContext = LocalAuthContextClientGenerator {
            LocalAuthenticationContextClient(
                biometryType: { .none },
                canEvaluatePolicy: { _ in false },
                evaluatePolicy: { _, _ in false }
            )
        }
    }

    static func makeState(
        selectedTab: Home.State.Tab = .chat,
        synchronizerFailedToStart: Bool = false
    ) -> Home.State {
        withDependencies {
            configureDependencies(&$0)
        } operation: {
            var state = Home.State(receiveAddress: nil)
            state.selectedTab = selectedTab
            state.synchronizerFailedToStart = synchronizerFailedToStart
            return state
        }
    }
}
