//
//  NighthawkLogo.swift
//  secant
//
//  Created by Matthew Watt on 3/22/23.
//

import Generated
import SwiftUI
import UIComponents

struct NighthawkLogo: View {
    var body: some View {
        VStack {
            Asset.Assets.Icons.Nighthawk.nighthawkSymbolPeach
                .image
                .resizable()
                .frame(width: 35, height: 35)
                .padding(.bottom, 30)
            
            Text(L10n.Nighthawk.WelcomeScreen.title)
                .title
        }
    }
}
