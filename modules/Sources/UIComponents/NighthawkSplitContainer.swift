//
//  NighthawkSplitContainer.swift
//
//  Compact width keeps a single column. Large iPhones in landscape show
//  the list and the detail side by side. The app target stays iPhone-only.
//

import SwiftUI

public struct NighthawkSplitContainer<Primary: View, Secondary: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private let primary: Primary
    private let secondary: Secondary

    public init(
        @ViewBuilder primary: () -> Primary,
        @ViewBuilder secondary: () -> Secondary
    ) {
        self.primary = primary()
        self.secondary = secondary()
    }

    public var body: some View {
        GeometryReader { proxy in
            let wide = horizontalSizeClass == .regular || proxy.size.width >= 700
            if wide {
                HStack(spacing: 0) {
                    primary
                        .frame(maxWidth: proxy.size.width * 0.42, maxHeight: .infinity)
                    secondary
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                primary
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
    }
}
