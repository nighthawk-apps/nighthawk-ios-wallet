//
//  TransactionActionableDetailRow.swift
//  
//
//  Created by Matthew Watt on 7/31/23.
//

import Generated
import SwiftUI

public struct TransactionActionableDetailRow: View {
    let name: String
    let value: String
    let actionTitle: String
    let action: () -> Void
    let showBorder: Bool
    
    public init(
        name: String,
        value: String,
        actionTitle: String,
        action: @escaping () -> Void,
        showBorder: Bool
    ) {
        self.name = name
        self.value = value
        self.actionTitle = actionTitle
        self.action = action
        self.showBorder = showBorder
    }
    
    public var body: some View {
        VStack(alignment: .trailing) {
            VStack(alignment: .trailing) {
                HStack(alignment: .top) {
                    Text(name)
                        .details()
                    Spacer()
                    Text(value)
                        .details()
                        .multilineTextAlignment(.trailing)
                }
                .padding(.bottom, 10)

                Button(actionTitle, action: action)
                    .buttonStyle(.txnDetailsLink())
            }
            .padding(.vertical, 12)

            if showBorder {
                Divider()
                    .frame(height: 1)
                    .overlay(Asset.Colors.Nighthawk.parmaviolet.color)
            }
        }
    }
}
