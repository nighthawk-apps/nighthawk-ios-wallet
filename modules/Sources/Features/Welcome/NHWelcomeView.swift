//
//  NHWelcomeView.swift
//  secant
//
//  Created by Matthew Watt on 3/17/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

public struct NHWelcomeView: View {
    let store: WelcomeStore
    
    public init(store: WelcomeStore) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                Spacer()
                
                VStack {
                    NighthawkLogo()
                        .padding(.bottom, 10)
                    
                    Text(L10n.Nighthawk.WelcomeScreen.subtitle)
                        .paragraph()
                }
                
                if viewStore.authenticationFailed {
                    Button(
                        L10n.Nighthawk.WelcomeScreen.retry,
                        action: { viewStore.send(.retryTapped) }
                    )
                    .buttonStyle(.nighthawkPrimary())
                    .padding(.top, 8)
                }

                Spacer()
                
                Asset.Assets.Icons.Nighthawk.poweredByZcash
                    .image
                    .resizable()
                    .frame(width: 131, height: 20)
                    .padding(.bottom, 44)
            }
        }
        .applyNighthawkBackground()
    }
}
