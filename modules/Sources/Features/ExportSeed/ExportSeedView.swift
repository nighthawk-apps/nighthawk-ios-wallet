//
//  ExportSeedView.swift
//  
//
//  Created by Matthew Wat on 9/10/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

public struct ExportSeedView: View {
    let store: StoreOf<ExportSeed>
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: 16) {
                HStack {
                    Text(L10n.Nighthawk.ExportSeed.title)
                        .title(color: .white)
                    
                    Spacer()
                }
                
                HStack {
                    Text(L10n.Nighthawk.ExportSeed.description)
                        .subtitle(color: .white)
                        .lineSpacing(4)
                    
                    Spacer()
                }
                
                NighthawkTextField(
                    placeholder: L10n.Nighthawk.ExportSeed.passwordPlaceholder,
                    text: .constant(""),
                    isSecure: true
                )
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    public init(store: StoreOf<ExportSeed>) {
        self.store = store
    }
}
