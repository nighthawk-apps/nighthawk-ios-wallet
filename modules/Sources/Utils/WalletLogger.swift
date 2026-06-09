//
//  WalletLogger.swift
//  stealth
//
//  Created by Lukáš Korba on 23.01.2023.
//

import Foundation
import os

public enum LoggerProxy {
    private static let logger = os.Logger(subsystem: "com.nighthawkapps.wallet", category: "wallet")
    
    public static func debug(_ message: String, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        logger.debug("\(message)")
    }
    
    public static func info(_ message: String, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        logger.info("\(message)")
    }
    
    public static func event(_ message: String, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        logger.log("\(message)")
    }
    
    public static func warn(_ message: String, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        logger.warning("\(message)")
    }
    
    public static func error(_ message: String, file: StaticString = #file, function: StaticString = #function, line: Int = #line) {
        logger.error("\(message)")
    }
}
