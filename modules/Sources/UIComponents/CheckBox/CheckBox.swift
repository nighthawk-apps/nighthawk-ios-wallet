//
//  CheckBox.swift
//  stealth
//
//  Created by Matthew Watt on 4/4/23.
//

import Generated
import SwiftUI

public struct CheckBox<Label>: View where Label: View {
    let isChecked: Binding<Bool>
    let label: Label

    public init(
        isChecked: Binding<Bool>,
        @ViewBuilder label: () -> Label = { EmptyView() }
    ) {
        self.isChecked = isChecked
        self.label = label()
    }

    public var body: some View {
        Button {
            isChecked.wrappedValue.toggle()
        } label: {
            HStack(alignment: .center, spacing: 10) {
                Group {
                    if isChecked.wrappedValue {
                        Asset.Assets.Icons.Nighthawk.checked.image
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                    } else {
                        Asset.Assets.Icons.Nighthawk.unchecked.image
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                    }
                }
                .scaledToFit()
                .frame(width: 18, height: 18)
                .padding(3)

                label

                Spacer()
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
