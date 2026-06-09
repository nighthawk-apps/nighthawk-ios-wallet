//
//  DaoHubTests.swift
//  stealthTests
//
//  Tests for DaoHub reducer — navigation, loading, error states.
//

import XCTest
import ComposableArchitecture
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
        )
        
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
        
        let daos: [DaoHub.State.DaoSummary] = [
            DaoHub.State.DaoSummary(
                id: "bulla1",
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
    
    // MARK: - DAO Detail Navigation
    
    func testDaoSelected_NavigatesToDetail() async throws {
        let store = TestStore(
            initialState: DaoHub.State(),
            reducer: DaoHub.init
        )
        
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
        )
        
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
    
    // MARK: - Model Tests
    
    func testDaoSummary_RolesLabel() {
        let fullRoles = DaoHub.State.DaoSummary(
            id: "1", name: "DAO", bullaB58: "1", govTokenId: "DRK",
            quorumDisplay: "100", proposerLimitDisplay: "10",
            approvalRatioPercent: 60, mintHeight: nil,
            canPropose: true, canVote: true, canExec: true
        )
        XCTAssertEqual(fullRoles.rolesLabel, "Proposer, Voter, Executor")
        
        let noRoles = DaoHub.State.DaoSummary(
            id: "2", name: "DAO", bullaB58: "2", govTokenId: "DRK",
            quorumDisplay: "100", proposerLimitDisplay: "10",
            approvalRatioPercent: 60, mintHeight: nil,
            canPropose: false, canVote: false, canExec: false
        )
        XCTAssertEqual(noRoles.rolesLabel, "None")
        
        let voterOnly = DaoHub.State.DaoSummary(
            id: "3", name: "DAO", bullaB58: "3", govTokenId: "DRK",
            quorumDisplay: "100", proposerLimitDisplay: "10",
            approvalRatioPercent: 60, mintHeight: nil,
            canPropose: false, canVote: true, canExec: false
        )
        XCTAssertEqual(voterOnly.rolesLabel, "Voter")
    }
    
    func testProposalSummary_StatusLabel() {
        let executed = DaoHub.State.ProposalSummary(
            id: "1", proposalBullaB58: "1", daoName: "DAO", daoBullaB58: "d1",
            authCallCount: 1, durationBlockwindows: 10, creationBlockwindow: 5,
            mintHeight: 100, execHeight: 200, isExecuted: true, summaryLine: ""
        )
        XCTAssertEqual(executed.statusLabel, "Executed")
        
        let active = DaoHub.State.ProposalSummary(
            id: "2", proposalBullaB58: "2", daoName: "DAO", daoBullaB58: "d1",
            authCallCount: 1, durationBlockwindows: 10, creationBlockwindow: 5,
            mintHeight: 100, execHeight: nil, isExecuted: false, summaryLine: ""
        )
        XCTAssertEqual(active.statusLabel, "Active")
        
        let pending = DaoHub.State.ProposalSummary(
            id: "3", proposalBullaB58: "3", daoName: "DAO", daoBullaB58: "d1",
            authCallCount: 1, durationBlockwindows: 10, creationBlockwindow: 5,
            mintHeight: nil, execHeight: nil, isExecuted: false, summaryLine: ""
        )
        XCTAssertEqual(pending.statusLabel, "Pending")
    }
}
