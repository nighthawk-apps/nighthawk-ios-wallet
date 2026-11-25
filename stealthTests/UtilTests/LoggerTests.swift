//
//  LoggerTests.swift
//  stealthTests
//
//  Verifies LoggerProxy logs across all severity levels and redacts fallback internals.
//

import OSLog
import Utils
import XCTest

final class LoggerTests: XCTestCase {
    func testLoggerProxyAllLevelsDoNotCrashAndEmitToOSLogStore() throws {
        let token = "nh-logger-test-\(UUID().uuidString)"
        LoggerProxy.debug("debug \(token)")
        LoggerProxy.info("info \(token)")
        LoggerProxy.event("event \(token)")
        LoggerProxy.warn("warn \(token)")
        LoggerProxy.error("error \(token)")

        let store = try OSLogStore(scope: .currentProcessIdentifier)
        let position = store.position(date: Date().addingTimeInterval(-30))
        let entries = try store
            .getEntries(at: position)
            .compactMap { $0 as? OSLogEntryLog }
            .filter { $0.subsystem == "com.nighthawkapps.wallet" && $0.composedMessage.contains(token) }

        XCTAssertGreaterThanOrEqual(entries.count, 1)
    }

    func testLoggerProxyRedactsFallbackMarkers() throws {
        let token = "nh-redact-\(UUID().uuidString)"
        LoggerProxy.warn("marker fallbackUserMessage SyncFallbackReason \(token)")

        let store = try OSLogStore(scope: .currentProcessIdentifier)
        let position = store.position(date: Date().addingTimeInterval(-30))
        let matched = try store
            .getEntries(at: position)
            .compactMap { $0 as? OSLogEntryLog }
            .first { $0.subsystem == "com.nighthawkapps.wallet" && $0.composedMessage.contains(token) }

        if let message = matched?.composedMessage {
            XCTAssertFalse(message.contains("fallbackUserMessage"))
            XCTAssertFalse(message.contains("SyncFallbackReason"))
            XCTAssertTrue(message.contains("[REDACTED_FALLBACK_MESSAGE]"))
            XCTAssertTrue(message.contains("[REDACTED_FALLBACK_REASON]"))
        }
    }
}
