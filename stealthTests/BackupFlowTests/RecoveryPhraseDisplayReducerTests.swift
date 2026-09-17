import XCTest
import ComposableArchitecture
import RecoveryPhraseDisplay
@testable import stealth_testnet

@MainActor
final class RecoveryPhraseDisplayReducerTests: XCTestCase {
    func testContinueDoesNothingUntilPhraseIsConfirmed() async {
        let store = TestStore(
            initialState: RecoveryPhraseDisplay.State(flow: .onboarding)
        ) {
            RecoveryPhraseDisplay()
        } withDependencies: {
            $0.userStoredPreferences.setIsUserBackupComplete = { _ in
                XCTFail("backup must not complete before the confirmation checkbox")
            }
        }

        await store.send(.continuePressed)
    }

    func testContinueAfterConfirmMarksBackupAndShowsOnboarding() async {
        var backupComplete = false
        var state = RecoveryPhraseDisplay.State(flow: .onboarding)
        state.isConfirmSeedPhraseWrittenChecked = true

        let store = TestStore(initialState: state) {
            RecoveryPhraseDisplay()
        } withDependencies: {
            $0.userStoredPreferences.setIsUserBackupComplete = { complete in
                backupComplete = complete
            }
            $0.userStoredPreferences.hasCompletedOnboarding = { false }
        }

        await store.send(.continuePressed) {
            $0.isOpeningWallet = true
        }
        await store.receive(.delegate(.showOnboardingCarousel))
        XCTAssertTrue(backupComplete)
    }

    func testContinueAfterOnboardingLaunchesWallet() async {
        var backupComplete = false
        var state = RecoveryPhraseDisplay.State(flow: .onboarding)
        state.isConfirmSeedPhraseWrittenChecked = true

        let store = TestStore(initialState: state) {
            RecoveryPhraseDisplay()
        } withDependencies: {
            $0.userStoredPreferences.setIsUserBackupComplete = { complete in
                backupComplete = complete
            }
            $0.userStoredPreferences.hasCompletedOnboarding = { true }
        }

        await store.send(.continuePressed) {
            $0.isOpeningWallet = true
        }
        await store.receive(.delegate(.initializeSDKAndLaunchWallet))
        XCTAssertTrue(backupComplete)
    }
}
