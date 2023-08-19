import SwiftUI
import ComposableArchitecture
import Generated
import RecoveryPhraseDisplay
import UIComponents

public struct SettingsView: View {
    let store: SettingsStore
    
    public init(store: SettingsStore) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store) { viewStore in
            VStack(spacing: 40) {
                Button(
                    action: { viewStore.send(.backupWalletAccessRequest) },
                    label: { Text(L10n.Settings.backupWallet) }
                )
                .activeButtonStyle
                .frame(height: 50)
                
                Button(
                    action: { viewStore.send(.sendSupportMail) },
                    label: { Text(L10n.Settings.feedback) }
                )
                .activeButtonStyle
                .frame(height: 50)

                Spacer()
                
                Button(
                    action: { viewStore.send(.updateDestination(.about)) },
                    label: { Text(L10n.Settings.about) }
                )
                .activeButtonStyle
                .frame(maxHeight: 50)
                .padding(.bottom, 50)
            }
            .padding(.horizontal, 30)
            .navigationTitle(L10n.Settings.title)
            .applyScreenBackground()
            .navigationLinkEmpty(
                isActive: viewStore.bindingForBackupPhrase,
                destination: {
                    RecoveryPhraseDisplayView(store: store.backupPhraseStore())
                }
            )
            .navigationLinkEmpty(
                isActive: viewStore.bindingForAbout,
                destination: {
                    About(store: store)
                }
            )
            .onAppear { viewStore.send(.onAppear) }

            if let supportData = viewStore.supportData {
                UIMailDialogView(
                    supportData: supportData,
                    completion: {
                        viewStore.send(.sendSupportMailFinished)
                    }
                )
                // UIMailDialogView only wraps MFMailComposeViewController presentation
                // so frame is set to 0 to not break SwiftUIs layout
                .frame(width: 0, height: 0)
            }
        }
        .alert(store: store.scope(
            state: \.$alert,
            action: { .alert($0) }
        ))
    }
}

// MARK: - Previews

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(store: .placeholder)
    }
}
