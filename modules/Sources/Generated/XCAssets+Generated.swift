// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import SwiftUI
#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ColorAsset.SystemColor", message: "This typealias will be removed in SwiftGen 7.0")
public typealias AssetColorTypeAlias = ColorAsset.SystemColor
@available(*, deprecated, renamed: "ImageAsset.UniversalImage", message: "This typealias will be removed in SwiftGen 7.0")
public typealias AssetImageTypeAlias = ImageAsset.UniversalImage

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
public enum Asset {
  public enum Assets {
    public enum Backgrounds {
      public static let callout0 = ImageAsset(name: "callout0")
      public static let callout1 = ImageAsset(name: "callout1")
      public static let callout2 = ImageAsset(name: "callout2")
      public static let callout3 = ImageAsset(name: "callout3")
      public static let callout4 = ImageAsset(name: "callout4")
      public static let calloutBackupFailed = ImageAsset(name: "calloutBackupFailed")
      public static let calloutBackupFlow1 = ImageAsset(name: "calloutBackupFlow1")
      public static let calloutBackupSucceeded = ImageAsset(name: "calloutBackupSucceeded")
    }
    public enum Icons {
      public enum Nighthawk {
        public static let about = ImageAsset(name: "about")
        public static let autoshield = ImageAsset(name: "autoshield")
        public static let backup = ImageAsset(name: "backup")
        public static let boxedQrCode = ImageAsset(name: "boxed_qr_code")
        public static let check = ImageAsset(name: "check")
        public static let checked = ImageAsset(name: "checked")
        public static let chevronLeft = ImageAsset(name: "chevron_left")
        public static let chevronRight = ImageAsset(name: "chevron_right")
        public static let connecting = ImageAsset(name: "connecting")
        public static let copy = ImageAsset(name: "copy")
        public static let defaultIconPreview = ImageAsset(name: "default_icon_preview")
        public static let doubleCheck = ImageAsset(name: "double_check")
        public static let error = ImageAsset(name: "error")
        public static let failed = ImageAsset(name: "failed")
        public static let fiat = ImageAsset(name: "fiat")
        public static let hidden = ImageAsset(name: "hidden")
        public static let memo = ImageAsset(name: "memo")
        public static let nhQrCode = ImageAsset(name: "nhQrCode")
        public static let nighthawkSymbol = ImageAsset(name: "nighthawk_symbol")
        public static let nighthawkSymbolPeach = ImageAsset(name: "nighthawk_symbol_peach")
        public static let notifications = ImageAsset(name: "notifications")
        public static let piggy = ImageAsset(name: "piggy")
        public static let poweredByZcash = ImageAsset(name: "powered_by_zcash")
        public static let preparing = ImageAsset(name: "preparing")
        public static let receive = ImageAsset(name: "receive")
        public static let received = ImageAsset(name: "received")
        public static let rescan = ImageAsset(name: "rescan")
        public static let retroIconPreview = ImageAsset(name: "retro_icon_preview")
        public static let saplingBadge = ImageAsset(name: "sapling_badge")
        public static let security = ImageAsset(name: "security")
        public static let send = ImageAsset(name: "send")
        public static let sent = ImageAsset(name: "sent")
        public static let server = ImageAsset(name: "server")
        public static let services = ImageAsset(name: "services")
        public static let settings = ImageAsset(name: "settings")
        public static let shielded = ImageAsset(name: "shielded")
        public static let sideshift = ImageAsset(name: "sideshift")
        public static let stealthex = ImageAsset(name: "stealthex")
        public static let swipe = ImageAsset(name: "swipe")
        public static let syncing = ImageAsset(name: "syncing")
        public static let topUp = ImageAsset(name: "topUp")
        public static let transfer = ImageAsset(name: "transfer")
        public static let transparentBadge = ImageAsset(name: "transparent_badge")
        public static let unchecked = ImageAsset(name: "unchecked")
        public static let unifiedBadge = ImageAsset(name: "unified_badge")
        public static let unshielded = ImageAsset(name: "unshielded")
        public static let visible = ImageAsset(name: "visible")
        public static let wallet = ImageAsset(name: "wallet")
      }
    }
  }
  public enum Colors {
    public enum Nighthawk {
      public static let darkNavy = ColorAsset(name: "darkNavy")
      public static let error = ColorAsset(name: "error")
      public static let navy = ColorAsset(name: "navy")
      public static let parmaviolet = ColorAsset(name: "parmaviolet")
      public static let peach = ColorAsset(name: "peach")
      public static let richBlack = ColorAsset(name: "richBlack")
    }
  }
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

public final class ColorAsset {
  public fileprivate(set) var name: String

  #if os(macOS)
  public typealias SystemColor = NSColor
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  public typealias SystemColor = UIColor
  #endif

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  public private(set) lazy var systemColor: SystemColor = {
    guard let color = SystemColor(asset: self) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }()

  public private(set) lazy var color: Color = {
    Color(systemColor)
  }()

  fileprivate init(name: String) {
    self.name = name
  }
}

public extension ColorAsset.SystemColor {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  convenience init?(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

public struct ImageAsset {
  public fileprivate(set) var name: String

  #if os(macOS)
  public typealias UniversalImage = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  public typealias UniversalImage = UIImage
  #endif

  public var systemImage: UniversalImage {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    let image = UniversalImage(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = UniversalImage(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }

  public var image: Image {
    let bundle = BundleToken.bundle
    return Image(name, bundle: bundle)
  }
}

public extension ImageAsset.UniversalImage {
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init?(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = BundleToken.bundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}

// swiftlint:enable convenience_type
