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
    @Bindable var store: StoreOf<Autoshield>
    
    public var body: some View {
        NavigationStack(
            path: $store.scope(
                state: \.path,
                action: \.path
            )
        ) {
            AutoshieldRootView(store: store)
                .applyNighthawkBackground()
                .alert(
                    $store.scope(
                        state: \.alert,
                        action: \.alert
                    )
                )
                .navigationTitle("")
        } destination: { store in
            switch store.case {
            case .inProgress:
                AutoshieldInProgressView()
                    .toolbar(.hidden, for: .navigationBar)
            case let .success(store):
                AutoshieldSuccessView(store: store)
                    .toolbar(.hidden, for: .navigationBar)
            case let .failed(store):
                AutoshieldFailedView(store: store)
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
    let store: StoreOf<Autoshield>
    
    private enum Constants {
        static let imageSizeRatio = 0.25
        static let paddingRatio = 0.1
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ScrollView([.vertical]) {
                    VStack(spacing: 24) {
                        Asset.Assets.Icons.Nighthawk.autoshield.image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geometry.size.width * Constants.imageSizeRatio, height: geometry.size.width * Constants.imageSizeRatio)
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
                    }
                }
                .layoutPriority(1)
                
                Spacer()
                                
                VStack(spacing: 8) {
                    Button(L10n.Nighthawk.Autoshield.buttonPositive) {
                        store.send(.positiveButtonTapped)
                    }
                    .buttonStyle(.largePrimary)
                    
                    Button(L10n.Nighthawk.Autoshield.buttonNeutral) {
                        store.send(.warnBeforeLeavingApp(eccURL))
                    }
                    .buttonStyle(.largeOutlined)
                }
            }
            .padding(geometry.size.width * Constants.paddingRatio)
        }
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
