//
//  AutoshieldView.swift
//
//
//  Created by Matthew Watt on 9/18/23.
//

import ComposableArchitecture
import Generated
import SwiftUI
import UIComponents

public struct AutoshieldView: View {
    let store: StoreOf<Autoshield>
    
    public var body: some View {
        NavigationStackStore(
            store.scope(
                state: \.path,
                action: { .path($0) }
            )
        ) {
            WithViewStore(store, observe: { $0 }) { viewStore in
                AutoshieldRootView(viewStore: viewStore)
            }
            .applyNighthawkBackground()
            .alert(
                store: store.scope(
                    state: \.$alert,
                    action: { .alert($0) }
                )
            )
            .navigationTitle("")
        } destination: { state in
            switch state {
            case .inProgress:
                AutoshieldInProgressView()
                    .toolbar(.hidden, for: .navigationBar)
            case .success:
                CaseLet(
                    /Autoshield.Path.State.success,
                     action: Autoshield.Path.Action.success,
                     then: AutoshieldSuccessView.init(store:)
                )
                .toolbar(.hidden, for: .navigationBar)
            case .failed:
                CaseLet(
                    /Autoshield.Path.State.failed,
                     action: Autoshield.Path.Action.failed,
                     then: AutoshieldFailedView.init(store:)
                )
                .toolbar(.hidden, for: .navigationBar)
            }
        }
    }
    
    public init(store: StoreOf<Autoshield>) {
        self.store = store
    }
}

// MARK: - Subviews
private struct AutoshieldRootView: View {
    let viewStore: ViewStoreOf<Autoshield>
    
    var body: some View {
        VStack(spacing: 24) {
            Asset.Assets.Icons.Nighthawk.autoshield.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
            HStack {
                Group {
                    Text(L10n.Nighthawk.Autoshield.title1) + Text(" ")
                    + Text(L10n.Nighthawk.Autoshield.shieldedByDefault)
                        .font(.custom(FontFamily.PulpDisplay.bold.name, size: 21)) + Text(" ")
                    + Text(L10n.Nighthawk.Autoshield.title2)
                }
                .foregroundColor(.white)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 21))
                .lineSpacing(6)
                
                Spacer()
            }
            
            HStack {
                Group {
                    Text(L10n.Nighthawk.Autoshield.autoshielding)
                        .font(.custom(FontFamily.PulpDisplay.bold.name, size: 16)) + Text(" ")
                    + Text(L10n.Nighthawk.Autoshield.detail1)
                }
                .foregroundColor(.white)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 16))
                .lineSpacing(4)
                
                Spacer()
            }
            
            HStack {
                Text(L10n.Nighthawk.Autoshield.detail2)
                    .subtitle(color: .white)
                    .lineSpacing(4)
                
                Spacer()
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Button(L10n.Nighthawk.Autoshield.buttonPositive) {
                    viewStore.send(.positiveButtonTapped)
                }
                .buttonStyle(.largePrimary)
                
                Button(L10n.Nighthawk.Autoshield.buttonNeutral) {
                    viewStore.send(.warnBeforeLeavingApp(eccURL))
                }
                .buttonStyle(.largeOutlined)
            }
        }
        .padding(48)
    }
    
    var eccURL: URL? {
        URL(string: "https://electriccoin.co/blog/unified-addresses-in-zcash-explained/")
    }
}

// MARK: - Button styles
private struct LargePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        LargePrimaryButton(configuration: configuration)
    }
    
    struct LargePrimaryButton: View {
        let configuration: ButtonStyle.Configuration
        var body: some View {
            configuration.label
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 14))
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(
                    Asset.Colors.Nighthawk.peach.color.opacity(configuration.isPressed ? 0.5 : 1.0)
                )
                .foregroundColor(Asset.Colors.Nighthawk.richBlack.color.opacity(configuration.isPressed ? 0.5 : 1.0))
                .cornerRadius(8)
        }
    }
}

private extension ButtonStyle where Self == LargePrimaryButtonStyle {
    static var largePrimary: LargePrimaryButtonStyle {
        LargePrimaryButtonStyle()
    }
}

private struct LargeOutlinedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        LargeOutlinedButton(configuration: configuration)
    }
    
    struct LargeOutlinedButton: View {
        let configuration: ButtonStyle.Configuration
        var body: some View {
            configuration.label
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 14))
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(
                    Asset.Colors.Nighthawk.darkNavy.color.opacity(configuration.isPressed ? 0.5 : 1.0)
                )
                .foregroundColor(.white.opacity(configuration.isPressed ? 0.5 : 1.0))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            Asset.Colors.Nighthawk.peach.color.opacity(configuration.isPressed ? 0.5 : 1.0),
                            style: StrokeStyle(lineWidth: 2)
                        )
                )
        }
    }
}

private extension ButtonStyle where Self == LargeOutlinedButtonStyle {
    static var largeOutlined: LargeOutlinedButtonStyle {
        LargeOutlinedButtonStyle()
    }
}
