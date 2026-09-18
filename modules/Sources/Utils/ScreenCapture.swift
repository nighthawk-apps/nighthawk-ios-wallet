import UIKit

/// Window-scene screen, avoiding deprecated `UIScreen.main` on the iOS 26/27 SDK.
public enum ScreenCapture {
    public static var current: UIScreen {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let key = scenes.flatMap(\.windows).first(where: \.isKeyWindow) {
            return key.screen
        }
        if let screen = scenes.first?.screen {
            return screen
        }
        return fallbackMainScreen()
    }

    public static var isCaptured: Bool { current.isCaptured }

    public static var bounds: CGRect { current.bounds }

    /// Isolated so the iOS 26 deprecation of `UIScreen.main` stays in one place.
    @available(iOS, deprecated: 26.0)
    private static func fallbackMainScreen() -> UIScreen { UIScreen.main }
}
