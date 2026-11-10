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

private struct NighthawkWindowWidthKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    /// True when [NighthawkSplitContainer] is showing the secondary pane.
    public var nighthawkUsesCompanionPane: Bool {
        get { self[NighthawkUsesCompanionPaneKey.self] }
        set { self[NighthawkUsesCompanionPaneKey.self] = newValue }
    }

    /// Full window width, including a leading nav rail. `0` means unknown.
    public var nighthawkWindowWidth: CGFloat {
        get { self[NighthawkWindowWidthKey.self] }
        set { self[NighthawkWindowWidthKey.self] = newValue }
    }
}

public struct NighthawkSplitContainer<Primary: View, Secondary: View>: View {
    private let primary: Primary
    private let secondary: Secondary
    @Environment(\.nighthawkWindowWidth) private var windowWidth

    public init(
        @ViewBuilder primary: () -> Primary,
        @ViewBuilder secondary: () -> Secondary
    ) {
        self.primary = primary()
        self.secondary = secondary()
    }

    public var body: some View {
        GeometryReader { proxy in
            // Prefer the full window (rail included) so a Duo / landscape
            // width at the 600pt gate opens the companion, not only the rail.
            let available = windowWidth > 0 ? windowWidth : proxy.size.width
            let wide = available >= NighthawkLayout.expandedWidth
            Group {
                if wide {
                    HStack(spacing: 0) {
                        primary
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        Rectangle()
                            .fill(Color(red: 0x3D / 255, green: 0x4C / 255, blue: 0x5C / 255))
                            .frame(width: 1)
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
