//
//  HandGestureProcessor.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/18.
//

import Foundation

enum HandGestureState {
    case indexPinch
    case middlePinch
    case ringPinch
    case littlePinch
    case none
}

class HandGestureProcessor {

    static let threshold: Double = 6

    static func process(fingerTips: FingerTips) -> HandGestureState {
        if CoordinateHelper.distance(p1: fingerTips.thumb, p2: fingerTips.index) < threshold {
            return .indexPinch
        } else if CoordinateHelper.distance(p1: fingerTips.thumb, p2: fingerTips.middle) < threshold {
            return .middlePinch
        } else if CoordinateHelper.distance(p1: fingerTips.thumb, p2: fingerTips.ring) < threshold {
            return .ringPinch
        } else if CoordinateHelper.distance(p1: fingerTips.thumb, p2: fingerTips.little) < threshold {
            return .littlePinch
        } else {
            return .none
        }
    }
}
