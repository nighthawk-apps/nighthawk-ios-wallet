//
//  NighthawkTextStyles.swift
//  secant
//
//  Created by Matthew Watt on 3/17/23.
//

import SwiftUI
import Generated

public extension Text {
    var title: some View {
        self.modifier(TitleTextStyle())
    }
    
    func subtitle(color: Color = Asset.Colors.Nighthawk.peach.color) -> some View {
        self.modifier(SubtitleTextStyle(color: color))
    }
    
    func paragraph(color: Color = .white) -> some View {
        self.modifier(ParagraphTextStyle(color: color))
    }
    
    func paragraphMedium(color: Color = Asset.Colors.Nighthawk.parmaviolet.color) -> some View {
        self.modifier(ParagraphMediumTextStyle(color: color))
    }
    
    func caption(color: Color = .white) -> some View {
        self.modifier(CaptionTextStyle(color: color))
    }

    private struct TitleTextStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .foregroundColor(Asset.Colors.Nighthawk.peach.color)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 21))
        }
    }
    
    private struct SubtitleTextStyle: ViewModifier {
        var color: Color
        
        func body(content: Content) -> some View {
            content
                .foregroundColor(color)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 16))
        }
    }
    
    private struct ParagraphTextStyle: ViewModifier {
        var color: Color
        
        func body(content: Content) -> some View {
            content
                .foregroundColor(color)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 14))
        }
    }
    
    private struct ParagraphMediumTextStyle: ViewModifier {
        var color: Color
        
        func body(content: Content) -> some View {
            content
                .foregroundColor(color)
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 14))
        }
    }
    
    private struct CaptionTextStyle: ViewModifier {
        var color: Color
        
        func body(content: Content) -> some View {
            content
                .foregroundColor(color)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
        }
    }
}
