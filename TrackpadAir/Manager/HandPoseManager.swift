//
//  HandPoseManager.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/18.
//

import Foundation
import Cocoa
import OSLog
@preconcurrency import AVFoundation
@preconcurrency import Vision

struct HandPoseProcessingResult {
    let image: NSImage?
    let frame: HandPoseFrame?
}

final class HandPoseManager: @unchecked Sendable {
    private final class SampleBufferBox: @unchecked Sendable {
        let value: CMSampleBuffer

        init(_ value: CMSampleBuffer) {
            self.value = value
        }
    }

    private struct PendingWork {
        let sampleBuffer: CMSampleBuffer
        let completion: @MainActor (HandPoseProcessingResult) -> Void
    }

    private let queue = DispatchQueue(label: "com.trackpadair.hand-pose", qos: .userInitiated)
    private let lock = NSLock()
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.TrackpadAir",
        category: "HandPose"
    )
    private let handPoseRequest: VNDetectHumanHandPoseRequest

    private var isProcessing = false
    private var pendingWork: PendingWork?
    private var droppedFrameCount = 0

    init() {
        handPoseRequest = VNDetectHumanHandPoseRequest()
        handPoseRequest.maximumHandCount = 1
    }

    func submit(
        _ sampleBuffer: CMSampleBuffer,
        completion: @escaping @MainActor (HandPoseProcessingResult) -> Void
    ) {
        lock.lock()
        if isProcessing {
            if pendingWork != nil {
                droppedFrameCount += 1
            }
            pendingWork = PendingWork(
                sampleBuffer: sampleBuffer,
                completion: completion
            )
            let droppedFrames = droppedFrameCount
            lock.unlock()

            if droppedFrames > 0, droppedFrames.isMultiple(of: 30) {
                logger.debug("Dropped \(droppedFrames, privacy: .public) stale frames")
            }
            return
        }
        isProcessing = true
        lock.unlock()

        process(sampleBuffer, completion: completion)
    }

    func reset() {
        lock.lock()
        pendingWork = nil
        droppedFrameCount = 0
        lock.unlock()
    }

    private func process(
        _ sampleBuffer: CMSampleBuffer,
        completion: @escaping @MainActor (HandPoseProcessingResult) -> Void
    ) {
        let sampleBufferBox = SampleBufferBox(sampleBuffer)
        queue.async { [self] in
            let sampleBuffer = sampleBufferBox.value
            let startedAt = ContinuousClock.now
            let image = NSImageFromSampleBuffer(sampleBuffer)
            let frame: HandPoseFrame?
            do {
                frame = try recognize(sampleBuffer)
            } catch {
                logger.error("Hand-pose recognition failed: \(error.localizedDescription, privacy: .public)")
                frame = nil
            }

            let elapsed = startedAt.duration(to: .now)
            logger.debug("Processed hand-pose frame in \(elapsed, privacy: .public)")
            Task { @MainActor in
                completion(HandPoseProcessingResult(image: image, frame: frame))
            }

            lock.lock()
            let nextWork = pendingWork
            pendingWork = nil
            if nextWork == nil {
                isProcessing = false
            }
            lock.unlock()

            if let nextWork {
                process(
                    nextWork.sampleBuffer,
                    completion: nextWork.completion
                )
            }
        }
    }

    private func recognize(_ sampleBuffer: CMSampleBuffer) throws -> HandPoseFrame? {
        let handler = VNImageRequestHandler(
            cmSampleBuffer: sampleBuffer,
            orientation: .up,
            options: [:]
        )
        try handler.perform([handPoseRequest])

        guard let observation = handPoseRequest.results?.first else {
            return nil
        }

        let allPoints = try observation.recognizedPoints(.all)

        guard let thumbTipPoint = allPoints[.thumbTip],
              let indexTipPoint = allPoints[.indexTip],
              let middleTipPoint = allPoints[.middleTip],
              let ringTipPoint = allPoints[.ringTip],
              let littleTipPoint = allPoints[.littleTip],
              let wristPoint = allPoints[.wrist],
              let middleMCPPoint = allPoints[.middleMCP] else {
            return nil
        }

        let points = [
            thumbTipPoint,
            indexTipPoint,
            middleTipPoint,
            ringTipPoint,
            littleTipPoint,
            wristPoint,
            middleMCPPoint
        ]
        let confidence = points.map(\.confidence).min() ?? 0
        guard confidence > 0.3 else {
            return nil
        }

        let wrist = flipped(wristPoint.location)
        let middleMCP = flipped(middleMCPPoint.location)
        let imageSize = imageSize(of: sampleBuffer)
        let aspectRatio = imageSize.width / imageSize.height
        let handScale = aspectCorrectedDistance(
            from: wrist,
            to: middleMCP,
            aspectRatio: aspectRatio
        )
        guard handScale > 0.01 else {
            return nil
        }

        return HandPoseFrame(
            fingerTips: FingerTips(
                thumb: flipped(thumbTipPoint.location),
                index: flipped(indexTipPoint.location),
                middle: flipped(middleTipPoint.location),
                ring: flipped(ringTipPoint.location),
                little: flipped(littleTipPoint.location)
            ),
            handScale: handScale,
            confidence: confidence,
            aspectRatio: aspectRatio
        )
    }

    private func flipped(_ point: CGPoint) -> CGPoint {
        CGPoint(x: point.x, y: 1 - point.y)
    }

    private func imageSize(of sampleBuffer: CMSampleBuffer) -> CGSize {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return CGSize(width: 16, height: 9)
        }
        return CGSize(
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer)
        )
    }

    private func aspectCorrectedDistance(
        from p1: CGPoint,
        to p2: CGPoint,
        aspectRatio: CGFloat
    ) -> CGFloat {
        hypot((p1.x - p2.x) * aspectRatio, p1.y - p2.y)
    }
}
