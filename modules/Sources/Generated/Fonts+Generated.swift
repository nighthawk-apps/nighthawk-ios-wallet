// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import SwiftUI
#if os(OSX)
import AppKit.NSFont
#elseif os(iOS) || os(tvOS) || os(watchOS)
import UIKit.UIFont
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "FontConvertible.Font", message: "This typealias will be removed in SwiftGen 7.0")
public typealias SystemFont = FontConvertible.SystemFont

// MARK: - Fonts

public enum FontFamily {
    public enum PulpDisplay {
        public static let bold = FontConvertible(name: "Outfit-Bold", family: "Outfit", path: "outfit.ttf")
        public static let medium = FontConvertible(name: "Outfit-Medium", family: "Outfit", path: "outfit.ttf")
        public static let regular = FontConvertible(name: "Outfit-Regular", family: "Outfit", path: "outfit.ttf")
        public static let all: [FontConvertible] = [bold, medium, regular]
    }
    public enum SourceSans3 {
        public static let medium = FontConvertible(name: "SourceSans3-Medium", family: "Source Sans 3", path: "source_sans_3.ttf")
        public static let regular = FontConvertible(name: "SourceSans3-Regular", family: "Source Sans 3", path: "source_sans_3.ttf")
        public static let all: [FontConvertible] = [medium, regular]
    }
    public enum SourceSerif4 {
        public static let regular = FontConvertible(name: "SourceSerif4Roman-Regular", family: "Source Serif 4", path: "source_serif_4.ttf")
        public static let all: [FontConvertible] = [regular]
    }
    public enum IbmPlexMono {
        public static let regular = FontConvertible(name: "IBMPlexMono-Regular", family: "IBM Plex Mono", path: "ibm_plex_mono.ttf")
        public static let all: [FontConvertible] = [regular]
    }
    public enum DejaVuSansMono {
        public static let regular = FontConvertible(name: "DejaVuSansMono", family: "DejaVu Sans Mono", path: "DejaVuSansMono.ttf")
        public static let bold = FontConvertible(name: "DejaVuSansMono-Bold", family: "DejaVu Sans Mono", path: "DejaVuSansMono-Bold.ttf")
        public static let all: [FontConvertible] = [regular, bold]
    }
    public static let allCustomFonts: [FontConvertible] = [
        PulpDisplay.all,
        SourceSans3.all,
        SourceSerif4.all,
        IbmPlexMono.all,
        DejaVuSansMono.all
    ].flatMap { $0 }
    public static func registerAllCustomFonts() {
        allCustomFonts.forEach { $0.register() }
    }
}

// MARK: - Implementation Details

public struct FontConvertible {
    public let name: String
    public let family: String
    public let path: String

    #if os(OSX)
    public typealias SystemFont = NSFont
    #elseif os(iOS) || os(tvOS) || os(watchOS)
    public typealias SystemFont = UIFont
    #endif

    public func font(size: CGFloat) -> SystemFont {
        guard let font = SystemFont(font: self, size: size) else {
            fatalError("Unable to initialize font '\(name)' (\(family))")
        }
        return font
    }

    public func textStyle(_ textStyle: Font.TextStyle) -> Font {
        Font.mappedFont(name, textStyle: textStyle)
    }

    public func register() {
        guard let url = url else { return }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }

    fileprivate var url: URL? {
        return BundleToken.bundle.url(forResource: path, withExtension: nil)
    }
}

public extension FontConvertible.SystemFont {
    convenience init?(font: FontConvertible, size: CGFloat) {
        #if os(iOS) || os(tvOS) || os(watchOS)
        if !UIFont.fontNames(forFamilyName: font.family).contains(font.name) {
            font.register()
        }
        #elseif os(OSX)
        if let url = font.url, CTFontManagerGetScopeForURL(url as CFURL) == .none {
            font.register()
        }
        #endif

        self.init(name: font.name, size: size)
    }
}

private final class BundleToken {
    static let bundle: Bundle = {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: BundleToken.self)
        #endif
    }()
}

fileprivate extension Font {
    static func mappedFont(_ name: String, textStyle: TextStyle) -> Font {
        let fontSize = UIFont.preferredFont(forTextStyle: self.mapToUIFontTextStyle(textStyle)).pointSize
        return Font.custom(name, size: fontSize, relativeTo: textStyle)
    }

    static func mapToUIFontTextStyle(_ textStyle: SwiftUI.Font.TextStyle) -> UIFont.TextStyle {
        switch textStyle {
        case .largeTitle:
            return .largeTitle
        case .title:
            return .title1
        case .title2:
            return .title2
        case .title3:
            return .title3
        case .headline:
            return .headline
        case .subheadline:
            return .subheadline
        case .callout:
            return .callout
        case .body:
            return .body
        case .caption:
            return .caption1
        case .caption2:
            return .caption2
        case .footnote:
            return .footnote
        @unknown default:
            fatalError("Missing a TextStyle mapping")
        }
    }
}
