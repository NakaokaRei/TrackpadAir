//
//  VideoCapture.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/18.
//

import Foundation
@preconcurrency import AVFoundation

final class VideoCapture: NSObject, @unchecked Sendable {
    let captureSession = AVCaptureSession()
    private let captureQueue = DispatchQueue(label: "com.trackpadair.capture")
    private var handler: (@Sendable (CMSampleBuffer) -> Void)?

    public override init() {
        super.init()
        setup()
    }

    func setup() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .hd1280x720
        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .unspecified),
            let deviceInput = try? AVCaptureDeviceInput(device: device),
            captureSession.canAddInput(deviceInput)
        else {
            captureSession.commitConfiguration()
            return
        }
        captureSession.addInput(deviceInput)
        configureFrameRate(for: device)

        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoDataOutput.setSampleBufferDelegate(self, queue: captureQueue)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true

        guard captureSession.canAddOutput(videoDataOutput) else {
            captureSession.commitConfiguration()
            return
        }
        captureSession.addOutput(videoDataOutput)
        captureSession.commitConfiguration()
    }

    private func configureFrameRate(for device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }

            let targetDuration = CMTime(value: 1, timescale: 30)
            if device.activeFormat.videoSupportedFrameRateRanges.contains(where: {
                $0.minFrameRate <= 30 && $0.maxFrameRate >= 30
            }) {
                device.activeVideoMinFrameDuration = targetDuration
                device.activeVideoMaxFrameDuration = targetDuration
            }
        } catch {
            return
        }
    }

    public func run(_ handler: @escaping @Sendable (CMSampleBuffer) -> Void) {
        captureQueue.async { [self] in
            self.handler = handler
            guard !captureSession.isRunning else { return }
            captureSession.startRunning()
        }
    }

    public func stop() {
        captureQueue.async { [self] in
            handler = nil
            guard captureSession.isRunning else { return }
            captureSession.stopRunning()
        }
    }
}

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        handler?(sampleBuffer)
    }
}
