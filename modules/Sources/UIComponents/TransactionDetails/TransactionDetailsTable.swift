//
//  TransactionDetailsTable.swift
//  
//
//  Created by Matthew Watt on 7/31/23.
//

import Generated
import SwiftUI
import ZcashLightClientKit

public struct TransactionLineItem: Identifiable {
    public struct Action {
        let title: String
        let action: () -> Void
        
        public init(title: String, action: @escaping () -> Void) {
            self.title = title
            self.action = action
        }
    }
    
    let name: String
    let value: String
    let isMemo: Bool
    let action: Action?
    let showBorder: Bool
    public var id: String { name }
    
    public init(
        name: String,
        value: String,
        isMemo: Bool = false,
        action: Action? = nil,
        showBorder: Bool = true
    ) {
        self.name = name
        self.value = value
        self.isMemo = isMemo
        self.action = action
        self.showBorder = showBorder
    }
}

public struct TransactionDetailsTable: View {
    let lineItems: [TransactionLineItem]
    
    public init(lineItems: [TransactionLineItem]) {
        self.lineItems = lineItems
    }
    
    public var body: some View {
        VStack {
            ForEach(lineItems) { lineItem in
                if let action = lineItem.action {
                    TransactionActionableDetailRow(
                        name: lineItem.name,
                        value: lineItem.value,
                        actionTitle: action.title,
                        action: action.action,
                        showBorder: lineItem.showBorder
                    )
                } else {
                    TransactionBasicDetailRow(
                        name: lineItem.name,
                        value: lineItem.value,
                        isMemo: lineItem.isMemo,
                        showBorder: lineItem.showBorder
                    )
                }
            }
        }
        .padding(.horizontal, 25)
        .padding(.top, 55)
        .padding(.bottom, 40)
    }
}

// MARK: - Internal
struct TransactionDetailsTextStyle: ViewModifier {
    var color: Color
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(color)
            .font(.custom(FontFamily.PulpDisplay.regular.name, size: 14))
    }
}

extension Text {
    func details(color: Color = Asset.Colors.Nighthawk.parmaviolet.color) -> some View {
        self.modifier(TransactionDetailsTextStyle(color: color))
    }
}

struct TxnDetailsButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        TxnDetailsLinkButton(configuration: configuration)
    }
    
    struct TxnDetailsLinkButton: View {
        let configuration: ButtonStyle.Configuration
        var body: some View {
            configuration.label
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 12))
                .foregroundColor(Asset.Colors.Nighthawk.peach.color.opacity(configuration.isPressed ? 0.5 : 1.0))
        }
    }
}

extension ButtonStyle where Self == TxnDetailsButtonStyle {
    static func txnDetailsLink() -> TxnDetailsButtonStyle { TxnDetailsButtonStyle() }
}
