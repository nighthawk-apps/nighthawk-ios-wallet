//
//  NighthawkBackButton.swift
//
//
//  Created by Matthew Watt on 7/23/23.
//

import Generated
import SwiftUI

public enum NighthawkBackButtonType: Equatable {
    case back
    case close
}

extension View {
    public func showNighthawkBackButton(type: NighthawkBackButtonType = .back, action: @escaping () -> Void) -> some View {
        safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                Button(action: action) {
                    image(for: type)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .aspectRatio(contentMode: .fit)
                        .padding(12)
                        .contentShape(Rectangle())
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 13)
        }
    }
    
    func image(for type: NighthawkBackButtonType) -> Image {
        switch type {
        case .back:
            Asset.Assets.Icons.Nighthawk.chevronLeft.image
        case .close:
            Asset.Assets.Icons.Nighthawk.failed.image
        }
    }
}
