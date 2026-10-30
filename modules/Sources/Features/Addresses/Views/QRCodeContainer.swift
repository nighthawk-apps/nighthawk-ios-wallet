//
//  QRCodeContainer.swift
//  wallet
//
//  Created by Francisco Gindre on 1/3/20.
//  Copyright © 2020 Francisco Gindre. All rights reserved.
//

import SwiftUI

struct QRCodeContainer: View {
    var qrImage: Image
    var badge: Image
    var body: some View {
        ZStack {
            qrImage
                .resizable().scaledToFit()
            badge
                .resizable()
                .frame(width: 64, height: 64)
        }
    }
}
