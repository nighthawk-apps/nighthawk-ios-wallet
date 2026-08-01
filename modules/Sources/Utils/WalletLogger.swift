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
        #if DEBUG
        logger.debug("\(scrub(message))")
        #endif
    }

    public static func info(_ message: String, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        logger.info("\(scrub(message))")
    }

    public static func event(_ message: String, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        logger.log("\(scrub(message))")
    }

    public static func warn(_ message: String, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        logger.warning("\(scrub(message))")
    }

    public static func error(_ message: String, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        logger.error("\(scrub(message))")
    }
}
