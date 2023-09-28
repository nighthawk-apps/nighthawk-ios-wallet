//
//  NotificationsView.swift
//  secant
//
//  Created by Matthew Watt on 5/14/23.
//

import ComposableArchitecture
import Generated
import Models
import SwiftUI
import UIComponents

public struct NotificationsView: View {
    let store: StoreOf<Notifications>
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.Nighthawk.SettingsTab.SyncNotifications.title)
                    .subtitleMedium(color: Asset.Colors.Nighthawk.parmaviolet.color)
                
                Text(L10n.Nighthawk.SettingsTab.SyncNotifications.description)
                    .paragraphMedium(color: .white)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6)
                
                switch viewStore.selectedSyncNotificationFrequency {
                case .weekly:
                    Text(L10n.Nighthawk.SettingsTab.SyncNotifications.weeklyDescription)
                        .paragraphMedium(color: .white)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(6)
                case .monthly:
                    Text(L10n.Nighthawk.SettingsTab.SyncNotifications.monthlyDescription)
                        .paragraphMedium(color: .white)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(6)
                case .off:
                    EmptyView()
                }
                
                RadioSelectionList(
                    options: NighthawkSetting.SyncNotificationFrequency.allCases,
                    selection: viewStore.$selectedSyncNotificationFrequency.animation(.none)
                ) { option in
                    HStack {
                        switch option {
                        case .weekly:
                            Text(L10n.Nighthawk.SettingsTab.SyncNotifications.weeklyOption)
                                .paragraphMedium(color: .white)
                        case .monthly:
                            Text(L10n.Nighthawk.SettingsTab.SyncNotifications.monthlyOption)
                                .paragraphMedium(color: .white)
                        case .off:
                            Text(L10n.Nighthawk.SettingsTab.SyncNotifications.offOption)
                                .paragraphMedium(color: .white)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
                
                Spacer()
            }
            .padding(.top, 25)
            .padding(.horizontal, 25)
            .onAppear { viewStore.send(.onAppear) }
        }
        .applyNighthawkBackground()
        .alert(
            store: store.scope(
                state: \.$alert,
                action: { .alert($0) }
            )
        )
    }
    
    public init(store: StoreOf<Notifications>) {
        self.store = store
    }
}
