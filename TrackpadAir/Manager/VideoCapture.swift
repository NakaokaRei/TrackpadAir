//
//  VideoCapture.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/18.
//

import Foundation
import AVFoundation

public class VideoCapture: NSObject {
    let captureSession = AVCaptureSession()
    var handler: ((CMSampleBuffer) -> Void)?

    public override init() {
        super.init()
        setup()
    }

    func setup() {
        captureSession.beginConfiguration()
        let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        guard
            let deviceInput = try? AVCaptureDeviceInput(device: device!),
            captureSession.canAddInput(deviceInput)
            else { return }
        captureSession.addInput(deviceInput)

        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "mydispatchqueue"))
        videoDataOutput.alwaysDiscardsLateVideoFrames = true

        guard captureSession.canAddOutput(videoDataOutput) else { return }
        captureSession.addOutput(videoDataOutput)

        // アウトプットの画像を縦向きに変更（標準は横）
        for connection in videoDataOutput.connections {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .landscapeLeft
            }
        }
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

