//
//  NHRecoveryPhraseDisplayView.swift
//  secant
//
//  Created by Matthew Watt on 3/24/23.
//

import ComposableArchitecture
import PDFKit
import SwiftUI
import ZcashLightClientKit

@MainActor
struct NHRecoveryPhraseDisplayView: View {
    let store: RecoveryPhraseDisplayStore
    
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                if let phrase = viewStore.phrase {
                    instructions
                    
                    backupSeedGrid(with: phrase)
                    
                    walletBirthday(with: viewStore.state.birthday)
                    
                    confirmPhrase(isChecked: viewStore.binding(\.$isConfirmSeedPhraseWrittenChecked))
                    
                    Spacer()
                    
                    actions(phrase: phrase, viewStore: viewStore)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 25)
            .padding(.horizontal, 25)
            .padding(.bottom, 66)
            .onAppear { viewStore.send(.onAppear) }
        }
        .applyNighthawkBackground()
    }
}

// MARK: - Subviews
private extension NHRecoveryPhraseDisplayView {
    @ViewBuilder
    var instructions: some View {
        Text(L10n.Nighthawk.RecoveryPhraseDisplay.title)
            .paragraph(color: Asset.Colors.Nighthawk.parmaviolet.color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 12)
        
        Text(L10n.Nighthawk.RecoveryPhraseDisplay.instructions1)
            .caption()
            .lineSpacing(6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 18)
        
        Text(L10n.Nighthawk.RecoveryPhraseDisplay.instructions2)
            .caption()
            .lineSpacing(6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 18)
    }
    
    func backupSeedGrid(with phrase: RecoveryPhrase) -> some View {
        LazyVGrid(columns: columns) {
            ForEach(Array(phrase.words.enumerated()), id: \.element.data) { index, word in
                HStack(alignment: .lastTextBaseline) {
                    Group {
                        Text("\(index + 1).")
                            .paragraph(color: Asset.Colors.Nighthawk.parmaviolet.color)
                        
                        Text(word.data)
                            .paragraph()
                    }
                    .lineSpacing(6)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 10)
            }
        }
        .background(Asset.Colors.Nighthawk.darkNavy.color)
        .padding(.bottom, 20)
    }
    
    @ViewBuilder
    func walletBirthday(with blockHeight: BlockHeight?) -> some View {
        if let blockHeight {
            HStack(alignment: .lastTextBaseline) {
                Group {
                    Text(L10n.Nighthawk.RecoveryPhraseDisplay.birthday)
                        .paragraph(color: Asset.Colors.Nighthawk.parmaviolet.color)
                    
                    Text("\(blockHeight)")
                        .paragraph()
                }
                .lineSpacing(6)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 23)
        }
    }
    
    func confirmPhrase(isChecked: Binding<Bool>) -> some View {
        NHCheckBox(isChecked: isChecked) {
            Text(L10n.Nighthawk.RecoveryPhraseDisplay.confirmPhraseWrittenDownCheckBox)
                .caption()
        }
        .frame(maxWidth: .infinity)
    }
    
    func actions(phrase: RecoveryPhrase, viewStore: ViewStoreOf<RecoveryPhraseDisplayReducer>) -> some View {
        VStack(spacing: 16) {
            Button(L10n.Nighthawk.RecoveryPhraseDisplay.continue) {
                viewStore.send(.finishedPressed)
            }
            .buttonStyle(.nighthawkPrimary(width: 152))
            .disabled(!viewStore.state.isConfirmSeedPhraseWrittenChecked)
            
            ShareLink(item: render(phrase: phrase, blockHeight: viewStore.state.birthday)) {
                Text(L10n.Nighthawk.RecoveryPhraseDisplay.exportAsPdf)
            }
            .buttonStyle(.nighthawkSecondary(width: 218))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Export as PDF
private extension NHRecoveryPhraseDisplayView {
    func render(phrase: RecoveryPhrase, blockHeight: BlockHeight?) -> URL {
        let renderer = ImageRenderer(
            content: VStack {
                backupSeedGrid(with: phrase)
                
                walletBirthday(with: blockHeight)
            }
            .frame(width: 300, height: 350)
            .applyNighthawkBackground()
        )
        
        let url = URL.documentsDirectory.appending(path: "seed.pdf")
        renderer.render { size, context in
            var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else {
                return
            }
            
            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }
        
        return url
    }
}
