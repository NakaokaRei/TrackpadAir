//
//  FingerTips.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/18.
//

import Foundation

struct FingerTips {

    let thumb: CGPoint
    let index: CGPoint
    let middle: CGPoint
    let ring: CGPoint
    let little: CGPoint

    init(
        thumb: CGPoint,
        index: CGPoint,
        middle: CGPoint,
        ring: CGPoint,
        little: CGPoint
    ) {
        self.thumb = thumb
        self.index = index
        self.middle = middle
        self.ring = ring
        self.little = little
    }
}

struct HandPoseFrame {
    let fingerTips: FingerTips
    let handScale: CGFloat
    let confidence: Float
    let aspectRatio: CGFloat

    init(
        fingerTips: FingerTips,
        handScale: CGFloat,
        confidence: Float,
        aspectRatio: CGFloat = 1
    ) {
        self.fingerTips = fingerTips
        self.handScale = handScale
        self.confidence = confidence
        self.aspectRatio = aspectRatio
    }

    func transformed(width: CGFloat, height: CGFloat) -> HandPoseFrame {
        HandPoseFrame(
            fingerTips: CoordinateHelper.transform(
                fingerTips: fingerTips,
                width: width,
                height: height
            ),
            handScale: handScale * min(width, height),
            confidence: confidence,
            aspectRatio: 1
        )
    }
}
