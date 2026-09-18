import ComposableArchitecture
import DarkfiCore
import Foundation

@Reducer
public struct MeshSettings {
    @ObservableState
    public struct State: Equatable {
        public var meshOn: Bool = false
        public var alwaysOn: Bool = true
        public var shareWifi: Bool = false
        public var peerCount: Int = 0
        public var radioBanner: String? = nil
        public var engineUnavailable: Bool = false
        public var cacheFull: Bool = false
        public var idleBecauseChatOff: Bool = false

        public init() {}
    }

    public enum Action: Equatable {
        case onAppear
        case toggleMesh(Bool)
        case toggleAlwaysOn(Bool)
        case toggleShareWifi(Bool)
        case openSettings
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.meshOn = NighthawkMeshController.shared.meshOn
                state.alwaysOn = NighthawkMeshController.shared.alwaysOn
                state.shareWifi = NighthawkMeshController.shared.gatewayOptIn
                state.peerCount = NighthawkMeshController.shared.peerCount
                state.radioBanner = NighthawkMeshController.shared.radioBanner
                refreshBanners(&state)
                return .none
            case let .toggleMesh(enabled):
                state.meshOn = enabled
                NighthawkMeshController.shared.setAlwaysOn(state.alwaysOn)
                NighthawkMeshController.shared.setGatewayOptIn(false)
                NighthawkMeshController.shared.setMeshOn(enabled)
                state.radioBanner = NighthawkMeshController.shared.radioBanner
                refreshBanners(&state)
                return .none
            case let .toggleAlwaysOn(enabled):
                state.alwaysOn = enabled
                NighthawkMeshController.shared.setAlwaysOn(enabled)
                return .none
            case .toggleShareWifi:
                state.shareWifi = false
                NighthawkMeshController.shared.setGatewayOptIn(false)
                return .none
            case .openSettings:
                NighthawkMeshController.shared.openSystemSettings()
                return .none
            }
        }
    }

    public init() {}

    private func refreshBanners(_ state: inout State) {
        state.engineUnavailable = !MeshEngineBridge.neighborsReady
        state.cacheFull = MeshEngineBridge.cacheEvicted
        let ffi = darkircStatus()
        state.idleBecauseChatOff = ffi == "not_running" || ffi == "failed"
    }
}
