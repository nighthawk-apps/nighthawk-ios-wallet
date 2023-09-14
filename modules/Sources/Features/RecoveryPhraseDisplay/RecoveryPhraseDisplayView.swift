//
//  NHRecoveryPhraseDisplayView.swift
//  secant
//
//  Created by Matthew Watt on 3/24/23.
//

import ComposableArchitecture
import ExportSeed
import Generated
import Models
import PDFKit
import SwiftUI
import UIComponents
import ZcashLightClientKit

public struct RecoveryPhraseDisplayView: View {
    let store: StoreOf<RecoveryPhraseDisplay>
    
    public init(store: StoreOf<RecoveryPhraseDisplay>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                Group {
                    let groups = viewStore.phrase.toGroups(groupSizeOverride: 3)
                    
                    instructions
                    
                    backupSeedGrid(with: groups)
                    
                    walletBirthday(with: viewStore.state.birthday)
                    
                    if viewStore.flow == .onboarding {
                        confirmPhrase(isChecked: viewStore.binding(\.$isConfirmSeedPhraseWrittenChecked))
                    }
                    
                    Spacer()
                    
                    actions(groups: groups, viewStore: viewStore)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 25)
            .padding(.horizontal, 25)
            .padding(.bottom, 66)
            .onAppear { viewStore.send(.onAppear) }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .applyNighthawkBackground()
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .nighthawkAlert(
            store: store.scope(
                state: \.$destination,
                action: { .destination($0) }
            ),
            state: /RecoveryPhraseDisplay.Destination.State.exportSeedAlert,
            action: RecoveryPhraseDisplay.Destination.Action.exportSeedAlert
        ) { store in
            ExportSeedView(store: store)
        }
    }
}

// MARK: - Subviews
private extension RecoveryPhraseDisplayView {
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
        CheckBox(isChecked: isChecked) {
            Text(L10n.Nighthawk.RecoveryPhraseDisplay.confirmPhraseWrittenDownCheckBox)
                .caption()
        }
        .frame(maxWidth: .infinity)
    }
    
    @MainActor
    func actions(groups: [RecoveryPhrase.Group], viewStore: ViewStoreOf<RecoveryPhraseDisplay>) -> some View {
        Group {
            if viewStore.flow == .settings {
                Button(L10n.Nighthawk.RecoveryPhraseDisplay.exportAsPdf) {
                    viewStore.send(.exportAsPdfPressed, animation: .easeInOut)
                }
                .buttonStyle(.nighthawkPrimary(width: 218))
                //                ShareLink(item: render(groups: groups, blockHeight: viewStore.state.birthday)) {
                //                    Text(L10n.Nighthawk.RecoveryPhraseDisplay.exportAsPdf)
                //                }
                //                .buttonStyle(.nighthawkPrimary(width: 218))
            } else {
                Button(L10n.Nighthawk.RecoveryPhraseDisplay.continue) {
                    viewStore.send(.continuePressed)
                }
                .buttonStyle(.nighthawkPrimary(width: 152))
                .disabled(!viewStore.state.isConfirmSeedPhraseWrittenChecked)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Export as PDF
private extension RecoveryPhraseDisplayView {
    @MainActor
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
        
        let url = URL.documentsDirectory.appending(path: "encrypted_seed.pdf")
        renderer.render { size, context in
            var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, [kCGPDFContextOwnerPassword: "password" as CFString] as CFDictionary) else {
                return
            }
            
            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
            
            // Read as a PDF document and encrypt with the provided password
            guard let pdfDocument = PDFDocument(url: url) else { return }
            pdfDocument.write(
                to: url,
                withOptions: [
                    PDFDocumentWriteOption.userPasswordOption : "password",
                    PDFDocumentWriteOption.ownerPasswordOption : "password"
                ]
            )
        }
        
        return url
    }
}
