import ComposableArchitecture
import DarkfiCore
import UserPreferencesStorage

/// Testable wrapper around the in-process Nym proxy (Android `AppNymCoordinator`).
public struct NymBootstrapClient: Sendable {
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

extension NymBootstrapClient: DependencyKey {
    public static let liveValue = Self(
        ensureReady: { await NymBootstrap.ensureReady(socksPort: $0) },
        stop: { NymBootstrap.stop() }
    )

    public static let testValue = Self(
        ensureReady: { _ in true },
        stop: {}
    )
}

extension DependencyValues {
    public var nymBootstrap: NymBootstrapClient {
        get { self[NymBootstrapClient.self] }
        set { self[NymBootstrapClient.self] = newValue }
    }
}

/// Which anonymity network splash should wait on. Tests override this so they
/// do not depend on the simulator's UserDefaults.
public struct PrivacyNetworkClient: Sendable {
    public var current: @Sendable () -> UserPreferencesStorage.PrivacyNetwork
    public var nymSocksPort: @Sendable () -> UInt16
    public var setDirect: @Sendable () -> Void

    public init(
        current: @escaping @Sendable () -> UserPreferencesStorage.PrivacyNetwork,
        nymSocksPort: @escaping @Sendable () -> UInt16,
        setDirect: @escaping @Sendable () -> Void
    ) {
        self.current = current
        self.nymSocksPort = nymSocksPort
        self.setDirect = setDirect
    }
}

extension PrivacyNetworkClient: DependencyKey {
    public static let liveValue = Self(
        current: { UserPreferencesStorage.live.privacyNetwork },
        nymSocksPort: { UInt16(UserPreferencesStorage.live.nymSocksPort) },
        setDirect: { UserPreferencesStorage.live.setPrivacyNetwork(.direct) }
    )

    public static let testValue = Self(
        current: { .nym },
        nymSocksPort: { NymBootstrap.defaultSocksPort },
        setDirect: {}
    )
}

extension DependencyValues {
    public var privacyNetwork: PrivacyNetworkClient {
        get { self[PrivacyNetworkClient.self] }
        set { self[PrivacyNetworkClient.self] = newValue }
    }
}
