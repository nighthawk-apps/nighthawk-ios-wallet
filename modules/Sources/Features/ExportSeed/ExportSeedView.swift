//
//  ExportSeedView.swift
//
//
//  Created by Matthew Wat on 9/10/23.
//

import ComposableArchitecture
import Generated
import Models
import PDFKit
import SwiftUI
import UIComponents
import ZcashLightClientKit

public struct ExportSeedView: View {
    @Bindable var store: StoreOf<ExportSeed>
    
    public var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(L10n.Nighthawk.ExportSeed.title)
                    .title(color: .white)
                
                Spacer()
            }
            
            HStack {
                Text(L10n.Nighthawk.ExportSeed.description)
                    .subtitle(color: .white)
                    .lineSpacing(4)
                
                Spacer()
            }
            
            NighthawkTextField(
                placeholder: L10n.Nighthawk.ExportSeed.passwordPlaceholder,
                text: $store.password,
                isSecure: !store.isPasswordVisible,
                inputAccessoryView: {
                    VisibilityToggle(isVisible: $store.isPasswordVisible)
                        .foregroundColor(.secondary)
                }
            )
            .frame(maxWidth: .infinity)
            
            HStack {
                Button(L10n.General.cancel) {
                    store.send(.cancelTapped)
                }
                .buttonStyle(.nighthawkSecondary(width: 110))
                let groups = store.phrase.toGroups(groupSizeOverride: 3)
                ShareLink(item: render(groups: groups, blockHeight: store.state.birthday, password: store.password)) {
                    Text(L10n.Nighthawk.ExportSeed.export)
                }
                .buttonStyle(.nighthawkPrimary(width: 110))
                .disabled(store.password.isEmpty)
            }
        }
        .onAppear { store.send(.onAppear) }
    }
    
    public init(store: StoreOf<ExportSeed>) {
        self.store = store
    }
}

// MARK: - Export as PDF
private extension ExportSeedView {
    @MainActor
    func render(groups: [RecoveryPhrase.Group], blockHeight: BlockHeight, password: String) -> URL {
        let renderer = ImageRenderer(
            content: VStack(alignment: .leading) {
                Text(L10n.Nighthawk.RecoveryPhraseDisplay.pdfHeader)
                    .paragraph(color: .black)
                    .padding(.bottom, 23)
                
                SeedView(groups: groups, birthday: blockHeight, forPdf: true)
                
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
            guard let pdfData = CFDataCreateMutable(nil, 0) else { return }
            var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            guard let pdfDataConsumer = CGDataConsumer(data: pdfData),
                  let pdf = CGContext(consumer: pdfDataConsumer, mediaBox: &box, nil)
            else { return }
            
            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
            
            // Read as a PDF document and encrypt with the provided password
            guard let pdfDocument = PDFDocument(data: pdfData as Data) else { return }
            pdfDocument.write(
                to: url,
                withOptions: [
                    PDFDocumentWriteOption.userPasswordOption : password,
                    PDFDocumentWriteOption.ownerPasswordOption : password
                ]
            )
        }
        
        return url
    }
}

