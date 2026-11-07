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
            // Subtitle & Header section
            VStack(spacing: 16) {
                Text(L10n.Nighthawk.Receive.sendAndReceive)
                    .font(.custom(FontFamily.PulpDisplay.bold.name, size: 18))
                    .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)

                Text(L10n.Nighthawk.Receive.receivePrivately)
                    .font(.custom(FontFamily.DejaVuSansMono.regular.name, size: 14))
                    .foregroundColor(Asset.Colors.Nighthawk.textMuted.color)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.top, 20)
            .padding(.bottom, 24)

            // Options
            VStack(spacing: 0) {
                Divider()
                    .frame(height: 1)
                    .overlay(Asset.Colors.Nighthawk.steelBorder.color)

                Button(action: { store.send(.showQrCodeTapped) }) {
                    optionRow(
                        title: L10n.Nighthawk.Receive.showQr,
                        description: L10n.Nighthawk.Receive.showQrDetail,
                        icon: Asset.Assets.Icons.Nighthawk.nhQrCode.image
                    )
                }
                .buttonStyle(.plain)

                Button(action: { store.send(.copyAddressTapped) }) {
                    optionRow(
                        title: L10n.Nighthawk.Receive.copyAddress,
                        description: L10n.Nighthawk.Receive.copyAddressDetail,
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
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                icon
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 24, height: 24, alignment: .center)
                    .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .foregroundColor(Asset.Colors.Nighthawk.accent.color)
                        .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))

                    Text(description)
                        .caption()
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
            .padding(.vertical, 14)
            .frame(minHeight: 56)
            .contentShape(Rectangle())

            Divider()
                .frame(height: 1)
                .overlay(Asset.Colors.Nighthawk.steelBorder.color)
        }
    }
}
