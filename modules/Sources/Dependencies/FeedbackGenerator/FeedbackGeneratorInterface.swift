//
//  FeedbackGeneratorInterface.swift
//  stealth
//

import ComposableArchitecture

extension DependencyValues {
    public var feedbackGenerator: FeedbackGeneratorClient {
        get { self[FeedbackGeneratorClient.self] }
        set { self[FeedbackGeneratorClient.self] = newValue }
    }
}

public struct FeedbackGeneratorClient {
    public let generateSuccessFeedback: () -> Void
    public let generateWarningFeedback: () -> Void
    public let generateErrorFeedback: () -> Void
}
