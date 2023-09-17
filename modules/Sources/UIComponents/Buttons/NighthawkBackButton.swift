//
//  NighthawkBackButton.swift
//  
//
//  Created by Matthew Watt on 7/23/23.
//

import Generated
import SwiftUI

extension View {
    public func showNighthawkBackButton(action: @escaping () -> Void) -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .topLeading) {
                Button(action: action) {
                    Asset.Assets.Icons.Nighthawk.chevronLeft.image
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .aspectRatio(contentMode: .fit)
                }
                .padding([.top, .leading], 25)
            }
            .toolbar(.hidden, for: .navigationBar)
    }
}
