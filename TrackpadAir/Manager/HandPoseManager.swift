//
//  HandPoseManager.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/18.
//

import Foundation
import Vision

class HandPoseManager {
    private var handPoseResquest = VNDetectHumanHandPoseRequest()

    public init() {
        setup()
    }

    func setup() {
        handPoseResquest.maximumHandCount = 1
    }

    func recognize(_ sampleBuffer: CMSampleBuffer) async throws -> FingerTips? {

        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        try handler.perform([handPoseResquest])

        guard let observation = handPoseResquest.results?.first else {
            return nil
        }

        let thumbPoints = try observation.recognizedPoints(.thumb)
        let indexFingerPoints = try observation.recognizedPoints(.indexFinger)
        let middleFingerPoints = try observation.recognizedPoints(.middleFinger)
        let ringFingerPoints = try observation.recognizedPoints(.ringFinger)
        let littleFingerPoints = try observation.recognizedPoints(.littleFinger)

        guard let thumbTipPoint = thumbPoints[.thumbTip],
              let indexTipPoint = indexFingerPoints[.indexTip],
              let middleTipPoint = middleFingerPoints[.middleTip],
              let ringTipPoint = ringFingerPoints[.ringTip],
              let littleTipPoint = littleFingerPoints[.littleTip] else {
            return nil
        }

        guard thumbTipPoint.confidence > 0.3 &&
                indexTipPoint.confidence > 0.3 &&
                middleTipPoint.confidence > 0.3 &&
                ringTipPoint.confidence > 0.3 &&
                littleTipPoint.confidence > 0.3 else {
            return nil
        }

        let fingerTips: FingerTips = .init(
            thumb: CGPoint(x: thumbTipPoint.location.x, y: (1 - thumbTipPoint.location.y)),
            index: CGPoint(x: indexTipPoint.location.x, y: (1 - indexTipPoint.location.y)),
            middle: CGPoint(x: middleTipPoint.location.x, y: (1 - middleTipPoint.location.y)),
            ring: CGPoint(x: ringTipPoint.location.x, y: (1 - ringTipPoint.location.y)),
            little: CGPoint(x: littleTipPoint.location.x, y: (1 - littleTipPoint.location.y))
        )

        return fingerTips
    }
}

