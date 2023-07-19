//
//  NHSettingsView.swift
//  secant
//
//  Created by Matthew Watt on 5/5/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

struct NHSettingsView: View {
    let store: Store<NHSettingsReducer.State, NHSettingsReducer.Action>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            ScrollView([.vertical], showsIndicators: false) {
                NighthawkLogo(spacing: .compact)
                    .padding(.vertical, 40)
                
                HStack {
                    Text(L10n.Nighthawk.SettingsTab.settings)
                        .paragraphMedium()
                    Spacer()
                }
                
                ForEach(NHSettingsReducer.State.Destination.allCases) { destination in
                    settingRow(with: viewStore, destination: destination)
                }
            }
            .padding(.horizontal, 25)
            .navigationLinkEmpty(
                isActive: viewStore.bindingForDestination(.notifications),
                destination: {
                    NotificationsView(store: store.notificationsStore())
                }
            )
            .navigationLinkEmpty(
                isActive: viewStore.bindingForDestination(.fiatCurrency),
                destination: {
                    FiatView(store: store.fiatStore())
                }
            )
            .navigationLinkEmpty(
                isActive: viewStore.bindingForDestination(.security),
                destination: {
                    SecurityView(store: store.securityStore())
                }
            )
            .navigationLinkEmpty(
                isActive: viewStore.bindingForDestination(.backup),
                destination: {
                    BackupView(store: store.backupStore())
                }
            )
            .navigationLinkEmpty(
                isActive: viewStore.bindingForDestination(.rescan),
                destination: {
                    RescanView(store: store.rescanStore())
                }
            )
            .navigationLinkEmpty(
                isActive: viewStore.bindingForDestination(.changeServer),
                destination: {
                    ChangeServerView(store: store.changeServerStore())
                }
            )
            .navigationLinkEmpty(
                isActive: viewStore.bindingForDestination(.externalServices),
                destination: {
                    ExternalServicesView(store: store.externalServicesStore())
                }
            )
            .navigationLinkEmpty(
                isActive: viewStore.bindingForDestination(.about),
                destination: {
                    AboutView(store: store.aboutStore())
                }
            )
            .onAppear { viewStore.send(.onAppear) }
        }
        .applyNighthawkBackground()
    }
}

// MARK: - Subviews
private extension NHSettingsView {
    func settingRow(
        with viewStore: ViewStore<NHSettingsReducer.State, NHSettingsReducer.Action>,
        destination: NHSettingsReducer.State.Destination
    ) -> some View {
        Button {
            viewStore.send(.updateDestination(destination))
        } label: {
            VStack {
                HStack(alignment: .center, spacing: 14) {
                    destination.image
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(.white)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(destination.title)
                            .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                            .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
                            .multilineTextAlignment(.leading)
                        
                        Group {
                            if destination == .about {
                                Text(L10n.Nighthawk.SettingsTab.aboutSubtitle(viewStore.appVersion))
                                    .caption()
                            } else {
                                Text(destination.subtitle)
                                    .caption()
                            }
                        }
                        .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                
                Divider()
                    .frame(height: 2)
                    .overlay(Asset.Colors.Nighthawk.navy.color)
            }
        }
    }
}
