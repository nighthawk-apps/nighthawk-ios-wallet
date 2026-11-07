//
//  NighthawkSplitContainer.swift
//
//  Compact width keeps a single column. At [NighthawkLayout.expandedWidth]
//  (Android fold / Duo parity) the list and detail sit side by side.
//  The app target stays iPhone-only.
//

import SwiftUI

private struct NighthawkUsesCompanionPaneKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// True when [NighthawkSplitContainer] is showing the secondary pane.
    public var nighthawkUsesCompanionPane: Bool {
        get { self[NighthawkUsesCompanionPaneKey.self] }
        set { self[NighthawkUsesCompanionPaneKey.self] = newValue }
    }
}

public struct NighthawkSplitContainer<Primary: View, Secondary: View>: View {
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
            // Width-only gate matches Android `NighthawkExpandedWidth` (600.dp).
            let wide = proxy.size.width >= NighthawkLayout.expandedWidth
            Group {
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
            .environment(\.nighthawkUsesCompanionPane, wide)
        }
    }
}
