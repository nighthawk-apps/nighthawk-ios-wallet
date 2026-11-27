import Foundation
import os

public enum LoggerProxy {
    private static let logger = os.Logger(subsystem: "com.nighthawkapps.wallet", category: "wallet")

    private static func scrub(_ message: String) -> String {
        var scrubbed = message
        if scrubbed.contains("fallbackUserMessage") {
            scrubbed = scrubbed.replacingOccurrences(of: "fallbackUserMessage", with: "[REDACTED_FALLBACK_MESSAGE]")
        }
        if scrubbed.contains("SyncFallbackReason") {
            scrubbed = scrubbed.replacingOccurrences(of: "SyncFallbackReason", with: "[REDACTED_FALLBACK_REASON]")
        }
        return scrubbed
    }

    public static func debug(_ message: String, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        emit(message)
    }

    public static func info(_ message: String, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        emit(message)
    }

    public static func event(_ message: String, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        emit(message)
    }

    public static func warn(_ message: String, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        emit(message)
    }

    public static func error(_ message: String, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        emit(message)
    }

    /// Release builds do not write to the unified log.
    private static func emit(_ message: String) {
        #if DEBUG
        logger.info("\(scrub(message))")
        #endif
    }
}
