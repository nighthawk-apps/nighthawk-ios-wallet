//
//  NighthawkTopBar.swift
//
//  Shared top chrome for stacked / sheet screens (Phase 0–2 audit).
//  Replaces ad-hoc safeAreaInset back + magic title paddings.
//

import Generated
import SwiftUI

public struct NighthawkTopBar: View {
    public enum Leading: Equatable {
        case back
        case close
        case none
    }

    let leading: Leading
    let title: String?
    let action: (() -> Void)?

    public init(
        leading: Leading = .back,
        title: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.leading = leading
        self.title = title
        self.action = action
    }

    public var body: some View {
        HStack(spacing: 8) {
            if leading != .none, let action {
                Button(action: action) {
                    leadingImage
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(leading == .close ? "Close" : "Back")
            } else {
                Color.clear.frame(width: 44, height: 44)
            }

            if let title {
                Text(title)
                    .subtitleMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)
                    .lineLimit(1)
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 13)
        .frame(minHeight: 44)
    }

    private var leadingImage: Image {
        switch leading {
        case .back:
            Asset.Assets.Icons.Nighthawk.chevronLeft.image
        case .close:
            // SF Symbol — do not reuse the error `failed` asset for dismiss.
            Image(systemName: "xmark")
        case .none:
            Image(systemName: "xmark")
        }
    }
}

extension View {
    /// Pins a standard Nighthawk top bar into the top safe-area inset.
    public func nighthawkTopBar(
        leading: NighthawkTopBar.Leading = .back,
        title: String? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        safeAreaInset(edge: .top, spacing: 0) {
            if leading != .none || title != nil {
                NighthawkTopBar(leading: leading, title: title, action: action)
            }
        }
    }

    /// Legacy alias — prefer `nighthawkTopBar` with an optional title.
    public func showNighthawkBackButton(
        type: NighthawkBackButtonType = .back,
        title: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        nighthawkTopBar(
            leading: type == .close ? .close : .back,
            title: title,
            action: action
        )
    }
}
