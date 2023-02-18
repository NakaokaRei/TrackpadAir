//
//  FingerTips.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/18.
//

import Foundation

public struct FingerTips {

    public let thumb: CGPoint
    public let index: CGPoint
    public let middle: CGPoint
    public let ring: CGPoint
    public let little: CGPoint

    public init(
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
