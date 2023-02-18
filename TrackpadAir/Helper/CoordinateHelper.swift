//
//  CoordinateHelper.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/18.
//

import Foundation

class CoordinateHelper {
    static func transform(point: CGPoint, width: CGFloat, height: CGFloat) -> CGPoint {
        return .init(x: point.x * width, y: point.y * height)
    }

    static func transform(fingerTips: FingerTips, width: CGFloat, height: CGFloat) -> FingerTips {
        let newTips: FingerTips = .init(
            thumb: transform(point: fingerTips.thumb, width: width, height: height),
            index: transform(point: fingerTips.index, width: width, height: height),
            middle: transform(point: fingerTips.middle, width: width, height: height),
            ring: transform(point: fingerTips.ring, width: width, height: height),
            little: transform(point: fingerTips.little, width: width, height: height)
        )

        return newTips
    }

    static func distance(p1: CGPoint, p2: CGPoint) -> Double {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return sqrt(dx*dx + dy*dy)
    }
 }
