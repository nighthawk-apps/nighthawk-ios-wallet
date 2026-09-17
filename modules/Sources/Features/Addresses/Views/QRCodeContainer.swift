//
//  QRCodeContainer.swift
//  wallet
//

import SwiftUI

struct QRCodeContainer: View {
    var qrImage: Image
    var badge: Image
    var body: some View {
        ZStack {
            qrImage
                .resizable()
                .aspectRatio(contentMode: .fit)
            badge
                .resizable()
                .frame(width: 64, height: 64)
        }
    }
}
