//
//  QRCodeScanView.swift
//  stealth
//

import SwiftUI

struct QRCodeScanView: UIViewRepresentable {
    let onQRScanningDidFail: () -> Void
    let onQRScanningSucceededWithCode: (String) -> Void

    func makeUIView(context: Context) -> ScanUIView {
        let view = ScanUIView()
        view.onQRScanningDidFail = onQRScanningDidFail
        view.onQRScanningSucceededWithCode = onQRScanningSucceededWithCode
        return view
    }

    func updateUIView(_ uiView: ScanUIView, context: Context) { }
}
