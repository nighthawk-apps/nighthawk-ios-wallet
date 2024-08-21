//
//  RecipientView.swift
//
//
//  Created by Matthew Watt on 7/23/23.
//

import ComposableArchitecture
import Generated
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
                title: L10n.Nighthawk.TransferTab.Recipient.chooseRecipient
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
            .foregroundColor(.green)
            .focused($isRecipientEditorFocused)
            
            if store.canPasteAddress {
                Button(
                    L10n.Nighthawk.TransferTab.Recipient.pasteFromClipboard,
                    action: { store.send(.pasteFromClipboardTapped) }
                )
                .buttonStyle(.nighthawkDashed())
            }
            
            Spacer()
            
            Button(
                L10n.Nighthawk.TransferTab.Recipient.continue,
                action: { store.send(.continueTapped) }
            )
            .buttonStyle(.nighthawkPrimary())
            .disabled(!store.isRecipientValid || store.isResolvingUNS)
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
                .frame(width: 24, height: 24)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.white)
            }
        } else if store.hasEnteredRecipient {
            Button(action: { store.send(.clearRecipientTapped) }) {
                Asset.Assets.Icons.Nighthawk.failed.image
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 24, height: 24)
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - ViewStore
extension StoreOf<Recipient> {    
    func validateRecipient() -> NighthawkTextFieldValidationState {
        return if self.isRecipientValid {
            .valid
        } else if let specific = self.specificValidationError  {
            specific
        } else {
            .invalid(error: L10n.Nighthawk.TransferTab.Recipient.invalid)
        }
    }
}
