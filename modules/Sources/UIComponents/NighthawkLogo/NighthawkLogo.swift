//
//  NighthawkLogo.swift
//  secant
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
            Asset.Assets.Icons.Nighthawk.nighthawkSymbolPeach
                .image
                .resizable()
                .frame(width: 35, height: 35)
                .padding(.bottom, spacing.rawValue)
            
            Text(L10n.Nighthawk.Splash.title)
                .title()
        }
    }
}
