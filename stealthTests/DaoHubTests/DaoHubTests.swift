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
}
