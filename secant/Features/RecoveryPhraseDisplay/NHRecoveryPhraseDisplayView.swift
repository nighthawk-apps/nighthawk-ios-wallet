//
//  NHRecoveryPhraseDisplayView.swift
//  secant
//
//  Created by Matthew Watt on 3/24/23.
//

import ComposableArchitecture
import Generated
import Models
import PDFKit
import SwiftUI
import UIComponents
import ZcashLightClientKit

@MainActor
struct NHRecoveryPhraseDisplayView: View {
    let store: RecoveryPhraseDisplayStore
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                if let phrase = viewStore.phrase {
                    let groups = phrase.toGroups(groupSizeOverride: 3)
                    
                    instructions
                    
                    backupSeedGrid(with: groups)
                    
                    walletBirthday(with: viewStore.state.birthday)
                    
                    confirmPhrase(isChecked: viewStore.binding(\.$isConfirmSeedPhraseWrittenChecked))
                    
                    Spacer()
                    
                    actions(groups: groups, viewStore: viewStore)
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
    
    func backupSeedGrid(
        with groups: [RecoveryPhrase.Group],
        forPdf: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(groups, id: \.startIndex) { group in
                VStack {
                    HStack(alignment: .center) {
                        HStack {
                            HStack(alignment: .lastTextBaseline) {
                                Text("\(group.startIndex).")
                                    .paragraph(
                                        color: forPdf
                                        ? .black
                                        : Asset.Colors.Nighthawk.parmaviolet.color
                                    )

                                Text(group.words[0].data)
                                    .paragraph(color: forPdf ? .black : .white)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        
                        Spacer()
                        
                        HStack {
                            HStack(alignment: .lastTextBaseline) {
                                Text("\(group.startIndex + 1).")
                                    .paragraph(
                                        color: forPdf
                                        ? .black
                                        : Asset.Colors.Nighthawk.parmaviolet.color
                                    )

                                Text(group.words[1].data)
                                    .paragraph(color: forPdf ? .black : .white)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        
                        Spacer()
                        
                        HStack {
                            HStack(alignment: .lastTextBaseline) {
                                Text("\(group.startIndex + 2).")
                                    .paragraph(
                                        color: forPdf
                                        ? .black
                                        : Asset.Colors.Nighthawk.parmaviolet.color
                                    )

                                Text(group.words[2].data)
                                    .paragraph(color: forPdf ? .black : .white)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .modify {
            if forPdf {
                $0
            } else {
                $0.background(Asset.Colors.Nighthawk.darkNavy.color)
            }
        }
        .padding(.bottom, 20)
    }
    
    @ViewBuilder
    func walletBirthday(with blockHeight: BlockHeight?, forPdf: Bool = false) -> some View {
        if let blockHeight {
            HStack(alignment: .lastTextBaseline) {
                Group {
                    Text(L10n.Nighthawk.RecoveryPhraseDisplay.birthday)
                        .paragraph(
                            color: forPdf
                            ? .black
                            : Asset.Colors.Nighthawk.parmaviolet.color
                        )
                    
                    Text("\(blockHeight)")
                        .paragraph(
                            color: forPdf
                            ? .black
                            : .white
                        )
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
    
    func actions(groups: [RecoveryPhrase.Group], viewStore: ViewStoreOf<RecoveryPhraseDisplayReducer>) -> some View {
        VStack(spacing: 16) {
            Button(L10n.Nighthawk.RecoveryPhraseDisplay.continue) {
                viewStore.send(.finishedPressed)
            }
            .buttonStyle(.nighthawkPrimary(width: 152))
            .disabled(!viewStore.state.isConfirmSeedPhraseWrittenChecked)
            
            if viewStore.flow == .settings {
                ShareLink(item: render(groups: groups, blockHeight: viewStore.state.birthday)) {
                    Text(L10n.Nighthawk.RecoveryPhraseDisplay.exportAsPdf)
                }
                .buttonStyle(.nighthawkSecondary(width: 218))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Export as PDF
private extension NHRecoveryPhraseDisplayView {
    func render(groups: [RecoveryPhrase.Group], blockHeight: BlockHeight?) -> URL {
        let renderer = ImageRenderer(
            content: VStack(alignment: .leading) {
                Text(L10n.Nighthawk.RecoveryPhraseDisplay.pdfHeader)
                    .paragraph(color: .black)
                    .padding(.bottom, 23)
                
                backupSeedGrid(with: groups, forPdf: true)
                    .padding(.leading, 64)
                
                walletBirthday(with: blockHeight, forPdf: true)
                
                HStack {
                    Text(L10n.Nighthawk.RecoveryPhraseDisplay.pdfTimestamp(Date.now.asHumanReadable()))
                        .paragraph(color: .black)
                    
                    Spacer()
                }
                
                Spacer()
            }
            .frame(width: 612, height: 792)
            .padding(64)
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
