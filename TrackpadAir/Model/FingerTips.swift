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
