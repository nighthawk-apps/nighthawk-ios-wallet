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
    @Bindable var store: StoreOf<Migrate>
    
    public var body: some View {
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
                    store.send(.continueTapped)
                }
                .buttonStyle(.nighthawkPrimary(width: 160))
                .disabled(store.isLoading)
                
                Button(L10n.Nighthawk.MigrateScreen.restoreManually) {
                    store.send(.restoreManuallyTapped)
                }
                .buttonStyle(.nighthawkSecondary(width: 160))
                .disabled(store.isLoading)
            }
            
            Spacer()
        }
        .overlay(alignment: .top) {
            if store.isLoading {
                IndeterminateProgress()
            }
        }
        .applyNighthawkBackground()
        .alert(
            $store.scope(
                state: \.alert,
                action: \.alert
            )
        )
    }
    
    public init(store: StoreOf<Migrate>) {
        self.store = store
    }
}
