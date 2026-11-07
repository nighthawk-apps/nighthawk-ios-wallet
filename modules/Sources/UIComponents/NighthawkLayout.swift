//
//  NighthawkLayout.swift
//
//  Shared fold / dual-pane breakpoints. Keep in lockstep with Android
//  `NighthawkExpandedWidth` (600.dp) and `wallpaper_wordmark_clearance` (48.dp).
//

import CoreGraphics

public enum NighthawkLayout {
    /// Width at or above this uses the leading nav rail and companion panes.
    public static let expandedWidth: CGFloat = 600

    /// Clears the wallpaper NIGHTHAWK wordmark under the status bar (fold rail).
    public static let wallpaperWordmarkClearance: CGFloat = 48

    /// Leading rail width — matches Android `NavigationRailWidth` (80.dp).
    public static let navigationRailWidth: CGFloat = 80
}
