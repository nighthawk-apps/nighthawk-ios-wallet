//
//  ScanView.swift
//  
//
//  Created by Matthew Watt on 7/22/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents
import Utils

public struct ScanView: View {
    @Bindable var store: StoreOf<Scan>
    
    let normalizedRectOfInterest: CGRect = CGRect(
        x: 0.25,
        y: 0.25,
        width: 1.0,
        height: 1.0
    )
    
    public var body: some View {
        GeometryReader { geometry in
            VStack {
                NighthawkHeading(
                    title: L10n.Nighthawk.TransferTab.Scan.scanPaymentRequest,
                    subtitle: L10n.Nighthawk.TransferTab.Scan.scanPaymentRequestDetails
                )
                .padding(.bottom, 40)
                
                QRCodeScanView(
                    rectOfInterest: normalizedRectOfInterest,
                    onQRScanningDidFail: { store.send(.scanFailed) },
                    onQRScanningSucceededWithCode: { store.send(.scan($0.redacted)) }
                )
                .frame(
                    width: geometry.size.width * 0.7,
                    height: geometry.size.width * 0.7
                )
                .cornerRadius(8)
                .overlay(
                    CornerStrokeSquare()
                        .stroke(Asset.Colors.Nighthawk.peach.color, lineWidth: 5)
                        .cornerRadius(2)
                        .padding(18)
                )
                
                Spacer()
            }
            .showNighthawkBackButton(
                type: store.backButtonType,
                action: { store.send(.backButtonTapped) }
            )
        }
        .onAppear { store.send(.onAppear) }
        .applyNighthawkBackground()
    }
    
    public init(store: StoreOf<Scan>) {
        self.store = store
    }
}

// MARK: - Subviews
private extension ScanView {
    func frameSize(_ size: CGSize) -> CGFloat {
        size.width * 0.55
    }

    func rectOfInterest(_ size: CGSize) -> CGRect {
        CGRect(
            x: size.width * 0.5,
            y: size.height * 0.5,
            width: frameSize(size),
            height: frameSize(size)
        )
    }
}

// MARK: - Private implementation
private struct CornerStrokeSquare: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let sideLength = min(rect.width, rect.height)
        let lineWidth: CGFloat = 2

        // Top-left corner
        path.move(to: CGPoint(x: rect.minX + lineWidth, y: rect.minY + sideLength / 4))
        path.addLine(to: CGPoint(x: rect.minX + lineWidth, y: rect.minY + lineWidth))
        path.addLine(to: CGPoint(x: rect.minX + sideLength / 4, y: rect.minY + lineWidth))

        // Top-right corner
        path.move(to: CGPoint(x: rect.maxX - sideLength / 4, y: rect.minY + lineWidth))
        path.addLine(to: CGPoint(x: rect.maxX - lineWidth, y: rect.minY + lineWidth))
        path.addLine(to: CGPoint(x: rect.maxX - lineWidth, y: rect.minY + sideLength / 4))

        // Bottom-right corner
        path.move(to: CGPoint(x: rect.maxX - lineWidth, y: rect.maxY - sideLength / 4))
        path.addLine(to: CGPoint(x: rect.maxX - lineWidth, y: rect.maxY - lineWidth))
        path.addLine(to: CGPoint(x: rect.maxX - sideLength / 4, y: rect.maxY - lineWidth))

        // Bottom-left corner
        path.move(to: CGPoint(x: rect.minX + sideLength / 4, y: rect.maxY - lineWidth))
        path.addLine(to: CGPoint(x: rect.minX + lineWidth, y: rect.maxY - lineWidth))
        path.addLine(to: CGPoint(x: rect.minX + lineWidth, y: rect.maxY - sideLength / 4))

        return path
    }
}

