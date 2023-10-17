//
//  ChangeServerView.swift
//  secant
//
//  Created by Matthew Watt on 5/22/23.
//

import ComposableArchitecture
import Generated
import Models
import SwiftUI
import UIComponents

public struct ChangeServerView: View {
    let store: StoreOf<ChangeServer>
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView([.vertical], showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L10n.Nighthawk.SettingsTab.ChangeServer.title)
                        .subtitleMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)
                    
                    RadioSelectionList(
                        options: NighthawkSetting.LightwalletdServer.allCases,
                        selection: viewStore.$lightwalletdServer.animation(.none)
                    ) { option in
                        HStack {
                            Text(option.label)
                                .paragraphMedium(color: .white)
                            
                            Spacer()
                        }
                        .padding(.vertical, 12)
                    }
                    
                    Spacer()
                }
                .padding(.top, 25)
                .padding(.horizontal, 25)
            }
        }
        .applyNighthawkBackground()
        .alert(
            store: store.scope(
                state: \.$alert,
                action: { .alert($0) }
            )
        )
    }
    
    public init(store: StoreOf<ChangeServer>) {
        self.store = store
    }
}

