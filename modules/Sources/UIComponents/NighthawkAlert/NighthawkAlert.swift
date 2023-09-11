//
//  NighthawkAlert.swift
//  
//
//  Created by Matthew Watt on 9/8/23.
//

import ComposableArchitecture
import Generated
import SwiftUI

struct NighthawkAlertModifier<NighthawkAlertContent: View>: ViewModifier {
    @Binding var isActive: Bool
    let content: () -> NighthawkAlertContent
    
    func body(content: Content) -> some View {
        content.overlay(
            ZStack {
                if self.isActive {
                    Rectangle()
                        .fill(Color.black.opacity(0.4))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture {
                            withAnimation {
                                self.isActive = false
                            }
                        }
                        .zIndex(1)
                        .transition(.opacity)
                    
                    self.content()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Asset.Colors.Nighthawk.darkNavy.color)
                        .cornerRadius(10)
                        .padding(24)
                        .padding(.bottom)
                        .zIndex(2)
                        .transition(.scale)
                }
            }
            .ignoresSafeArea()
        )
    }
}
