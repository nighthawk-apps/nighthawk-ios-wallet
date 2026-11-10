//
//  RecipientView.swift
//
//
//  Created by Matthew Watt on 7/23/23.
//

import ComposableArchitecture
import Generated
import Models
import SwiftUI
import UIComponents
import Utils

public struct RecipientView: View {
    @Bindable var store: StoreOf<Recipient>

    public init(store: StoreOf<Recipient>) {
        self.store = store
    }

    @FocusState private var isRecipientEditorFocused: Bool

    public var body: some View {
        VStack {
            NighthawkHeading(
                title: L10n.Nighthawk.TransferTab.Recipient.chooseRecipient,
                compact: true
            )
            .padding(.bottom, 40)
            .onTapGesture {
                isRecipientEditorFocused = false
            }

            NighthawkTextField(
                placeholder: L10n.Nighthawk.TransferTab.Recipient.addAddress,
                text: $store.recipient.sending(\.recipientInputChanged),
                isValid: store.validateRecipient(),
                foregroundColor: Asset.Colors.Nighthawk.parmaviolet.color,
                inputAccessoryView: {
                    addressFieldAccessoryView
                }
            )
            .padding(.horizontal, 24)
            .focused($isRecipientEditorFocused)

            if store.canPasteAddress {
                Button(
                    L10n.Nighthawk.TransferTab.Recipient.pasteFromClipboard,
                    action: { store.send(.pasteFromClipboardTapped) }
                )
                .buttonStyle(.nighthawkDashed())
            }

            if !store.addressBook.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Saved addresses")
                        .font(.custom(FontFamily.PulpDisplay.medium.name, size: 14))
                        .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    ForEach(store.addressBook) { entry in
                        Button {
                            store.send(.addressBookEntryTapped(entry))
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.label)
                                    .font(.custom(FontFamily.PulpDisplay.medium.name, size: 15))
                                    .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
                                Text(entry.address)
                                    .font(.custom(FontFamily.DejaVuSansMono.regular.name, size: 11))
                                    .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }

            if store.isRecipientValid {
                NighthawkTextField(
                    placeholder: "Label to save",
                    text: $store.saveLabel.sending(\.saveLabelChanged)
                )
                .padding(.horizontal, 24)
                .padding(.top, 8)
                Button("Save address") { store.send(.saveAddressTapped) }
                    .buttonStyle(.nighthawkSecondary())
                    .disabled(store.saveLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Spacer()

            Button(
                L10n.Nighthawk.TransferTab.Recipient.continue,
                action: { store.send(.continueTapped) }
            )
            .buttonStyle(.nighthawkPrimary())
            .disabled(!store.isRecipientValid)
            .padding(.bottom, 28)
        }
        .showNighthawkBackButton(
            action: {
                isRecipientEditorFocused = false
                store.send(.backButtonTapped)
            }
        )
        .onAppear {
            isRecipientEditorFocused = true
            store.send(.onAppear)
        }
        .applyNighthawkBackground()
    }
}

// MARK: - Subviews
private extension RecipientView {
    @ViewBuilder var addressFieldAccessoryView: some View {
        if store.showScanButton {
            Button(action: { store.send(store.hasEnteredRecipient ? .clearRecipientTapped : .scanQRCodeTapped) }) {
                (
                    store.hasEnteredRecipient
                        ? Asset.Assets.Icons.Nighthawk.failed.image
                        : Asset.Assets.Icons.Nighthawk.boxedQrCode.image
                )
                .resizable()
                .renderingMode(.template)
                .frame(width: 24, height: 24).scaledToFit()
                .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
            }
        } else if store.hasEnteredRecipient {
            Button(action: { store.send(.clearRecipientTapped) }) {
                Asset.Assets.Icons.Nighthawk.failed.image
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 24, height: 24).scaledToFit()
                    .foregroundColor(Asset.Colors.Nighthawk.textHeader.color)
            }
        }
    }
}

// MARK: - ViewStore
extension StoreOf<Recipient> {
    func validateRecipient() -> NighthawkTextFieldValidationState {
        return if self.isRecipientValid {
            .valid
        } else if let specific = self.specificValidationError {
            specific
        } else {
            .invalid(error: L10n.Nighthawk.TransferTab.Recipient.invalid)
        }
    }
}
