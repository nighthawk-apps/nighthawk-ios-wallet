import ComposableArchitecture
import DarkfiCore

/// Testable wrapper around embedded Arti start/wait/stop (Android `AppTorCoordinator`).
public struct TorBootstrapClient: Sendable {
    public var ensureReady: @Sendable (UInt16) async -> Bool
    public var stop: @Sendable () -> Void

    public init(
        ensureReady: @escaping @Sendable (UInt16) async -> Bool,
        stop: @escaping @Sendable () -> Void
    ) {
        self.ensureReady = ensureReady
        self.stop = stop
    }
}

extension TorBootstrapClient: DependencyKey {
    public static let liveValue = Self(
        ensureReady: { await TorBootstrap.ensureReady(socksPort: $0) },
        stop: { DarkfiFfiSafe.stopArtiProxy() }
    )

    public static let testValue = Self(
        ensureReady: { _ in true },
        stop: {}
    )
}

extension DependencyValues {
    public var torBootstrap: TorBootstrapClient {
        get { self[TorBootstrapClient.self] }
        set { self[TorBootstrapClient.self] = newValue }
    }
}
