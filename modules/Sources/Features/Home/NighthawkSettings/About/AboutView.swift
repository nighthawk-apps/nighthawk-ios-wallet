//
//  AboutView.swift
//  stealth
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
        ScrollView([.vertical], showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.Nighthawk.About.message)
                    .paragraphMedium(color: .white)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6)

                Button(L10n.Nighthawk.About.viewSource) {
                    store.send(.viewSourceTapped)
                }
                .buttonStyle(.nighthawkLink())

                Button(L10n.Nighthawk.About.nighthawkFriends) {
                    store.send(.nighthawkFriendsTapped)
                }
                .buttonStyle(.nighthawkLink())

                Button(L10n.General.termsAndConditions) {
                    store.send(.termsAndConditionsTapped)
                }
                .buttonStyle(.nighthawkLink())

                Spacer()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Open Source Licenses")
                        .subtitleMedium(color: .white)

                    licenseRow(name: "DarkFi", license: "AGPL-3.0")
                    licenseRow(name: "Arti (Tor)", license: "MIT / Apache-2.0")
                    licenseRow(name: "The Composable Architecture", license: "MIT")
                    licenseRow(name: "SwiftUI Navigation", license: "MIT")
                    licenseRow(name: "DarkIRC", license: "AGPL-3.0")
                    licenseRow(name: "gRPC Swift", license: "Apache-2.0")
                    licenseRow(name: "Turso / SQLite", license: "MIT")
                    licenseRow(name: "libsecp256k1", license: "MIT")
                }
                .padding(.top, 8)
            }
            .padding(.top, 8)
            .padding(.bottom, 25)
        }
        .padding(.horizontal, 25)
        .applyNighthawkBackground()
    }

    @ViewBuilder
    private func licenseRow(name: String, license: String) -> some View {
        HStack {
            Text(name)
                .paragraphMedium(color: .white)
            Spacer()
            Text(license)
                .caption(color: Asset.Colors.Nighthawk.parmaviolet.color)
        }
    }

    public init(store: StoreOf<About>) {
        self.store = store
    }
}
