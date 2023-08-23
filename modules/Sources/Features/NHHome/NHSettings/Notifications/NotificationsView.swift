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

struct NotificationsView: View {
    let store: Store<NotificationsReducer.State, NotificationsReducer.Action>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.Nighthawk.SettingsTab.SyncNotifications.title)
                    .paragraphMedium()
                
                Text(L10n.Nighthawk.SettingsTab.SyncNotifications.description)
                    .caption()
                    .multilineTextAlignment(.leading)
                
                switch viewStore.selectedSyncNotificationFrequency {
                case .weekly:
                    Text(L10n.Nighthawk.SettingsTab.SyncNotifications.weeklyDescription)
                        .caption()
                        .multilineTextAlignment(.leading)
                case .monthly:
                    Text(L10n.Nighthawk.SettingsTab.SyncNotifications.monthlyDescription)
                        .caption()
                        .multilineTextAlignment(.leading)
                case .off:
                    EmptyView()
                }
                
                RadioSelectionList(
                    options: NighthawkSetting.SyncNotificationFrequency.allCases,
                    selection: viewStore.binding(\.$selectedSyncNotificationFrequency).animation(.none)
                ) { option in
                    HStack {
                        switch option {
                        case .weekly:
                            Text(L10n.Nighthawk.SettingsTab.SyncNotifications.weeklyOption)
                                .paragraph()
                        case .monthly:
                            Text(L10n.Nighthawk.SettingsTab.SyncNotifications.monthlyOption)
                                .paragraph()
                        case .off:
                            Text(L10n.Nighthawk.SettingsTab.SyncNotifications.offOption)
                                .paragraph()
                        }

                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
                
                Spacer()
            }
            .padding(.top, 25)
            .padding(.horizontal, 25)
        }
        .applyNighthawkBackground()
    }
}
