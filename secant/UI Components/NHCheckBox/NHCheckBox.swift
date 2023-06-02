//
//  NHCheckBox.swift
//  secant
//
//  Created by Matthew Watt on 4/4/23.
//

import Generated
import SwiftUI

struct NHCheckBox<Label>: View where Label: View {
    let isChecked: Binding<Bool>
    let label: Label?
    
    var body: some View {
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
                
                if let label {
                    label
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Initializers
extension NHCheckBox {
    init(isChecked: Binding<Bool>) {
        self.isChecked = isChecked
        self.label = nil
    }
    
    init(isChecked: Binding<Bool>, @ViewBuilder label: () -> Label) {
        self.isChecked = isChecked
        self.label = label()
    }
}
