//
//  ScanUIView.swift
//  stealth
//
//  Created by Lukáš Korba on 16.05.2022.
//

import AVFoundation
import UIKit

public class ScanUIView: UIView {
    private var captureSession: AVCaptureSession?
    private var metadataOutput: AVCaptureMetadataOutput?
    private var isConfigured = false
    private var isConfiguring = false
    private var hasDeliveredCode = false

    var onQRScanningDidFail: (() -> Void)?
    var onQRScanningSucceededWithCode: ((String) -> Void)?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    deinit {
        captureSession?.stopRunning()
    }

    override public class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    override public var layer: AVCaptureVideoPreviewLayer {
        super.layer as! AVCaptureVideoPreviewLayer
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        updateRectOfInterest()
    }

    override public func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)

        if newWindow == nil {
            captureSession?.stopRunning()
        } else {
            configureIfNeeded()
        }
    }
}

// MARK: - Camera setup
private extension ScanUIView {
    func configureIfNeeded() {
        guard !isConfigured, !isConfiguring else { return }
        isConfiguring = true

        clipsToBounds = true
        layer.videoGravity = .resizeAspectFill

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if granted {
                        self.setupCaptureSession()
                    } else {
                        self.isConfiguring = false
                        self.scanningDidFail()
                    }
                }
            }
        default:
            isConfiguring = false
            scanningDidFail()
        }
    }

    func setupCaptureSession() {
        defer { isConfiguring = false }

        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let videoCaptureDevice = preferredCameraDevice() else {
            session.commitConfiguration()
            scanningDidFail()
            return
        }

        let videoInput: AVCaptureDeviceInput
        do {
            try videoCaptureDevice.lockForConfiguration()
            if videoCaptureDevice.isFocusModeSupported(.continuousAutoFocus) {
                videoCaptureDevice.focusMode = .continuousAutoFocus
            }
            videoCaptureDevice.unlockForConfiguration()

            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            session.commitConfiguration()
            scanningDidFail()
            return
        }

        guard session.canAddInput(videoInput) else {
            session.commitConfiguration()
            scanningDidFail()
            return
        }
        session.addInput(videoInput)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            scanningDidFail()
            return
        }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [.qr]

        session.commitConfiguration()

        captureSession = session
        metadataOutput = output
        layer.session = session
        isConfigured = true
        updateRectOfInterest()
        startSessionIfNeeded()
    }

    func preferredCameraDevice() -> AVCaptureDevice? {
        if let triple = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) {
            return triple
        }
        if let dual = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
            return dual
        }
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            ?? AVCaptureDevice.default(for: .video)
    }

    func startSessionIfNeeded() {
        guard let captureSession, !captureSession.isRunning else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self, weak captureSession] in
            captureSession?.startRunning()
            DispatchQueue.main.async {
                self?.updateRectOfInterest()
            }
        }
    }

    func updateRectOfInterest() {
        guard
            let metadataOutput,
            let captureSession,
            captureSession.isRunning || isConfigured,
            bounds.width > 0,
            bounds.height > 0
        else { return }

        let converted = layer.metadataOutputRectConverted(fromLayerRect: bounds)
        guard converted.origin.x.isFinite,
              converted.origin.y.isFinite,
              converted.size.width.isFinite,
              converted.size.height.isFinite,
              converted.width > 0,
              converted.height > 0
        else { return }

        metadataOutput.rectOfInterest = converted
    }

    func scanningDidFail() {
        onQRScanningDidFail?()
        captureSession?.stopRunning()
        captureSession = nil
        metadataOutput = nil
        isConfigured = false
    }

    func found(code: String) {
        guard !hasDeliveredCode else { return }
        hasDeliveredCode = true
        captureSession?.stopRunning()
        onQRScanningSucceededWithCode?(code)
    }
}

extension ScanUIView: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard
            let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            let stringValue = metadataObject.stringValue
        else { return }

        found(code: stringValue)
    }
}
