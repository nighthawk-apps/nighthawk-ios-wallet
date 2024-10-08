//
//  ImportWarningView.swift
//
//
//  Created by Matthew Watt on 9/24/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

public struct ImportWarningView: View {
    @Bindable var store: StoreOf<ImportWarning>
    
    public var body: some View {
        VStack(spacing: 16) {
            Text(L10n.Nighthawk.ImportWarning.title)
                .title(color: Asset.Colors.Nighthawk.peach.color)
            
            Text(L10n.Nighthawk.ImportWarning.description)
                .subtitle(color: .white)
                .lineSpacing(6)
            
            Button(L10n.Nighthawk.ImportWarning.proceed) {
                store.send(.proceedTapped)
            }
            .buttonStyle(.nighthawkPrimary(width: 150))
            
            Button(L10n.General.cancel) {
                store.send(.cancelTapped)
            }
            .buttonStyle(.nighthawkSecondary(width: 150))
        }
        .padding(8)
    }
    
    public init(store: StoreOf<ImportWarning>) {
        self.store = store
    }
}
