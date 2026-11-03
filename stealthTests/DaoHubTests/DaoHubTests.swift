//
//  DaoHubTests.swift
//  stealthTests
//
//  Tests for DaoHub reducer — navigation, loading, error states.
//

import XCTest
import ComposableArchitecture
import SDKSynchronizer
import Utils
@testable import stealth_testnet

@MainActor
class DaoHubTests: XCTestCase {
    
    // MARK: - Initial State
    
    func testInitialState() {
        let state = DaoHub.State()
        XCTAssertEqual(state.screen, .hub)
        XCTAssertFalse(state.isLoading)
        XCTAssertNil(state.errorMessage)
        XCTAssertTrue(state.daos.isEmpty)
        XCTAssertTrue(state.proposals.isEmpty)
        XCTAssertNil(state.selectedDao)
        XCTAssertNil(state.proposalDetail)
    }
    
    // MARK: - Hub Loading
    
    func testLoadHub_SetsLoadingThenClears() async throws {
        let store = TestStore(
            initialState: DaoHub.State(),
            reducer: DaoHub.init
        ) {
            $0.sdkSynchronizer.isWalletPrepared = { true }
            $0.sdkSynchronizer.refreshNow = { }
            $0.sdkSynchronizer.listDaos = { [] }
            $0.sdkSynchronizer.latestState = {
                SynchronizerState(syncStatus: .upToDate)
            }
        }
        
        await store.send(.loadHub) { state in
            state.isLoading = true
            state.errorMessage = nil
            state.screen = .hub
        }
        
        await store.receive(.hubLoaded([])) { state in
            state.isLoading = false
            state.daos = []
        }
    }
    
    func testHubLoaded_PopulatesDaos() async throws {
        let store = TestStore(
            initialState: DaoHub.State(),
            reducer: DaoHub.init
        )
        
        let daos: [DaoBrief] = [
            DaoBrief(
                name: "TestDAO",
                bullaB58: "bulla1",
                govTokenId: "DRK",
                quorumDisplay: "100.00",
                proposerLimitDisplay: "10.00",
                approvalRatioPercent: 60.0,
                mintHeight: 1234,
                canPropose: true,
                canVote: true,
                canExec: false
            )
        ]
        
        await store.send(.hubLoaded(daos)) { state in
            state.isLoading = false
            state.daos = daos
        }
    }
    
    func testLoadHub_WhenWalletNotSynced_AttemptsRefresh() async {
        let store = TestStore(
            initialState: DaoHub.State(),
            reducer: DaoHub.init
        ) {
            $0.sdkSynchronizer.isWalletPrepared = { true }
            $0.sdkSynchronizer.refreshNow = { }
            $0.sdkSynchronizer.listDaos = { [] }
            $0.sdkSynchronizer.latestState = {
                SynchronizerState(syncStatus: .syncing(progress: 0.4))
            }
        }
        
        await store.send(.loadHub) { state in
            state.isLoading = true
            state.errorMessage = nil
            state.screen = .hub
        }

        await store.receive(.hubLoaded([])) { state in
            state.isLoading = false
            state.daos = []
        }
    }

    func testLoadHub_WhenWalletNotPrepared_ShowsMessage() async {
        let store = TestStore(
            initialState: DaoHub.State(),
            reducer: DaoHub.init
        ) {
            $0.sdkSynchronizer.isWalletPrepared = { false }
        }

        await store.send(.loadHub) { state in
            state.isLoading = false
            state.errorMessage = "Wallet is not ready yet. Finish setup or wait for the wallet to initialize."
        }
    }
    
    // MARK: - DAO Detail Navigation
    
    func testDaoSelected_NavigatesToDetail() async throws {
        let store = TestStore(
            initialState: DaoHub.State(),
            reducer: DaoHub.init
        ) {
            $0.sdkSynchronizer.isWalletPrepared = { true }
            $0.sdkSynchronizer.refreshNow = { }
            $0.sdkSynchronizer.listProposals = { _ in [] }
            $0.sdkSynchronizer.latestState = {
                SynchronizerState(syncStatus: .upToDate)
            }
        }
        
        await store.send(.daoSelected("TestDAO")) { state in
            state.isLoading = true
            state.screen = .daoDetail("TestDAO")
        }
        
        await store.receive(.daoLoaded(nil, [])) { state in
            state.isLoading = false
            state.selectedDao = nil
            state.proposals = []
            state.errorMessage = "DAO not found"
        }
    }
    
    // MARK: - Proposal Detail Navigation
    
    func testProposalSelected_NavigatesToProposalDetail() async throws {
        let store = TestStore(
            initialState: DaoHub.State(),
            reducer: DaoHub.init
        ) {
            $0.sdkSynchronizer.isWalletPrepared = { true }
            $0.sdkSynchronizer.refreshNow = { }
            $0.sdkSynchronizer.getProposal = { _ in nil }
            $0.sdkSynchronizer.latestState = {
                SynchronizerState(syncStatus: .upToDate)
            }
        }
        
        await store.send(.proposalSelected("bulla123")) { state in
            state.isLoading = true
            state.screen = .proposalDetail("bulla123")
        }
        
        await store.receive(.proposalLoaded(nil)) { state in
            state.isLoading = false
            state.proposalDetail = nil
            state.errorMessage = "Proposal not found"
        }
    }
    
    // MARK: - Back Navigation
    
    func testBackFromDaoDetail_ReturnsToHub() async throws {
        var initialState = DaoHub.State()
        initialState.screen = .daoDetail("TestDAO")
        
        let store = TestStore(
            initialState: initialState,
            reducer: DaoHub.init
        )
        
        await store.send(.backTapped) { state in
            state.screen = .hub
        }
    }
    
    // MARK: - Error Handling
    
    func testErrorOccurred_SetsMessage() async throws {
        let store = TestStore(
            initialState: DaoHub.State(),
            reducer: DaoHub.init
        )
        
        await store.send(.errorOccurred("Native library unavailable")) { state in
            state.isLoading = false
            state.errorMessage = "Native library unavailable"
        }
    }

    func testSubmitCreate_PassesDistinctLimitsAndReloadsHub() async {
        let created = LockIsolated<(String, String, String, String, Double, String)?>(nil)
        let store = TestStore(
            initialState: DaoHub.State(),
            reducer: DaoHub.init
        ) {
            $0.sdkSynchronizer.isWalletPrepared = { true }
            $0.sdkSynchronizer.refreshNow = { }
            $0.sdkSynchronizer.listDaos = { [] }
            $0.sdkSynchronizer.latestState = {
                SynchronizerState(syncStatus: .upToDate)
            }
            $0.sdkSynchronizer.daoCreate = { name, limit, quorum, early, ratio, token in
                created.setValue((name, limit, quorum, early, ratio, token))
                return "created"
            }
        }

        await store.send(.submitCreate("Guild", "2", "5", "3", 0.5, "DRK")) { state in
            state.actionInProgress = true
            state.actionResult = nil
        }

        await store.receive(.proposalSubmitted(.success("Group submitted"), .hub)) { state in
            state.actionInProgress = false
            state.actionResult = .success("Group submitted")
        }

        await store.receive(.loadHub) { state in
            state.isLoading = true
            state.errorMessage = nil
            state.screen = .hub
        }

        await store.receive(.hubLoaded([])) { state in
            state.isLoading = false
            state.daos = []
        }

        XCTAssertEqual(created.value?.1, "2")
        XCTAssertEqual(created.value?.2, "5")
        XCTAssertEqual(created.value?.3, "3")
    }

    func testSubmitCreate_IgnoredWhileActionInProgress() async {
        var initial = DaoHub.State()
        initial.actionInProgress = true
        let store = TestStore(initialState: initial, reducer: DaoHub.init)

        await store.send(.submitCreate("Guild", "2", "5", "", 0.5, "DRK"))
    }

    func testDaoSelected_ResetsTreasuryBeforeLoad() async {
        var initial = DaoHub.State()
        initial.treasuryLine = "other-dao"
        initial.mintAuthorities = [
            MintAuthorityBrief(tokenId: "tok", alias: "Old", frozen: false)
        ]
        initial.daos = [
            DaoBrief(
                name: "Next",
                bullaB58: "b",
                govTokenId: "DRK",
                quorumDisplay: "1",
                proposerLimitDisplay: "1",
                approvalRatioPercent: 67,
                mintHeight: 0,
                canPropose: true,
                canVote: true,
                canExec: true
            )
        ]
        let store = TestStore(initialState: initial, reducer: DaoHub.init) {
            $0.sdkSynchronizer.listProposals = { _ in [] }
            $0.sdkSynchronizer.daoTreasury = { _ in "treasury" }
            $0.sdkSynchronizer.listMintAuthorities = { [] }
        }

        await store.send(.daoSelected("Next")) { state in
            state.isLoading = true
            state.screen = .daoDetail("Next")
            state.proposals = []
            state.treasuryLine = "Not scanned yet"
            state.mintAuthorities = []
        }

        await store.receive(.daoLoaded(initial.daos[0], [])) { state in
            state.isLoading = false
            state.selectedDao = initial.daos[0]
            state.proposals = []
        }

        await store.receive(.treasuryLoaded("treasury")) { state in
            state.treasuryLine = "treasury"
        }
        await store.receive(.authoritiesLoaded([]))
    }
}
