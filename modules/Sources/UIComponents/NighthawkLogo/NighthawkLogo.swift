//
//  NighthawkLogo.swift
//  stealth
//
//  Created by Matthew Watt on 3/22/23.
//

import Generated
import SwiftUI

public struct NighthawkLogo: View {
    public enum Spacing: CGFloat {
        case normal = 30
        case compact = 22
    }
    
    let spacing: Spacing
    
    public init(spacing: Spacing = .normal) {
        self.spacing = spacing
    }
    
    public var body: some View {
        VStack {
            Asset.Assets.Icons.Nighthawk.nighthawkSymbol
                .image
                .renderingMode(.template)
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.white)
                .padding(.bottom, spacing.rawValue)
            
            Text(L10n.Nighthawk.Splash.title)
                .title()
        }
    }
}
