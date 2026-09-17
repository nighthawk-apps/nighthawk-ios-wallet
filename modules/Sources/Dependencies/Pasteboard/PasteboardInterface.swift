//
//  PasteboardInterface.swift
//  stealth
//

import ComposableArchitecture
import Utils

extension DependencyValues {
    public var pasteboard: PasteboardClient {
        get { self[PasteboardClient.self] }
        set { self[PasteboardClient.self] = newValue }
    }
}

public struct PasteboardClient {
    public let setString: (RedactableString) -> Void
    public let getString: () -> RedactableString?
}
