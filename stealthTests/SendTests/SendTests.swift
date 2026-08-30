//
//  Live UnifOMR e2e against real DarkFi testnet (iOS Simulator).
//  Fail-closed: missing mnemonic, sync failure, or unfunded wallet fails the test.
//

import Darwin
import XCTest
@testable import DarkfiCore

final class LiveUnifOmrE2eTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        executionTimeAllowance = 7200
        continueAfterFailure = false
    }

    func testRestoreSyncAndTransferLiveTestnet() throws {
        let env = ProcessInfo.processInfo.environment
        let mnemonicRaw = loadMnemonic(env: env)
        XCTAssertFalse(mnemonicRaw.isEmpty, "Set TEST_RUNNER_E2E_MNEMONIC or /tmp/e2e_wallets/ios.txt")
        let seedWords = mnemonicRaw.split(whereSeparator: \.isWhitespace).map(String.init)
        XCTAssertEqual(seedWords.count, 22, "Restore phrase must be 22 words")

        let recipient = env["E2E_RECIPIENT"]
            ?? "fRBpXay2wr67PXeZXM6C1pGqyLD9zi9a3Qv4jV2co3gn7jvdgrxYoRkY"
        let amount = env["E2E_AMOUNT"] ?? "0.01"
        let lwd = env["E2E_LWD_URL"] ?? "tcp://127.0.0.1:9067"
        let darkfid = env["E2E_DARKFID_RPC"] ?? "tcp://127.0.0.1:18345"
        let birthday = Int64(env["E2E_BIRTHDAY"] ?? "53200") ?? 53200

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let stamp = Int(Date().timeIntervalSince1970)
        let walletDbPath = docs.appendingPathComponent("darkfi_live_e2e_\(stamp).db").path
        let cachePath = docs.appendingPathComponent("darkfi_live_e2e_cache_\(stamp)").path
        try FileManager.default.createDirectory(atPath: cachePath, withIntermediateDirectories: true)

        let config = DrkBootstrapConfig(
            network: "testnet",
            mnemonic: seedWords,
            walletDbPath: walletDbPath,
            cachePath: cachePath,
            walletPass: "live_e2e_wallet_pass",
            lightwalletServerUrl: lwd,
            birthdayHeight: birthday,
            lightwalletTlsPinSha256: nil,
            useTor: false,
            torSocksPort: 0,
            darkfidRpcUrl: darkfid,
            strictOmrOnly: false
        )

        print("E2E_OPENING_WALLET birthday=\(birthday) lwd=\(lwd)")
        let handle = try DarkfiWalletHandle(config: config)
        let address = try handle.primaryDepositAddress()
        print("WALLET_ADDRESS_DUMP: \(address)")

        try waitUntilSynced(handle: handle)
        let balance = try waitForSpendableBalance(handle: handle, address: address)
        print("E2E_BALANCE_ATOMIC: \(balance)")

        print("E2E_BUILDING_TRANSFER to \(recipient) amount=\(amount)")
        let txHash = try handle.broadcastTransfer(
            txBytes: try handle.buildTransfer(
                recipientAddress: recipient,
                amount: amount,
                tokenId: nil as String?,
                paymentMemo: nil as String?
            ),
            paymentMemo: nil as String?,
            recipientAddress: recipient
        )
        print("TXID_DUMP: \(txHash)")
        XCTAssertEqual(txHash.count, 64, "Expected 32-byte hex tx hash, got \(txHash)")
        XCTAssertTrue(txHash.allSatisfy { $0.isHexDigit })

        try waitForExplorer(txHash: txHash)
        print("E2E_EXPLORER: https://explorer.testnet.dark.fi/tx/\(txHash)")
    }

    private func waitUntilSynced(handle: DarkfiWalletHandle) throws {
        let deadline = Date().addingTimeInterval(1500)
        var lastLog = Date.distantPast
        while Date() < deadline {
            let snap = handle.lightSyncSnapshot()
            if lastLog.timeIntervalSinceNow < -15 {
                print(
                    "E2E_SYNC status=\(snap.status) type=\(snap.syncType) scanned=\(snap.scannedHeight) tip=\(snap.chainTip) omr=\(snap.omrAvailable) msg=\(snap.statusMessage)"
                )
                lastLog = Date()
            }
            if snap.status == "Error" {
                throw NSError(
                    domain: "LiveUnifOmrE2e",
                    code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "UnifOMR sync error: \(snap.statusMessage) fallback=\(snap.fallbackUserMessage)",
                    ]
                )
            }
            let caughtUp = snap.chainTip > 0 && snap.scannedHeight + 2 >= snap.chainTip
            if caughtUp && (snap.status == "Synced" || snap.status == "Degraded") {
                print(
                    "E2E_SYNC_DONE status=\(snap.status) scanned=\(snap.scannedHeight) tip=\(snap.chainTip) omr=\(snap.omrAvailable)"
                )
                return
            }
            Thread.sleep(forTimeInterval: 5)
        }
        let snap = handle.lightSyncSnapshot()
        throw NSError(
            domain: "LiveUnifOmrE2e",
            code: 2,
            userInfo: [
                NSLocalizedDescriptionKey:
                    "Timed out waiting for UnifOMR sync. status=\(snap.status) scanned=\(snap.scannedHeight) tip=\(snap.chainTip) msg=\(snap.statusMessage)",
            ]
        )
    }

    private func waitForSpendableBalance(handle: DarkfiWalletHandle, address: String) throws -> Int64 {
        let deadline = Date().addingTimeInterval(1200)
        var lastLog = Date.distantPast
        while Date() < deadline {
            let balance = try handle.confirmedBalanceAtomic()
            if lastLog.timeIntervalSinceNow < -15 {
                print("E2E_BALANCE_WAIT atomic=\(balance) address=\(address)")
                lastLog = Date()
            }
            if balance > 8_000_000 {
                return balance
            }
            Thread.sleep(forTimeInterval: 5)
        }
        let balance = try handle.confirmedBalanceAtomic()
        throw NSError(
            domain: "LiveUnifOmrE2e",
            code: 3,
            userInfo: [
                NSLocalizedDescriptionKey:
                    "iOS wallet has no spendable testnet funds after UnifOMR sync. Address: \(address) balance=\(balance)",
            ]
        )
    }

    private func loadMnemonic(env: [String: String]) -> String {
        let fromEnv = env["E2E_MNEMONIC"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !fromEnv.isEmpty { return fromEnv }
        let candidates = [
            "/tmp/e2e_wallets/ios.txt",
            "/tmp/e2e_mnemonic.txt",
        ]
        for path in candidates {
            if let raw = try? String(contentsOfFile: path, encoding: .utf8) {
                let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { return trimmed }
            }
        }
        return ""
    }

    private func waitForExplorer(txHash: String) throws {
        let url = URL(string: "https://explorer.testnet.dark.fi/tx/\(txHash)")!
        let sidecar = URL(string: "http://127.0.0.1:18765/tx/\(txHash)")!
        let deadline = Date().addingTimeInterval(3600)
        var attempt = 0
        var minedLogged = false
        while Date() < deadline {
            attempt += 1
            print("E2E_EXPLORER_CHECK attempt=\(attempt) \(url.absoluteString)")
            if isRealExplorerTxPage(url: url, txHash: txHash) || sidecarConfirmed(url: sidecar, txHash: txHash) {
                return
            }
            if !minedLogged && darkfidHasTransaction(txHash) {
                print("E2E_DARKFID_MINED \(txHash) waiting_for_explorer")
                minedLogged = true
            }
            Thread.sleep(forTimeInterval: 15)
        }
        throw NSError(
            domain: "LiveUnifOmrE2e",
            code: 4,
            userInfo: [
                NSLocalizedDescriptionKey:
                    "Transaction \(txHash) did not appear on the public DarkFi explorer",
            ]
        )
    }

    private func httpGet(_ url: URL, timeout: TimeInterval) -> (Int, String) {
        var status = 0
        var body = ""
        let sem = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: url) { data, response, _ in
            status = (response as? HTTPURLResponse)?.statusCode ?? 0
            body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            sem.signal()
        }
        task.resume()
        _ = sem.wait(timeout: .now() + timeout)
        return (status, body)
    }

    private func isRealExplorerTxPage(url: URL, txHash: String) -> Bool {
        let (_, body) = httpGet(url, timeout: 20)
        return isRealExplorerBody(body, txHash: txHash)
    }

    private func sidecarConfirmed(url: URL, txHash: String) -> Bool {
        let (status, body) = httpGet(url, timeout: 8)
        return status == 200 && body.contains("CONFIRMED") && body.localizedCaseInsensitiveContains(txHash)
    }

    private func isRealExplorerBody(_ body: String, txHash: String) -> Bool {
        if body.isEmpty { return false }
        let anubis =
            body.localizedCaseInsensitiveContains("anubis_challenge") ||
            body.localizedCaseInsensitiveContains("Making sure you're not a bot") ||
            body.contains("Making sure you&#39;re not a bot")
        if anubis { return false }
        if body.localizedCaseInsensitiveContains("page not found") { return false }
        if !body.localizedCaseInsensitiveContains(txHash) { return false }
        return body.contains("Transaction Info") || body.contains("From Block") || body.contains("Raw Transaction")
    }

    private func darkfidHasTransaction(_ txHash: String) -> Bool {
        let env = ProcessInfo.processInfo.environment
        let rpc = env["E2E_DARKFID_RPC"] ?? "tcp://127.0.0.1:18345"
        let hostPort = rpc
            .replacingOccurrences(of: "tcp://", with: "")
            .replacingOccurrences(of: "http://", with: "")
        let parts = hostPort.split(separator: ":")
        guard parts.count == 2, let port = UInt16(parts[1]) else { return false }
        let host = String(parts[0])
        var inp = sockaddr_in()
        inp.sin_family = sa_family_t(AF_INET)
        inp.sin_port = port.bigEndian
        guard host.withCString({ inet_pton(AF_INET, $0, &inp.sin_addr) }) == 1 else { return false }
        let fd = socket(AF_INET, SOCK_STREAM, 0)
        guard fd >= 0 else { return false }
        defer { close(fd) }
        var timeout = timeval(tv_sec: 8, tv_usec: 0)
        setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
        setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
        let connected = withUnsafePointer(to: &inp) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard connected == 0 else { return false }
        let req = "{\"jsonrpc\":\"2.0\",\"method\":\"blockchain.get_tx\",\"params\":[\"\(txHash)\"],\"id\":1}\n"
        guard req.withCString({ send(fd, $0, strlen($0), 0) }) > 0 else { return false }
        var buf = [CChar](repeating: 0, count: 512)
        let n = recv(fd, &buf, buf.count - 1, 0)
        guard n > 0 else { return false }
        let resp = String(cString: buf)
        return resp.contains("\"result\"") && !resp.contains("\"error\"")
    }

    private func darkfidPendingHasTransaction(_ txHash: String) -> Bool {
        let env = ProcessInfo.processInfo.environment
        let rpc = env["E2E_DARKFID_RPC"] ?? "tcp://127.0.0.1:18345"
        let hostPort = rpc
            .replacingOccurrences(of: "tcp://", with: "")
            .replacingOccurrences(of: "http://", with: "")
        let parts = hostPort.split(separator: ":")
        guard parts.count == 2, let port = UInt16(parts[1]) else { return false }
        let host = String(parts[0])
        var inp = sockaddr_in()
        inp.sin_family = sa_family_t(AF_INET)
        inp.sin_port = port.bigEndian
        guard host.withCString({ inet_pton(AF_INET, $0, &inp.sin_addr) }) == 1 else { return false }
        let fd = socket(AF_INET, SOCK_STREAM, 0)
        guard fd >= 0 else { return false }
        defer { close(fd) }
        var timeout = timeval(tv_sec: 8, tv_usec: 0)
        setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
        setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
        let connected = withUnsafePointer(to: &inp) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard connected == 0 else { return false }
        let req = "{\"jsonrpc\":\"2.0\",\"method\":\"tx.pending\",\"params\":[],\"id\":1}\n"
        guard req.withCString({ send(fd, $0, strlen($0), 0) }) > 0 else { return false }
        var buf = [CChar](repeating: 0, count: 2048)
        let n = recv(fd, &buf, buf.count - 1, 0)
        guard n > 0 else { return false }
        return String(cString: buf).contains(txHash)
    }
}
