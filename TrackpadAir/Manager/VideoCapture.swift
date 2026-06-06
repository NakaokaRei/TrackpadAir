//
//  VideoCapture.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/18.
//

import Foundation
import AVFoundation

class VideoCapture: NSObject {
    let captureSession = AVCaptureSession()
    var handler: ((CMSampleBuffer) -> Void)?

    public override init() {
        super.init()
        setup()
    }

    func setup() {
        captureSession.beginConfiguration()
        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let deviceInput = try? AVCaptureDeviceInput(device: device),
            captureSession.canAddInput(deviceInput)
        else {
            captureSession.commitConfiguration()
            return
        }
        captureSession.addInput(deviceInput)

        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "mydispatchqueue"))
        videoDataOutput.alwaysDiscardsLateVideoFrames = true

        guard captureSession.canAddOutput(videoDataOutput) else {
            captureSession.commitConfiguration()
            return
        }
        captureSession.addOutput(videoDataOutput)
        captureSession.commitConfiguration()
    }

    public func run(_ handler: @escaping (CMSampleBuffer) -> Void)  {
        if !captureSession.isRunning {
            self.handler = handler
            captureSession.startRunning()
        }
    }

    public func stop() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
}

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let handler = handler {
            handler(sampleBuffer)
        }
    }
}
