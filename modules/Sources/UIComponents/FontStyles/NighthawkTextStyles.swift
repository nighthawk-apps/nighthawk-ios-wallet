//
//  NighthawkTextStyles.swift
//  secant
//
//  Created by Matthew Watt on 3/17/23.
//

import SwiftUI
import Generated

public extension Text {
    func title(color: Color = Asset.Colors.Nighthawk.peach.color) -> some View {
        self.modifier(TitleTextStyle(color: color))
    }
    
    func subtitle(color: Color = Asset.Colors.Nighthawk.peach.color) -> some View {
        self.modifier(SubtitleTextStyle(color: color))
    }
    
    func subtitleMedium(color: Color = .white) -> some View {
        self.modifier(SubtitleMediumTextStyle(color: color))
    }
    
    func paragraph(color: Color = .white) -> some View {
        self.modifier(ParagraphTextStyle(color: color))
    }
    
    func paragraphMedium(color: Color = Asset.Colors.Nighthawk.parmaviolet.color) -> some View {
        self.modifier(ParagraphMediumTextStyle(color: color))
    }
    
    func paragraphBold(color: Color = Asset.Colors.Nighthawk.parmaviolet.color) -> some View {
        self.modifier(ParagraphBoldTextStyle(color: color))
    }
    
    func caption(color: Color = .white) -> some View {
        self.modifier(CaptionTextStyle(color: color))
    }
    
    func captionBold(color: Color = .white) -> some View {
        self.modifier(CaptionBoldTextStyle(color: color))
    }

    private struct TitleTextStyle: ViewModifier {
        var color: Color
        
        func body(content: Content) -> some View {
            content
                .foregroundColor(color)
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
    
    private struct SubtitleMediumTextStyle: ViewModifier {
        var color: Color
        
        func body(content: Content) -> some View {
            content
                .foregroundColor(color)
                .font(.custom(FontFamily.PulpDisplay.medium.name, size: 16))
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
    
    private struct ParagraphBoldTextStyle: ViewModifier {
        var color: Color
        
        func body(content: Content) -> some View {
            content
                .foregroundColor(color)
                .font(.custom(FontFamily.PulpDisplay.bold.name, size: 14))
        }
    }
    
    private struct CaptionTextStyle: ViewModifier {
        var color: Color
        
        func body(content: Content) -> some View {
            content
                .foregroundColor(color)
                .font(.custom(FontFamily.PulpDisplay.regular.name, size: 12))
                .lineSpacing(6)
        }
    }
    
    private struct CaptionBoldTextStyle: ViewModifier {
        var color: Color
        
        func body(content: Content) -> some View {
            content
                .foregroundColor(color)
                .font(.custom(FontFamily.PulpDisplay.bold.name, size: 12))
                .lineSpacing(6)
        }
    }
}
