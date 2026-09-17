import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents
import Utils

struct RequestMoneyView: View {
    @Bindable var store: StoreOf<RequestMoney>

    var body: some View {
        VStack(spacing: 16) {
            NighthawkLogo(spacing: .compact)
                .padding(.vertical, 24)

            Text(L10n.Nighthawk.TransferTab.requestMoneyTitle)
                .font(.custom(FontFamily.PulpDisplay.bold.name, size: 18))
                .foregroundColor(.white)

            Text(L10n.Nighthawk.TransferTab.requestMoneySingleAddress)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 14))
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            TextField(L10n.Nighthawk.TransferTab.requestAmountHint, text: $store.amount)
                .keyboardType(.decimalPad)
                .foregroundColor(.white)
                .padding()
                .background(Asset.Colors.Nighthawk.navy.color)
                .cornerRadius(8)
                .padding(.horizontal, 25)

            TextField(L10n.Nighthawk.TransferTab.requestMemoHint, text: $store.memo)
                .foregroundColor(.white)
                .padding()
                .background(Asset.Colors.Nighthawk.navy.color)
                .cornerRadius(8)
                .padding(.horizontal, 25)

            if !store.uri.isEmpty {
                if let img = QRCodeGenerator.generate(from: store.uri) {
                    Image(img, scale: 1, label: Text(L10n.Nighthawk.TransferTab.requestInvoiceQr))
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                }
                Text(store.uri)
                    .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    .textSelection(.enabled)
                    .padding(.horizontal, 25)

                Button(L10n.Nighthawk.TransferTab.requestCopyUri) {
                    store.send(.copyUriTapped)
                }
                .buttonStyle(.nighthawkPrimary())
            }

            Spacer()
        }
        .modify {
            if store.showCloseButton {
                $0.showNighthawkBackButton(type: .close) {
                    store.send(.closeButtonTapped)
                }
            } else {
                $0
            }
        }
        .applyNighthawkBackground()
    }
}
