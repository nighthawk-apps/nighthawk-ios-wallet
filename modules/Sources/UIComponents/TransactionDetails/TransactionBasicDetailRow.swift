//
//  TransactionBasicDetailRow.swift
//  
//
//  Created by Matthew Watt on 7/31/23.
//

import Generated
import SwiftUI

public struct TransactionBasicDetailRow: View {
    let name: String
    let value: String
    let isMemo: Bool
    let showBorder: Bool
    
    public init(name: String, value: String, isMemo: Bool, showBorder: Bool) {
        self.name = name
        self.value = value
        self.isMemo = isMemo
        self.showBorder = showBorder
    }
    
    public var body: some View {
        Group {
            if isMemo {
                HStack {
                    VStack(alignment: .leading) {
                        Text(name)
                            .details()
                            .padding(.bottom, 4)
                        
                        Text(value)
                            .foregroundColor(.white)
                            .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
                            .multilineTextAlignment(.leading)
                            .lineSpacing(6)
                            .padding(.bottom, 22)
                    }
                    
                    Spacer()
                }
            } else {
                VStack {
                    HStack(alignment: .center) {
                        Text(name)
                            .details()
                        Spacer()
                        Text(value)
                            .details()
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
    }
}
