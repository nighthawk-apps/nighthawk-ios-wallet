//
//  ReceiveView.swift
//  stealth
//
//  DarkFi: Single privacy address — show QR code + copy address.
//  No transparent/public section. No legacy address types.
//

import AlertToast
import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

public struct ReceiveView: View {
    @Bindable var store: StoreOf<Receive>

    public init(store: StoreOf<Receive>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            NighthawkLogo(spacing: .compact)
                .padding(.vertical, 32)

            // Subtitle & Header section
            VStack(spacing: 16) {
                Text("Send and receive DRK")
                    .font(.custom(FontFamily.PulpDisplay.bold.name, size: 18))
                    .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)

                Text("Receive money privately")
                    .font(.custom(FontFamily.Rubik.regular.name, size: 14))
                    .foregroundColor(Asset.Colors.Nighthawk.textMuted.color)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.bottom, 24)

            // Options
            VStack(spacing: 10) {
                Button(action: { store.send(.showQrCodeTapped) }) {
                    optionRow(
                        title: "Show QR Code",
                        description: "Let someone scan to send you money.",
                        icon: Asset.Assets.Icons.Nighthawk.nhQrCode.image
                    )
                }
                .buttonStyle(.plain)

                Button(action: { store.send(.copyAddressTapped) }) {
                    optionRow(
                        title: "Copy private address",
                        description: "Your wallet address will be copied to the clipboard.",
                        icon: Asset.Assets.Icons.Nighthawk.copy.image
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 25)

            Spacer()
        }
        .toast(
            unwrapping: $store.toast,
            case: /Receive.State.Toast.copiedToClipboard,
            alert: {
                AlertToast.nighthawkBanner(
                    type: .regular,
                    title: L10n.Nighthawk.WalletTab.Addresses.copiedToClipboard
                )
            }
        )
        .toast(
            unwrapping: $store.toast,
            case: /Receive.State.Toast.newAddressGenerated,
            alert: {
                AlertToast.nighthawkBanner(
                    type: .complete(.green),
                    title: "New address generated"
                )
            }
        )
        .toast(
            unwrapping: $store.toast,
            case: /Receive.State.Toast.generateFailed,
            alert: {
                AlertToast.nighthawkBanner(
                    type: .error(.red),
                    title: "Failed to generate address"
                )
            }
        )
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

// MARK: - Components
private extension ReceiveView {
    func optionRow(
        title: String,
        description: String,
        icon: Image
    ) -> some View {
        VStack {
            HStack(alignment: .center) {
                icon
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
                    .padding(.trailing, 14)

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .foregroundColor(Asset.Colors.Nighthawk.accent.color)
                        .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))

                    Text(description)
                        .caption()
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
            .padding(.vertical, 8)

            Divider()
                .frame(height: 2)
                .overlay(Asset.Colors.Nighthawk.steelBorder.color)
        }
    }
}
