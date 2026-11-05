//
//  NighthawkHeading.swift
//
//  Title block for transfer/detail flows (no logo mark).
//  When a TopBar is present, use `compact: true` so top padding is not doubled.
//

import Generated
import SwiftUI

public struct NighthawkHeading: View {
    let title: String
    let subtitle: String?
    /// When true, omit the status-bar-sized top pad (TopBar already owns that space).
    let compact: Bool

    public init(title: String, subtitle: String? = nil, compact: Bool = false) {
        self.title = title
        self.subtitle = subtitle
        self.compact = compact
    }

    public var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .paragraphMedium()
                .padding(.top, compact ? 8 : 16)

            if let subtitle {
                Text(subtitle)
                    .caption()
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
