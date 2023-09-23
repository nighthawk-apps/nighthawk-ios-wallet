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

public struct RecipientView: View {
    let store: StoreOf<Recipient>
    
    public init(store: StoreOf<Recipient>) {
        self.store = store
    }
    
    @FocusState private var isRecipientEditorFocused: Bool
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
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
                    text: viewStore.bindingForRedactableRecipient(viewStore.recipient),
                    isValid: viewStore.validateRecipient(),
                    foregroundColor: Asset.Colors.Nighthawk.parmaviolet.color,
                    inputAccessoryView: {
                        addressFieldAccessoryView(with: viewStore)
                    }
                )
                .padding(.horizontal, 24)
                .foregroundColor(.green)
                .focused($isRecipientEditorFocused)
                
                if viewStore.canPasteAddress {
                    Button(
                        L10n.Nighthawk.TransferTab.Recipient.pasteFromClipboard,
                        action: { viewStore.send(.pasteFromClipboardTapped) }
                    )
                    .buttonStyle(.nighthawkDashed())
                }
                
                Spacer()
                
                Button(
                    L10n.Nighthawk.TransferTab.Recipient.continue,
                    action: { viewStore.send(.continueTapped) }
                )
                .buttonStyle(.nighthawkPrimary())
                .disabled(!viewStore.isRecipientValid)
                .padding(.bottom, 28)
            }
            .showNighthawkBackButton(action: { viewStore.send(.backButtonTapped) })
            .onAppear {
                isRecipientEditorFocused = true
                viewStore.send(.onAppear)
            }
        }
        .applyNighthawkBackground()
    }
}

// MARK: - Subviews
private extension RecipientView {
    func addressFieldAccessoryView(with viewStore: ViewStoreOf<Recipient>) -> some View {
        Button(action: { viewStore.send(viewStore.hasEnteredRecipient ? .clearRecipientTapped : .scanQRCodeTapped) }) {
            (
                viewStore.hasEnteredRecipient
                ? Asset.Assets.Icons.Nighthawk.failed.image
                : Asset.Assets.Icons.Nighthawk.boxedQrCode.image
            )
            .resizable()
            .renderingMode(.template)
            .frame(width: 24, height: 24)
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.white)
        }
    }
}
