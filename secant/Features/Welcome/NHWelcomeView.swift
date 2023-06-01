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

struct NHWelcomeView: View {
    var store: WelcomeStore
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack {
                NighthawkLogo()
                    .padding(.bottom, 10)
                
                Text(L10n.Nighthawk.WelcomeScreen.subtitle)
                    .paragraph()
            }

            Spacer()
            
            Asset.Assets.Icons.Nighthawk.poweredByZcash
                .image
                .resizable()
                .frame(width: 131, height: 20)
                .padding(.bottom, 44)
        }
        .applyNighthawkBackground()
    }
}
