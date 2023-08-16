//
//  IndeterminateProgress.swift
//  secant
//
//  Created by Matthew Watt on 5/6/23.
//

import Generated
import SwiftUI

public struct IndeterminateProgress: View {
    private enum Constants {
        static let height: CGFloat = 4
        static let coverPercentage: CGFloat = 0.8
        static let minOffset: CGFloat = -2
        static let maxOffset = 1 / coverPercentage * abs(minOffset)
    }
    
    @State private var offset = Constants.minOffset
    @State private var scaleX = 1.0
    
    public init() {}
    
    public var body: some View {
        Rectangle()
            .foregroundColor(Asset.Colors.Nighthawk.peach.color.opacity(0.2))
            .frame(height: Constants.height)
            .overlay(
                GeometryReader { geometry in
                    rect(in: geometry.frame(in: .local))
                }
            )
    }
}

// MARK: - Implementation
private extension IndeterminateProgress {
    func rect(in rect: CGRect) -> some View {
        let width = rect.width * Constants.coverPercentage
        return Rectangle()
            .foregroundColor(Asset.Colors.Nighthawk.peach.color)
            .frame(width: width)
            .scaleEffect(x: scaleX)
            .offset(x: width * offset)
            .onAppear {
                // Offset animation
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    self.offset = Constants.maxOffset
                }
                
                // Scale animation
                withAnimation(Animation.linear(duration: 1).delay(0.5).repeatForever(autoreverses: true)) {
                    self.scaleX = 0.5
                }
            }
    }
}
