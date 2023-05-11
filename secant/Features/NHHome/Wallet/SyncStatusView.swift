//
//  SyncStatusView.swift
//  secant
//
//  Created by Matthew Watt on 5/6/23.
//

import SwiftUI

struct SyncStatusView: View {
    let status: SyncStatusSnapshot
    
    var body: some View {
        VStack {
            if let image = syncImage(for: status) {
                image
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .aspectRatio(contentMode: .fit)
                    .padding(.bottom, 20)
            }
            
            Text(status.message)
                .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
                .padding(.horizontal, 25)
        }
        .padding(.top, 96)
    }
}

// MARK: - Subviews
private extension SyncStatusView {
    func syncImage(for status: SyncStatusSnapshot) -> Image? {
        switch status.syncStatus {
        case .unprepared:
            return Asset.Assets.Icons.Nighthawk.connecting.image
        case .disconnected:
            return Asset.Assets.Icons.Nighthawk.reconnecting.image
        case .enhancing:
            return Asset.Assets.Icons.Nighthawk.enhancing.image
        case let .syncing(progress):
            if progress.progress == 0 || progress.progress == 100 {
                return Asset.Assets.Icons.Nighthawk.preparing.image
            } else {
                return Asset.Assets.Icons.Nighthawk.syncing.image
            }
        case .error:
            return Asset.Assets.Icons.Nighthawk.error.image
            
        default:
            return nil
        }
    }
}
