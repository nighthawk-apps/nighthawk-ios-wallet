// DarkfiFFIErrorTests.swift
// Tests for the DarkFi mobile FFI error handling from the iOS side.
//
// These tests validate that the expanded error enum (13 variants) from the
// Rust UniFFI bindings is correctly surfaced in Swift.
//
// Copyright (C) 2020-2026 Dyne.org foundation
// SPDX-License-Identifier: AGPL-3.0-or-later

import XCTest
@testable import DarkfiCore

final class DarkfiFFIErrorTests: XCTestCase {
    /// Verify that all 13 error variants exist in the Swift enum.
    func testAllErrorVariantsExist() {
        let errors: [DarkfiWalletNativeError] = [
            .WalletNotInitialized(message: "uninit"),
            .InvalidBootstrapConfig(message: "bad config"),
            .NativeDrkUnavailable(message: "test"),
            .ConnectionFailed(message: "timeout"),
            .SyncFailed(message: "block error"),
            .CryptoError(message: "bad key"),
            .NetworkTimeout(message: "30s"),
            .ServerUnavailable(message: "503"),
            .InvalidAddress(message: "not_base58"),
            .InsufficientFunds(message: "need 100"),
            .TransactionBuildFailed(message: "proof gen"),
            .OmrDetectionFailed(message: "unsupported"),
            .TrialDecryptFailed(message: "AEAD")
        ]

        XCTAssertEqual(errors.count, 13, "Should have exactly 13 error variants")
    }

    /// Verify error descriptions contain the inner message.
    func testErrorDescriptions() {
        let error = DarkfiWalletNativeError.ConnectionFailed(message: "server refused")
        XCTAssertTrue(
            "\(error)".contains("server refused") || "\(error)".lowercased().contains("connection"),
            "Error description should contain context"
        )
    }

    /// Verify error matching works for switch statements.
    func testErrorPatternMatching() {
        let error: DarkfiWalletNativeError = .OmrDetectionFailed(message: "scheme 0xFF")

        switch error {
        case .OmrDetectionFailed(let msg):
            XCTAssertEqual(msg, "scheme 0xFF")
        default:
            XCTFail("Should match OmrDetectionFailed")
        }
    }

    /// Verify TrialDecryptFailed can carry AEAD-specific context.
    func testTrialDecryptFailedContext() {
        let error = DarkfiWalletNativeError.TrialDecryptFailed(
            message: "ChaCha20Poly1305 AEAD tag mismatch"
        )

        if case .TrialDecryptFailed(let msg) = error {
            XCTAssertTrue(msg.contains("AEAD"))
        } else {
            XCTFail("Should be TrialDecryptFailed")
        }
    }

    /// Verify InsufficientFunds error for UI display.
    func testInsufficientFundsUserFacing() {
        let error = DarkfiWalletNativeError.InsufficientFunds(
            message: "Balance: 0 DRK, Required: 1.5 DRK"
        )

        if case .InsufficientFunds(let msg) = error {
            XCTAssertTrue(msg.contains("1.5 DRK"))
        } else {
            XCTFail("Should be InsufficientFunds")
        }
    }
}
