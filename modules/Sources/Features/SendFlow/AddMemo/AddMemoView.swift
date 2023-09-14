//
//  AddMemoView.swift
//  
//
//  Created by Matthew Watt on 7/22/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

public struct AddMemoView: View {
    let store: StoreOf<AddMemo>
    
    public init(store: StoreOf<AddMemo>) {
        self.store = store
    }
    
    @FocusState private var isMemoEditorFocused: Bool
    
    public var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                NighthawkHeading(
                    title: L10n.Nighthawk.TransferTab.AddMemo.addMessageToPayment
                )
                .padding(.bottom, 40)
                .onTapGesture {
                    isMemoEditorFocused = false
                }
                
                NighthawkTextEditor(
                    placeholder: L10n.Nighthawk.TransferTab.AddMemo.writeSomething,
                    text: viewStore.bindingForRedactableMemo(viewStore.memo),
                    foregroundColor: Asset.Colors.Nighthawk.parmaviolet.color
                )
                .frame(width: nil, height: 120, alignment: .center)
                .padding(.horizontal, 24)
                .focused($isMemoEditorFocused)
                
                Spacer()
                
                availableActions(with: viewStore)
            }
            .showNighthawkBackButton(action: { viewStore.send(.backButtonTapped) })
            .onAppear {
                isMemoEditorFocused = true
            }
        }
        .applyNighthawkBackground()
    }
}

// MARK: - Subviews
private extension AddMemoView {
    func availableActions(with viewStore: ViewStoreOf<AddMemo>) -> some View {
        Button(
            viewStore.hasEnteredMemo
                ? L10n.Nighthawk.TransferTab.Send.continue
                : L10n.General.skip,
            action: {
                viewStore.send(.continueOrSkipTapped)
            }
        )
        .buttonStyle(.nighthawkPrimary())
        .padding(.bottom, 28)
    }
}
