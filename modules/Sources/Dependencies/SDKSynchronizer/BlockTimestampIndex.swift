//
//  BlockTimestampIndex.swift
//
//  Block times are not on DrkTransactionRecord. The sync engine writes
//  Documents/darkfi_cache/block_timestamps.json when a compact block's
//  timestamp is known (`{"<height>": <unix seconds>}`). This index reads
//  that file and also remembers broadcast times for transactions this
//  process sent, so a row does not stay "---" once a time exists.
//

import Foundation
import Utils

enum BlockTimestampIndex {
    private static let lock = NSLock()
    private static var blockTimes: [BlockHeight: TimeInterval] = [:]
    private static var txTimes: [String: TimeInterval] = [:]
    private static var loaded = false
    private static var loadedBlockMtime: Date?

    static func timestamp(forBlockHeight height: BlockHeight) -> TimeInterval? {
        lock.lock()
        defer { lock.unlock() }
        loadIfNeeded()
        guard let raw = blockTimes[height], raw > 0 else { return nil }
        return normalize(raw)
    }

    static func timestamp(forTxHash txHash: String) -> TimeInterval? {
        lock.lock()
        defer { lock.unlock() }
        loadIfNeeded()
        guard let raw = txTimes[txHash], raw > 0 else { return nil }
        return normalize(raw)
    }

    static func note(txHash: String, sentAt: TimeInterval) {
        guard sentAt > 0 else { return }
        lock.lock()
        defer { lock.unlock() }
        loadIfNeeded()
        txTimes[txHash] = sentAt
        persistTxTimes()
    }

    /// Drop in-memory maps and the per-wallet tx cache. Rust rewrites
    /// block_timestamps.json during sync, and a wiped wallet must not
    /// persist the previous wallet's tx times into the new cache.
    static func reset() {
        lock.lock()
        defer { lock.unlock() }
        blockTimes = [:]
        txTimes = [:]
        loaded = false
        loadedBlockMtime = nil
        try? FileManager.default.removeItem(at: txFile())
    }

    private static func normalize(_ raw: TimeInterval) -> TimeInterval {
        // Compact-block timestamps are unix seconds. Values past 1e11 are ms.
        raw > 100_000_000_000 ? raw / 1000 : raw
    }

    private static func loadIfNeeded() {
        let mtime = modificationDate(of: blockFile())
        let blockChanged = !loaded || mtime != loadedBlockMtime
        if !loaded {
            txTimes = readStringMap(at: txFile())
        }
        guard blockChanged else { return }
        var heights: [BlockHeight: TimeInterval] = [:]
        for (key, value) in readStringMap(at: blockFile()) {
            if let height = BlockHeight(key), value > 0 {
                heights[height] = value
            }
        }
        blockTimes = heights
        loadedBlockMtime = mtime
        loaded = true
    }

    private static func modificationDate(of url: URL) -> Date? {
        try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date
    }

    private static func readStringMap(at url: URL) -> [String: TimeInterval] {
        guard let data = try? Data(contentsOf: url),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return [:] }
        var result: [String: TimeInterval] = [:]
        for (key, value) in object {
            if let number = value as? NSNumber {
                result[key] = number.doubleValue
            }
        }
        return result
    }

    private static func persistTxTimes() {
        var object: [String: Double] = [:]
        for (key, value) in txTimes {
            object[key] = value
        }
        guard let data = try? JSONSerialization.data(withJSONObject: object) else { return }
        try? FileManager.default.createDirectory(
            at: cacheDirectory(),
            withIntermediateDirectories: true
        )
        try? data.write(to: txFile(), options: .atomic)
    }

    private static func cacheDirectory() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return docs.appendingPathComponent("darkfi_cache", isDirectory: true)
    }

    private static func blockFile() -> URL {
        cacheDirectory().appendingPathComponent("block_timestamps.json")
    }

    private static func txFile() -> URL {
        cacheDirectory().appendingPathComponent("tx_timestamps.json")
    }
}
