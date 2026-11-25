//
//  DarkFiSymbol.swift
//  wallet
//
//  Created by Francisco Gindre on 12/30/19.
//  Copyright © 2019 Francisco Gindre. All rights reserved.
//

import SwiftUI

/// Vector shape drawing the stylized currency symbol path.
public struct DarkFiSymbol: Shape {
    public static let ratio: CGFloat = 0.56

    public func path(in rect: CGRect) -> Path {
        Path { path in
            let width = rect.height * Self.ratio
            let origin = CGPoint(x: rect.midX - width / 2, y: rect.origin.y)
            let height = rect.height
            let middle = origin.x + width / 2
            let endX = origin.x + width
            let yOffset = height / 8
            let caretWidth = yOffset
            let caretheight = yOffset
            let caretStartX = middle - caretWidth / 2
            let caretEndX = caretStartX + caretWidth
            let strokeHeight = caretheight * 1.25

            path.move(to: CGPoint(x: origin.x, y: caretheight))
            path.addLine(to: CGPoint(x: caretStartX, y: yOffset))
            path.addLine(to: CGPoint(x: caretStartX, y: origin.y))
            path.addLine(to: CGPoint(x: caretEndX, y: origin.y))
            path.addLine(to: CGPoint(x: caretEndX, y: caretheight))
            path.addLine(to: CGPoint(x: endX, y: caretheight))
            path.addLine(to: CGPoint(x: endX, y: caretheight + strokeHeight * 0.75))
            path.addLine(to: CGPoint(x: caretStartX, y: caretheight + strokeHeight + strokeHeight * 3))
            path.addLine(to: CGPoint(x: endX, y: caretheight + strokeHeight + strokeHeight * 3))
            path.addLine(to: CGPoint(x: endX, y: caretheight + strokeHeight + strokeHeight * 3 + strokeHeight))
            path.addLine(to: CGPoint(x: caretEndX, y: caretheight + strokeHeight + strokeHeight * 3 + strokeHeight))
            path.addLine(
                to: CGPoint(
                    x: caretEndX,
                    y: caretheight + strokeHeight + strokeHeight * 3 + strokeHeight + caretheight
                )
            )
            path.addLine(
                to: CGPoint(
                    x: caretStartX,
                    y: caretheight + strokeHeight + strokeHeight * 3 + strokeHeight + caretheight
                )
            )
            path.addLine(to: CGPoint(x: caretStartX, y: caretheight + strokeHeight + strokeHeight * 3 + strokeHeight))
            path.addLine(to: CGPoint(x: origin.x, y: caretheight + strokeHeight + strokeHeight * 3 + strokeHeight))
            path.addLine(to: CGPoint(x: origin.x, y: caretheight + strokeHeight + strokeHeight * 3 + strokeHeight * 0.25))
            path.addLine(to: CGPoint(x: caretEndX, y: caretheight + strokeHeight))
            path.addLine(to: CGPoint(x: origin.x, y: caretheight + strokeHeight))
            path.closeSubpath()
        }
    }
}
