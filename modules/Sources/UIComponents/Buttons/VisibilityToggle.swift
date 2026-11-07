//
//  VisibilityToggle.swift
//
//
//  Created by Matthew Watt on 9/15/23.
//

import Generated
import SwiftUI

public struct VisibilityToggle: View {
    let isVisible: Binding<Bool>

    public var body: some View {
        Button {
            isVisible.wrappedValue.toggle()
        } label: {
            (
                isVisible.wrappedValue
                    ? Asset.Assets.Icons.Nighthawk.visible.image
                    : Asset.Assets.Icons.Nighthawk.hidden.image
            )
            .resizable()
            .renderingMode(.template)
            .scaledToFit()
            .frame(width: 24, height: 24)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
    }

    public init(isVisible: Binding<Bool>) {
        self.isVisible = isVisible
    }
}
