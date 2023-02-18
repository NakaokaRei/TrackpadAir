//
//  FingerTipsView.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/18.
//

import SwiftUI

struct FingerTipsView: View {

    let fingerTips: FingerTips

    var body: some View {
        Group {
            Circle()
                .fill(.blue)
                .frame(width: 5, height: 5)
                .position(fingerTips.thumb)
            Circle()
                .fill(.blue)
                .frame(width: 5, height: 5)
                .position(fingerTips.index)
            Circle()
                .fill(.blue)
                .frame(width: 5, height: 5)
                .position(fingerTips.middle)
            Circle()
                .fill(.blue)
                .frame(width: 5, height: 5)
                .position(fingerTips.ring)
            Circle()
                .fill(.blue)
                .frame(width: 5, height: 5)
                .position(fingerTips.little)
        }
    }
}
