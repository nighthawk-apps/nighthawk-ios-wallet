//
//  Task+SleepSeconds.swift
//  
//
//  Created by Matthew Watt on 7/16/23.
//

import Foundation

extension Task where Success == Never, Failure == Never {
    public static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}
