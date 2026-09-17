//
//  CaptureDeviceTestKey.swift
//  stealth
//

import ComposableArchitecture
import XCTestDynamicOverlay

extension CaptureDeviceClient: TestDependencyKey {
    public static let testValue = Self(
        isTorchAvailable: unimplemented("\(Self.self).isTorchAvailable", placeholder: false),
        torch: unimplemented("\(Self.self).torch")
    )
}

extension CaptureDeviceClient {
    public static let noOp = Self(
        isTorchAvailable: { false },
        torch: { _ in }
    )
}
