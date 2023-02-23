//
//  FingerTipsView.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/18.
//

import SwiftUI

struct FingerTipsView: View {

    let fingerTips: FingerTips
    let pointSize: CGFloat = 7

    var body: some View {
        Group {
            Circle()
                .fill(.blue)
                .frame(width: pointSize, height: pointSize)
                .position(fingerTips.thumb)
            Circle()
                .fill(.blue)
                .frame(width: pointSize, height: pointSize)
                .position(fingerTips.index)
            Circle()
                .fill(.blue)
                .frame(width: pointSize, height: pointSize)
                .position(fingerTips.middle)
            Circle()
                .fill(.blue)
                .frame(width: pointSize, height: pointSize)
                .position(fingerTips.ring)
            Circle()
                .fill(.blue)
                .frame(width: pointSize, height: pointSize)
                .position(fingerTips.little)
        }
    }
}
