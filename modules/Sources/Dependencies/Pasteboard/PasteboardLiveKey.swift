//
//  PasteboardLiveKey.swift
//  stealth
//
//  Created by Lukáš Korba on 13.11.2022.
//

import ComposableArchitecture
import UIKit

extension PasteboardClient: DependencyKey {
    public static let liveValue = Self(
        setString: {
            // Local-only + short TTL — matches chat share path and avoids
            // Universal Clipboard / long-lived clipboard retention of addresses.
            UIPasteboard.general.setItems(
                [[UIPasteboard.typeAutomatic: $0.data]],
                options: [
                    .localOnly: true,
                    .expirationDate: Date().addingTimeInterval(60),
                ]
            )
        },
        getString: { UIPasteboard.general.string?.redacted }
    )
}
