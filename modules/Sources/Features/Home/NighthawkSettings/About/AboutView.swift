//
//  AboutView.swift
//  secant
//
//  Created by Matthew Watt on 5/22/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

public struct AboutView: View {
    let store: StoreOf<About>
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView([.vertical], showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L10n.Nighthawk.About.title)
                        .subtitleMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)
                    
                    Text(L10n.Nighthawk.About.message)
                        .paragraphMedium(color: .white)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(6)
                    
                    Button(L10n.Nighthawk.About.viewSource) {
                        viewStore.send(.viewSourceTapped)
                    }
                    .buttonStyle(.nighthawkLink())
                    
                    Button(L10n.General.termsAndConditions) {
                        viewStore.send(.termsAndConditionsTapped)
                    }
                    .buttonStyle(.nighthawkLink())
                    
                    Spacer()
                    
                    // TODO: Add licenses list
//                    VStack {
//                        Button(L10n.Nighthawk.About.viewLicenses) {
//                            viewStore.send(.viewLicensesTapped)
//                        }
//                        .buttonStyle(.nighthawkPrimary())
//                    }
//                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 25)
            }
            .padding(.horizontal, 25)
        }
        .applyNighthawkBackground()
    }
    
    public init(store: StoreOf<About>) {
        self.store = store
    }
}
