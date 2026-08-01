//
//  SyncStatusView.swift
//  stealth
//
//  Created by Matthew Watt on 5/6/23.
//

import Generated
import Models
import SwiftUI
import Utils

struct SyncStatusView: View {
    let status: SyncStatusSnapshot

    var body: some View {
        VStack(spacing: 4) {
            if let image = syncImage(for: status) {
                image
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .aspectRatio(contentMode: .fit)
                    .padding(.bottom, 8)
            }

            // Sync status message — from lightwallet sync engine
            if let lightSyncMessage = status.lightSyncStatusMessage, !lightSyncMessage.isEmpty {
                Text(lightSyncMessage)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                    .padding(.horizontal, 25)
                    .accessibilityIdentifier("SYNC_STATUS_TEXT")
            } else {
                Text(status.message)
                    .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                    .padding(.horizontal, 25)
            }

            // Live retrieval-method label from the shared Rust `SyncMethod`.
            // Private OMR-family paths get a lock + green; the trial-decryption
            // fallback gets an amber warning.
            if status.syncMethod != .unknown {
                syncMethodLabel(for: status.syncMethod)
            }
        }
    }

    @ViewBuilder
    func syncMethodLabel(for method: DarkfiSyncMethod) -> some View {
        // Surface UnifOMR phase text from the Rust sync engine when present.
        let phaseHint: String = {
            guard let msg = status.lightSyncStatusMessage else { return "" }
            if msg.contains("1/2") { return " · scanning" }
            if msg.contains("2/2") { return " · fetching" }
            return ""
        }()
        let displayText: String = {
            if method.isPrivateRetrieval { return "🔒 \(method.displayName)\(phaseHint)" }
            if method == .trialDecrypt { return "⚠️ \(method.displayName)" }
            return method.displayName
        }()
        let displayColor: Color = {
            if method.isPrivateRetrieval { return Color.green.opacity(0.8) }
            if method == .trialDecrypt { return Color.orange.opacity(0.8) }
            return Asset.Colors.Nighthawk.peach.color.opacity(0.7)
        }()

        Text(displayText)
            .font(.caption2)
            .foregroundColor(displayColor)
            .accessibilityIdentifier("SYNC_TYPE_TEXT")
    }
}

// MARK: - Subviews
private extension SyncStatusView {
    func syncImage(for status: SyncStatusSnapshot) -> Image? {
        switch status.syncStatus {
        case .unprepared:
            return Asset.Assets.Icons.Nighthawk.connecting.image
        case let .syncing(progress):
            let percentage = progress * 100
            if percentage == 0 || percentage == 100 {
                return Asset.Assets.Icons.Nighthawk.preparing.image
            } else {
                return Asset.Assets.Icons.Nighthawk.syncing.image
            }
        case .error:
            return Asset.Assets.Icons.Nighthawk.error.image
        case .stopped:
            return Asset.Assets.Icons.Nighthawk.failed.image
        case .upToDate:
            return nil
        }
    }
}
