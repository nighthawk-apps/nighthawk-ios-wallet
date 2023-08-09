//
//  RadioSelectionList.swift
//  
//
//  Created by Matthew Watt on 8/3/23.
//

import Generated
import SwiftUI

public struct RadioSelectionList<Option: Identifiable & Hashable, OptionContent: View>: View {
    let options: [Option]
    let selection: Binding<Option?>
    let optionContent: (Option) -> OptionContent
    
    public init(
        options: [Option],
        selection: Binding<Option?>,
        optionContent: @escaping (Option) -> OptionContent
    ) {
        self.options = options
        self.selection = selection
        self.optionContent = optionContent
    }
    
    public var body: some View {
        VStack {
            ForEach(options) { option in
                Button(action: { selection.wrappedValue = option }) {
                    HStack(alignment: .center) {
                        ZStack {
                            Circle()
                                .stroke(Asset.Colors.Nighthawk.peach.color, lineWidth: 2)
                                .frame(width: 20, height: 20)
                            
                            if option == selection.wrappedValue {
                                Circle()
                                    .fill(Asset.Colors.Nighthawk.peach.color)
                                    .frame(width: 10, height: 10)
                            }
                        }
                        .frame(width: 24, height: 24)
                        
                        optionContent(option)
                        
                        Spacer()
                    }
                }
            }
        }
    }
}
