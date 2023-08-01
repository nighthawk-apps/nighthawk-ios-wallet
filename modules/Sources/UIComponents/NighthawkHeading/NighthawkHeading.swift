//
//  NighthawkHeading.swift
//  
//
//  Created by Matthew watt on 7/22/23.
//

import Generated
import SwiftUI

public struct NighthawkHeading: View {
    let title: String
    let subtitle: String?
    
    public init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    public var body: some View {
        VStack(spacing: 10) {
            Asset.Assets.Icons.Nighthawk.nighthawkSymbolPeach
                .image
                .resizable()
                .frame(width: 35, height: 35)
                .padding(.bottom, 22)
                .padding(.top, 44)
            
            Text(title)
                .paragraphMedium()
            
            if let subtitle {
                Text(subtitle)
                    .caption()
                    .frame(width: 246)
            }
        }
    }
}
