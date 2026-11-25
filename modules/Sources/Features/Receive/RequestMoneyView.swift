import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents
import Utils

public struct RequestMoneyView: View {
    @Bindable var store: StoreOf<RequestMoney>

    public init(store: StoreOf<RequestMoney>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(L10n.Nighthawk.RequestMoney.title)
                    .font(.custom(FontFamily.PulpDisplay.bold.name, size: 22))
                    .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)

                Text(L10n.Nighthawk.RequestMoney.subtitle)
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 14))
                    .foregroundColor(Asset.Colors.Nighthawk.textMuted.color)
                    .multilineTextAlignment(.center)

                if let image = QRCodeGenerator.generate(from: store.invoice, scale: 8) {
                    Image(decorative: image, scale: 1)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 220, height: 220)
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                NighthawkTextField(
                    placeholder: L10n.Nighthawk.RequestMoney.amount,
                    text: $store.amount
                )
                NighthawkTextField(
                    placeholder: L10n.Nighthawk.RequestMoney.memo,
                    text: $store.memo
                )

                Text(store.invoice)
                    .font(.custom(FontFamily.DejaVuSansMono.regular.name, size: 12))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    .multilineTextAlignment(.center)
                    .textSelection(.enabled)

                Button(store.copied ? L10n.Nighthawk.RequestMoney.copied : L10n.Nighthawk.RequestMoney.copyInvoice) {
                    store.send(.copyTapped)
                }
                .buttonStyle(.nighthawkPrimary())
            }
            .padding(24)
        }
        .showNighthawkBackButton(action: { store.send(.closeButtonTapped) })
        .applyNighthawkBackground()
    }
}
