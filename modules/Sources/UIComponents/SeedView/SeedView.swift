//
//  SeedGrid.swift
//  
//
//  Created by Matthew Watt on 9/15/23.
//

import Generated
import Models
import SwiftUI
import ZcashLightClientKit

public struct SeedView: View {
    let groups: [RecoveryPhrase.Group]
    let birthday: BlockHeight
    let forPdf: Bool
    
    public var body: some View {
        VStack {
            SeedGridView(groups: groups, forPdf: forPdf)
            SeedBirthdayView(birthday: birthday, forPdf: forPdf)
        }
    }
    
    public init(groups: [RecoveryPhrase.Group], birthday: BlockHeight, forPdf: Bool = false) {
        self.groups = groups
        self.birthday = birthday
        self.forPdf = forPdf
    }
}

struct SeedGridView: View {
    let groups: [RecoveryPhrase.Group]
    let forPdf: Bool
    
    var body: some View {
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
    
    init(groups: [RecoveryPhrase.Group], forPdf: Bool) {
        self.groups = groups
        self.forPdf = forPdf
    }
}

struct SeedBirthdayView: View {
    let birthday: BlockHeight
    let forPdf: Bool
    
    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            Group {
                Text(L10n.Nighthawk.RecoveryPhraseDisplay.birthday)
                    .paragraphMedium(
                        color: forPdf
                        ? .black
                        : Asset.Colors.Nighthawk.parmaviolet.color
                    )
                
                Text("\(birthday)")
                    .paragraphMedium(
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
    
    init(birthday: BlockHeight, forPdf: Bool) {
        self.birthday = birthday
        self.forPdf = forPdf
    }
}
