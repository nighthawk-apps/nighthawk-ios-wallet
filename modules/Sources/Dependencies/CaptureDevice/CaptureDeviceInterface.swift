//
//  CaptureDeviceInterface.swift
//  stealth
//

import ComposableArchitecture

extension DependencyValues {
    public var captureDevice: CaptureDeviceClient {
        get { self[CaptureDeviceClient.self] }
        set { self[CaptureDeviceClient.self] = newValue }
    }
}

public struct CaptureDeviceClient {
    public enum CaptureDeviceClientError: Error {
        case captureDeviceFailed
        case lockForConfigurationFailed
        case torchUnavailable
    }

    public let isTorchAvailable: () throws -> Bool
    public let torch: (Bool) throws -> Void
}
