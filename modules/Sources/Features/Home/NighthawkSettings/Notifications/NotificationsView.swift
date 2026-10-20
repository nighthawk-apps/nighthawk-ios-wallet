//
//  NotificationsView.swift
//  stealth
//
//  Created by Matthew Watt on 5/14/23.
//

import ComposableArchitecture
import Generated
import Models
import SwiftUI
import UIComponents

public struct NotificationsView: View {
    @Bindable var store: StoreOf<Notifications>

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.Nighthawk.SettingsTab.SyncNotifications.description)
                .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
                .multilineTextAlignment(.leading)
                .lineSpacing(6)

            switch store.selectedSyncNotificationFrequency {
            case .weekly:
                Text(L10n.Nighthawk.SettingsTab.SyncNotifications.weeklyDescription)
                    .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6)
            case .monthly:
                Text(L10n.Nighthawk.SettingsTab.SyncNotifications.monthlyDescription)
                    .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6)
            case .off:
                EmptyView()
            }

            RadioSelectionList(
                options: NighthawkSetting.SyncNotificationFrequency.allCases,
                selection: $store.selectedSyncNotificationFrequency.animation(.none)
            ) { option in
                HStack {
                    switch option {
                    case .weekly:
                        Text(L10n.Nighthawk.SettingsTab.SyncNotifications.weeklyOption)
                            .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
                    case .monthly:
                        Text(L10n.Nighthawk.SettingsTab.SyncNotifications.monthlyOption)
                            .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
                    case .off:
                        Text(L10n.Nighthawk.SettingsTab.SyncNotifications.offOption)
                            .paragraphMedium(color: Asset.Colors.Nighthawk.textHeader.color)
                    }

                    Spacer()
                }
                .padding(.vertical, 12)
            }

            Spacer()
        }
        .padding(.top, 8)
        .padding(.horizontal, 25)
        .onAppear { store.send(.onAppear) }
        .applyNighthawkBackground()
        .alert(
            $store.scope(
                state: \.alert,
                action: \.alert
            )
        )
    }

    public init(store: StoreOf<Notifications>) {
        self.store = store
    }
}
