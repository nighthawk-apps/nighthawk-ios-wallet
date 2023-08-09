//
//  TransactionStatusView.swift
//  
//
//  Created by Matthew Watt on 7/9/23.
//

import Generated
import Models
import SwiftUI

public struct TransactionStatusView: View {
    let status: TransactionState.Status
    
    public init(status: TransactionState.Status) {
        self.status = status
    }
    
    public var body: some View {
        HStack(alignment: .center) {
            statusImage
                .resizable()
                .foregroundColor(Asset.Colors.Nighthawk.parmaviolet.color)
                .frame(width: 16, height: 16)
            
            Text(statusText)
                .paragraphMedium()
        }
        .padding(.horizontal, 16)
        .frame(height: 26)
        .background(Asset.Colors.Nighthawk.navy.color)
        .cornerRadius(13)
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .strokeBorder(
                    Asset.Colors.Nighthawk.parmaviolet.color,
                    style: StrokeStyle(lineWidth: 1, dash: [4])
                )
        )
    }
}

// MARK: - Subviews
private extension TransactionStatusView {
    var statusText: String {
        switch status {
        case .paid(success: true), .received:
            return L10n.Nighthawk.Transaction.confirmed
        case .receiving:
            return L10n.Nighthawk.Transaction.received
        case .sending:
            return L10n.Nighthawk.Transaction.sent
        case .failed, .paid(success: false):
            return L10n.Nighthawk.Transaction.failed
        }
    }
    
    var statusImage: Image {
        switch status {
        case .paid(success: true), .received:
            return Asset.Assets.Icons.Nighthawk.doubleCheck.image
        case .receiving, .sending:
            return Asset.Assets.Icons.Nighthawk.check.image
        case .failed, .paid(success: false):
            return Asset.Assets.Icons.Nighthawk.error.image
        }
    }
}
