import Foundation
import Combine

public enum DarkfiChatState {
    case stopped
    case startingDaemon
    case daemonRunning
    case connectingIrc
    case connected
    case error(Error)
}

public class DarkfiChatController {
    public static let shared = DarkfiChatController()
    
    @Published public private(set) var state: DarkfiChatState = .stopped
    public let incomingMessages = PassthroughSubject<ChatChannelMessage, Never>()
    
    private var ircClient: DarkircIrcClient?
    private var cancellables = Set<AnyCancellable>()
    private let datastorePath: String
    
    public init() {
        // Use the documents directory for the Darkirc Sled DB datastore
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        self.datastorePath = urls[0].appendingPathComponent("darkirc_db").path
    }
    
    public func startChat(nickname: String, joinChannels: [String] = ["#general"]) {
        guard case .stopped = state else { return }
        
        state = .startingDaemon
        
        // 1. Start the in-process rust daemon via FFI
        // (Assuming uniffi_darkfi_mobile_ffi_func_start_darkirc or similar generated binding)
        do {
            try startDarkirc(datastorePath: self.datastorePath, useTor: false, callback: nil)
            self.state = .daemonRunning
        } catch {
            self.state = .error(error)
            return
        }
        
        // 2. Wait a moment for daemon to bind to port 6667 locally, then connect IRC
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            self.connectIrcClient(nickname: nickname, channels: joinChannels)
        }
    }
    
    private func connectIrcClient(nickname: String, channels: [String]) {
        state = .connectingIrc
        
        let config = DarkircConnectionConfig(
            host: "127.0.0.1",
            port: 6667,
            nickname: nickname,
            username: "nighthawk",
            realname: "Nighthawk iOS User"
        )
        
        let client = DarkircIrcClient(config: config)
        self.ircClient = client
        
        client.messages
            .sink { [weak self] message in
                self?.incomingMessages.send(message)
            }
            .store(in: &cancellables)
        
        Task {
            do {
                _ = try await client.connectAndJoin(joinChannels: channels)
                DispatchQueue.main.async {
                    self.state = .connected
                }
            } catch {
                DispatchQueue.main.async {
                    self.state = .error(error)
                }
            }
        }
    }
    
    public func stopChat() {
        ircClient?.disconnect()
        ircClient = nil
        
        do {
            try stopDarkirc()
        } catch {
            print("Failed to stop darkirc daemon: \(error)")
        }
        
        state = .stopped
    }
    
    public func sendMessage(channel: String, text: String) {
        ircClient?.sendPrivmsg(channelOrNick: channel, text: text)
    }
}
