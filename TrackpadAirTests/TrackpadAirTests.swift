//
//  TrackpadAirTests.swift
//  TrackpadAirTests
//
//  Created by NakaokaRei on 2024/06/29.
//

import Testing
@testable import TrackpadAir

struct TrackpadAirTests {

    @Test(arguments: [
        (FingerTips(thumb: .zero, index: .zero, middle: .zero, ring: .zero, little: .zero), HandGestureState.indexPinch),
        (FingerTips(thumb: .zero, index: .init(x: 10, y: 10), middle: .zero, ring: .init(x: 10, y: 10), little: .init(x: 10, y: 10)), HandGestureState.middlePinch),
    ]) func handposeGesture(fingerTips: FingerTips, expectedState: HandGestureState) {
        let event = HandGestureProcessor.process(fingerTips: fingerTips)
        #expect(event == expectedState)
    }

}
