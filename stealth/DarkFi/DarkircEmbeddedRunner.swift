import Foundation
import os.log

public enum EmbeddedDarkircNodeStatus {
    case notUsed
    case starting
    case running
    case failed
}

public class DarkircEmbeddedRunner {
    static let shared = DarkircEmbeddedRunner()
    private var process: Process?
    private var isDaemonRunning = false
    
    private init() {}
    
    public static func hasBundledBinary() -> Bool {
        return Bundle.main.url(forResource: "darkirc_exec", withExtension: nil) != nil
    }
    
    public static func isDaemonProcessAlive() -> Bool {
        return shared.isDaemonRunning && shared.process?.isRunning == true
    }
    
    public static func startDaemon(configPath: String) -> Bool {
        guard !isDaemonProcessAlive() else { return true }
        
        guard let executableURL = Bundle.main.url(forResource: "darkirc_exec", withExtension: nil) else {
            os_log("Darkirc executable not found in bundle")
            return false
        }
        
        let task = Process()
        task.executableURL = executableURL
        task.arguments = ["--config", configPath]
        
        // Setup pipes for output logging if needed
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            shared.process = task
            shared.isDaemonRunning = true
            
            task.terminationHandler = { _ in
                shared.isDaemonRunning = false
                os_log("Darkirc daemon terminated")
            }
            return true
        } catch {
            os_log("Failed to start Darkirc daemon: %{public}@", error.localizedDescription)
            return false
        }
    }
    
    public static func stopDaemon() {
        if let process = shared.process, process.isRunning {
            process.terminate()
            process.waitUntilExit()
            shared.isDaemonRunning = false
        }
    }
}
