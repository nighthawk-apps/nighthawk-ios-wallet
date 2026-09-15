import ComposableArchitecture
import Foundation

@Reducer
public struct MeshSettings {
    @ObservableState
    public struct State: Equatable {
        public var meshOn: Bool = false
        public var alwaysOn: Bool = true
        public var shareWifi: Bool = false
        public var peerCount: Int = 0

        public init() {}
    }

    public enum Action: Equatable {
        case onAppear
        case toggleMesh(Bool)
        case toggleAlwaysOn(Bool)
        case toggleShareWifi(Bool)
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.meshOn = NighthawkMeshController.shared.meshOn
                state.alwaysOn = NighthawkMeshController.shared.alwaysOn
                state.shareWifi = NighthawkMeshController.shared.gatewayOptIn
                state.peerCount = NighthawkMeshController.shared.peerCount
                return .none
            case let .toggleMesh(enabled):
                state.meshOn = enabled
                NighthawkMeshController.shared.setAlwaysOn(state.alwaysOn)
                NighthawkMeshController.shared.setGatewayOptIn(false)
                NighthawkMeshController.shared.setMeshOn(enabled)
                return .none
            case let .toggleAlwaysOn(enabled):
                state.alwaysOn = enabled
                NighthawkMeshController.shared.setAlwaysOn(enabled)
                return .none
            case .toggleShareWifi:
                state.shareWifi = false
                NighthawkMeshController.shared.setGatewayOptIn(false)
                return .none
            }
        }
    }

    public init() {}
}
