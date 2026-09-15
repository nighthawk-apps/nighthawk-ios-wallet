import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

public struct MeshSettingsView: View {
    @Bindable var store: StoreOf<MeshSettings>

    public init(store: StoreOf<MeshSettings>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Nearby encrypted DarkIRC DAG over Bluetooth. Radios stay off until you enable Bluetooth mesh.")
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 14))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    .fixedSize(horizontal: false, vertical: true)

                toggleRow(
                    title: "Bluetooth mesh",
                    subtitle: "Nearby Nighthawk chat over Bluetooth. Nighthawk does not use Bluetooth to determine your location.",
                    isOn: Binding(
                        get: { store.meshOn },
                        set: { store.send(.toggleMesh($0)) }
                    )
                )

                if store.meshOn {
                    toggleRow(
                        title: "Always-on power",
                        subtitle: "Keep Bluetooth mesh running in the background. Turn off to stop scanning when you leave the app.",
                        isOn: Binding(
                            get: { store.alwaysOn },
                            set: { store.send(.toggleAlwaysOn($0)) }
                        )
                    )

                    Text("Nearby peers: \(store.peerCount). Mesh works best with Nighthawk open.")
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                }

                Text("If mesh stops after you lock the screen, check Settings → Battery and allow Nighthawk to run in the background. Nearby / local-network access is used only to talk to other Nighthawk wallets, not to determine your location.")
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .onAppear { store.send(.onAppear) }
        .applyNighthawkBackground()
    }

    private func toggleRow(
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: isOn) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.custom(FontFamily.PulpDisplay.medium.name, size: 15))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(Asset.Colors.Nighthawk.peach.color)
        }
    }
}
