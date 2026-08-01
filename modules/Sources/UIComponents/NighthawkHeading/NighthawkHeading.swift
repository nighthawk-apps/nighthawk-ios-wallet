//
//  NighthawkHeading.swift
//
//  Brand + title block for transfer/detail flows.
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
            Asset.Assets.Icons.Nighthawk.nighthawkSymbol
                .image
                .renderingMode(.template)
                .resizable()
                .frame(width: 35, height: 35)
                .foregroundColor(.white)
                .padding(.bottom, 22)
                .padding(.top, compact ? 8 : 16)

            Text(title)
                .paragraphMedium()

            if let subtitle {
                Text(subtitle)
                    .caption()
                    .frame(width: 246)
            }
        }
    }
}
