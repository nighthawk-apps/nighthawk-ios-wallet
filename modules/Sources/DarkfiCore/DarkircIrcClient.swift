import Combine
import Foundation
import Network

public struct ChatChannelMessage {
    public let channel: String
    public let senderNick: String
    public let body: String
    public let isNotice: Bool
}

public struct DarkircConnectionConfig {
    public let host: String
    public let port: UInt16
    public let nickname: String
    public let username: String
    public let realname: String
    public let ircPassword: String?
    
    public init(host: String = "127.0.0.1", port: UInt16 = 6667, nickname: String, username: String, realname: String, ircPassword: String? = nil) {
        self.host = host
        self.port = port
        self.nickname = nickname
        self.username = username
        self.realname = realname
        self.ircPassword = ircPassword
    }
}

public enum DarkircIrcClientState {
    case disconnected
    case connecting
    case connected
    case registered
}

public class DarkircIrcClient {
    private let config: DarkircConnectionConfig
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "co.nighthawk.darkirc.client")
    
    @Published public private(set) var state: DarkircIrcClientState = .disconnected
    public let messages = PassthroughSubject<ChatChannelMessage, Never>()
    
    public init(config: DarkircConnectionConfig) {
        self.config = config
    }
    
    public func connectAndJoin(joinChannels: [String]) async throws -> [ChatChannelMessage] {
        return try await withCheckedThrowingContinuation { continuation in
            state = .connecting
            let host = NWEndpoint.Host(config.host)
            let port = NWEndpoint.Port(rawValue: config.port)!
            
            // Assuming local darkirc daemon over TCP without TLS for now.
            let parameters = NWParameters.tcp
            connection = NWConnection(host: host, port: port, using: parameters)
            
            connection?.stateUpdateHandler = { [weak self] newState in
                guard let self = self else { return }
                switch newState {
                case .ready:
                    self.state = .connected
                    self.performHandshake(joinChannels: joinChannels) { result in
                        continuation.resume(with: result)
                    }
                    self.receiveLoop()
                case .failed(let error):
                    self.state = .disconnected
                    continuation.resume(throwing: error)
                case .cancelled:
                    self.state = .disconnected
                default:
                    break
                }
            }
            connection?.start(queue: queue)
        }
    }
    
    public func disconnect() {
        connection?.cancel()
        connection = nil
        state = .disconnected
    }
    
    public func sendPrivmsg(channelOrNick: String, text: String) {
        let sanitized = text.replacingOccurrences(of: "\r", with: "").replacingOccurrences(of: "\n", with: " ")
        sendRaw("PRIVMSG \(channelOrNick) :\(sanitized)")
    }
    
    private func sendRaw(_ line: String) {
        guard let data = "\(line)\r\n".data(using: .utf8) else { return }
        connection?.send(content: data, completion: .contentProcessed({ error in
            if let error = error {
                #if DEBUG
                print("DarkircIrcClient send error: \(error)")
                #endif
            }
        }))
    }
    
    private func performHandshake(joinChannels: [String], completion: @escaping (Result<[ChatChannelMessage], Error>) -> Void) {
        if let pass = config.ircPassword, !pass.isEmpty {
            sendRaw("PASS :\(pass)")
        }
        sendRaw("NICK \(config.nickname)")
        sendRaw("USER \(config.username) 0 * :\(config.realname)")
        
        // TODO: Full handshake validation with CAP LS and waiting for welcome numeric (001)
        // For now, immediately returning empty bootstrap messages and transitioning state.
        self.state = .registered
        
        let chanArg = joinChannels.map { $0.hasPrefix("#") ? $0 : "#\($0)" }.joined(separator: ",")
        if !chanArg.isEmpty {
            sendRaw("JOIN \(chanArg)")
        }
        
        completion(.success([]))
    }
    
    private func receiveLoop() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            guard let self = self else { return }
            
            if let data = content, let string = String(data: data, encoding: .utf8) {
                let lines = string.components(separatedBy: .newlines)
                for line in lines where !line.isEmpty {
                    self.handleServerLine(line)
                }
            }
            
            if isComplete || error != nil {
                self.disconnect()
            } else {
                self.receiveLoop()
            }
        }
    }
    
    private func handleServerLine(_ rawLine: String) {
        let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty else { return }
        
        if line.uppercased().hasPrefix("PING ") {
            let payload = line.dropFirst(5)
            sendRaw("PONG \(payload)")
            return
        }
        
        // Proper IRC line parser
        var remaining = line
        var prefix: String?
        
        if remaining.hasPrefix(":") {
            if let spaceIdx = remaining.firstIndex(of: " ") {
                prefix = String(remaining[remaining.index(after: remaining.startIndex)..<spaceIdx])
                remaining = String(remaining[remaining.index(after: spaceIdx)...])
            }
        }
        
        var trailing: String?
        var paramsStr = remaining
        if let trailingRange = remaining.range(of: " :") {
            trailing = String(remaining[trailingRange.upperBound...])
            paramsStr = String(remaining[..<trailingRange.lowerBound])
        }
        
        let params = paramsStr.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard !params.isEmpty else { return }
        let command = params[0].uppercased()
        
        if command == "PRIVMSG", params.count >= 2 {
            let body = trailing ?? (params.count > 2 ? params[2...].joined(separator: " ") : "")
            let senderNick = prefix?.split(separator: "!").first.map(String.init) ?? "unknown"
            let channel = params[1]
            
            let message = ChatChannelMessage(channel: channel, senderNick: senderNick, body: body, isNotice: false)
            DispatchQueue.main.async {
                self.messages.send(message)
            }
        }
    }
}
