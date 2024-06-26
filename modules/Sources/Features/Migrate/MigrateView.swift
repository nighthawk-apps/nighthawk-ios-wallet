//
//  MigrateView.swift
//  
//
//  Created by Matthew Watt on 8/12/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

public struct MigrateView: View {
    let store: StoreOf<Migrate>
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                NighthawkLogo(spacing: .compact)
                    .padding(.top, 44)
                    .padding(.bottom, 22)
                
                Text(L10n.Nighthawk.MigrateScreen.title)
                    .paragraphMedium()
                    .padding(.bottom, 32)
                    
                
                Text(L10n.Nighthawk.MigrateScreen.explanation)
                    .caption()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 44)

                VStack(spacing: 24) {
                    Button(L10n.Nighthawk.MigrateScreen.continue) {
                        viewStore.send(.continueTapped)
                    }
                    .buttonStyle(.nighthawkPrimary(width: 160))
                    .disabled(viewStore.isLoading)
                    
                    Button(L10n.Nighthawk.MigrateScreen.restoreManually) {
                        viewStore.send(.restoreManuallyTapped)
                    }
                    .buttonStyle(.nighthawkSecondary(width: 160))
                    .disabled(viewStore.isLoading)
                }
                
                Spacer()
            }
            .overlay(alignment: .top) {
                if viewStore.isLoading {
                    IndeterminateProgress()
                }
            }
        }
        .applyNighthawkBackground()
        .alert(
            store: store.scope(
                state: \.$alert,
                action: { .alert($0) }
            )
        )
    }
    
    public init(store: StoreOf<Migrate>) {
        self.store = store
    }
}
