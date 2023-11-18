//
//  NHPageIndicator.swift
//  
//
//  Created by Matthew Watt on 8/9/23.
//

import Generated
import SwiftUI

public protocol NHPage: Hashable, CaseIterable where AllCases == Array<Self> {}

public struct NHPageIndicator<Page: NHPage>: View where Page.AllCases == Array<Page> {
    let selection: Binding<Page>
    
    public init(selection: Binding<Page>) {
        self.selection = selection
    }
    
    public var body: some View {
        HStack {
            ForEach(Page.allCases, id: \.self) { page in
                Circle()
                    .strokeBorder(
                        strokeColor(isSelected: page == selection.wrappedValue),
                        lineWidth: 3
                    )
                    .background(
                        Circle()
                            .fill(fillColor(isSelected: page == selection.wrappedValue))
                            .frame(width: 10, height: 10)
                    )
                    .frame(width: 16, height: 16)
            }
        }
        .environment(\.locale, Locale(identifier: "en_US"))
    }
}

// MARK: - Implementation
private extension NHPageIndicator {
    func fillColor(isSelected: Bool) -> Color {
        isSelected ? .white : Asset.Colors.Nighthawk.peach.color.opacity(0.6)
    }
    
    func strokeColor(isSelected: Bool) -> Color {
        isSelected ? Asset.Colors.Nighthawk.parmaviolet.color : .clear
    }
}
