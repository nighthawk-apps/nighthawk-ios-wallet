import Foundation
import os.log

public enum DarkfiChatConnectionState {
    case disconnected
    case connecting
    case connectedDirect
    case connectedViaTor
    case error
}

public class DarkfiChatController {
    public static let shared = DarkfiChatController()
    
    @Published public private(set) var connectionState: DarkfiChatConnectionState = .disconnected
    @Published public private(set) var embeddedNodeStatus: EmbeddedDarkircNodeStatus = .notUsed
    @Published public private(set) var diagnosticDetail: String?
    
    private var watchdogTimer: Timer?
    
    private init() {}
    
    public func connectOrRetry() {
        // Disconnect existing
        connectionState = .connecting
        diagnosticDetail = nil
        
        let useEmbeddedNode = DarkircEmbeddedRunner.hasBundledBinary()
        
        if useEmbeddedNode {
            embeddedNodeStatus = .starting
            // We would write the TOML config here
            let configPath = FileManager.default.temporaryDirectory.appendingPathComponent("darkirc_config.toml").path
            
            let started = DarkircEmbeddedRunner.startDaemon(configPath: configPath)
            if started {
                embeddedNodeStatus = .running
                connectionState = .connectedDirect
                startWatchdog()
            } else {
                embeddedNodeStatus = .failed
                connectionState = .error
            }
        } else {
            // TCP connect to remote host
            connectionState = .connectedDirect
        }
    }
    
    private func startWatchdog() {
        watchdogTimer?.invalidate()
        var failureCount = 0
        
        watchdogTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Simple local port ping to check if darkirc is alive
            self.pingLocalPort(port: 6667) { success in
                if success {
                    failureCount = 0
                } else {
                    failureCount += 1
                    os_log("Zombie watchdog: ping failed (attempt %d)", failureCount)
                    if failureCount >= 2 {
                        os_log("Zombie watchdog: darkirc daemon appears dead/hung, restarting...")
                        DarkircEmbeddedRunner.stopDaemon()
                        self.connectOrRetry()
                    }
                }
            }
        }
    }
    
    private func pingLocalPort(port: UInt16, completion: @escaping (Bool) -> Void) {
        // TCP ping simulation
        let queue = DispatchQueue(label: "com.nighthawk.darkfi.ping")
        queue.async {
            // Very simplified mock ping
            let isAlive = DarkircEmbeddedRunner.isDaemonProcessAlive()
            DispatchQueue.main.async {
                completion(isAlive)
            }
        }
    }
}
