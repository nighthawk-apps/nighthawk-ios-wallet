//
//  SyncStatusView.swift
//  secant
//
//  Created by Matthew Watt on 5/6/23.
//

import Generated
import Models
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
