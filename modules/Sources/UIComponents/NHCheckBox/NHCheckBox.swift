//
//  NHCheckBox.swift
//  secant
//
//  Created by Matthew Watt on 4/4/23.
//

import Generated
import SwiftUI

public struct NHCheckBox<Label>: View where Label: View {
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
            HStack(alignment: .center) {
                Group {
                    if isChecked.wrappedValue {
                        Asset.Assets.Icons.Nighthawk.checked.image
                            .resizable()
                    } else {
                        Asset.Assets.Icons.Nighthawk.unchecked.image
                            .resizable()
                    }
                }
                .frame(width: 18, height: 18)
                .padding(3)
                
                label
                
                Spacer()
            }
        }
    }
}
