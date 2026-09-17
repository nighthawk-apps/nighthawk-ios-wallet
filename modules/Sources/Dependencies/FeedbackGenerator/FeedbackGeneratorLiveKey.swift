//
//  FeedbackGeneratorLiveKey.swift
//  stealth
//

import UIKit
import ComposableArchitecture

extension FeedbackGeneratorClient: DependencyKey {
    public static let liveValue = Self(
        generateSuccessFeedback: { UINotificationFeedbackGenerator().notificationOccurred(.success) },
        generateWarningFeedback: { UINotificationFeedbackGenerator().notificationOccurred(.warning) },
        generateErrorFeedback: { UINotificationFeedbackGenerator().notificationOccurred(.error) }
    )
}
