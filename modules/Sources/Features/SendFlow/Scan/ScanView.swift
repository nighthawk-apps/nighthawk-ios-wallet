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

    public var body: some View {
        GeometryReader { geometry in
            let scanSize = min(geometry.size.width * 0.72, 320)

            ZStack {
                VStack(spacing: 24) {
                    Spacer(minLength: 0)

                    NighthawkHeading(
                        title: L10n.Nighthawk.TransferTab.Scan.scanPaymentRequest,
                        subtitle: L10n.Nighthawk.TransferTab.Scan.scanPaymentRequestDetails
                    )
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)

                    QRCodeScanView(
                        onQRScanningDidFail: { store.send(.scanFailed) },
                        onQRScanningSucceededWithCode: { store.send(.scan($0.redacted)) }
                    )
                    .frame(width: scanSize, height: scanSize)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        CornerStrokeSquare()
                            .stroke(Asset.Colors.Nighthawk.peach.color, lineWidth: 5)
                            .padding(18)
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
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
