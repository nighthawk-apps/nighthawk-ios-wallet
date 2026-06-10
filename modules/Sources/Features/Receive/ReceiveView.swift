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
            
            // Address section
            VStack(spacing: 16) {
                Text("Your DarkFi Address")
                    .font(.custom(FontFamily.PulpDisplay.bold.name, size: 18))
                    .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                
                Text("All transactions on DarkFi are private by default. Share this address to receive DRK.")
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
                        description: "Display QR for in-person payments",
                        icon: Asset.Assets.Icons.Nighthawk.nhQrCode.image
                    )
                }
                
                Button(action: { store.send(.copyAddressTapped) }) {
                    optionRow(
                        title: "Copy Address",
                        description: "Copy your DarkFi privacy address to clipboard",
                        icon: Asset.Assets.Icons.Nighthawk.copy.image
                    )
                }
                
                Button(action: { store.send(.generateNewAddressTapped) }) {
                    HStack(alignment: .center) {
                        if store.isGenerating {
                            ProgressView()
                                .frame(width: 24, height: 24)
                                .tint(.white)
                                .padding(.trailing, 14)
                        } else {
                            Image(systemName: "plus.circle")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                                .padding(.trailing, 14)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Generate New Address")
                                .foregroundColor(Asset.Colors.Nighthawk.accent.color)
                                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
                            
                            Text("Derive a new DarkFi address for privacy")
                                .caption()
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .disabled(store.isGenerating)
            }
            .padding(.horizontal, 25)
            
            Spacer()
            
            // Address preview
            addressPreview
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
    var addressPreview: some View {
        VStack(spacing: 12) {
            if store.privacyAddress != "-" {
                addressCard(label: "PRIMARY ADDRESS", address: store.privacyAddress)
            }
            
            if let generated = store.generatedAddress {
                addressCard(label: "NEW ADDRESS", address: generated)
            }
        }
        .padding(.horizontal, 25)
        .padding(.bottom, 24)
    }
    
    func addressCard(label: String, address: String) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 11))
                .foregroundColor(Asset.Colors.Nighthawk.textMuted.color)
                .tracking(1.5)
            
            Text(address)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Asset.Colors.Nighthawk.textBody.color)
                .lineLimit(2)
                .truncationMode(.middle)
                .padding(.horizontal, 20)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Asset.Colors.Nighthawk.charcoalRaised.color)
        )
    }
    
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
