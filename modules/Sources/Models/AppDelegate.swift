//
//  AppDelegate.swift
//  secant-testnet
//
//  Created by Lukáš Korba on 27.03.2022.
//

import Foundation
import SwiftUI

public enum AppDelegateAction: Equatable {
    case didFinishLaunching
}

public enum SceneAction: Equatable {
    case didChangePhase(ScenePhase)
}
