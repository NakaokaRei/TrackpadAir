//
//  HandGestureProcessor.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/18.
//

import Foundation

enum HandGestureState: String, CaseIterable, Identifiable {
    case indexPinch
    case middlePinch
    case ringPinch
    case littlePinch
    case indexMiddlePinch
    case middleRingPinch
    case ringLittlePinch
    case threeFingerPinch
    case none

    var id: String {
        rawValue
    }

    static var assignableGestures: [HandGestureState] {
        [
            .indexPinch,
            .middlePinch,
            .ringPinch,
            .littlePinch,
            .indexMiddlePinch,
            .middleRingPinch,
            .ringLittlePinch,
            .threeFingerPinch
        ]
    }

    var displayName: String {
        switch self {
        case .indexPinch:
            return "Thumb + Index Pinch"
        case .middlePinch:
            return "Thumb + Middle Pinch"
        case .ringPinch:
            return "Thumb + Ring Pinch"
        case .littlePinch:
            return "Thumb + Little Pinch"
        case .indexMiddlePinch:
            return "Index + Middle Pinch"
        case .middleRingPinch:
            return "Middle + Ring Pinch"
        case .ringLittlePinch:
            return "Ring + Little Pinch"
        case .threeFingerPinch:
            return "Three Finger Pinch"
        case .none:
            return "None"
        }
    }

    var description: String {
        switch self {
        case .indexPinch:
            return "Touch the thumb and index fingertips together."
        case .middlePinch:
            return "Touch the thumb and middle fingertips together."
        case .ringPinch:
            return "Touch the thumb and ring fingertips together."
        case .littlePinch:
            return "Touch the thumb and little fingertips together."
        case .indexMiddlePinch:
            return "Touch the index and middle fingertips together."
        case .middleRingPinch:
            return "Touch the middle and ring fingertips together."
        case .ringLittlePinch:
            return "Touch the ring and little fingertips together."
        case .threeFingerPinch:
            return "Touch the thumb, index, and middle fingertips together."
        case .none:
            return "No gesture is currently recognized."
        }
    }

    var symbolName: String {
        switch self {
        case .none:
            return "hand.raised"
        default:
            return "hand.pinch"
        }
    }
}

class HandGestureProcessor {

    static let threshold: Double = 6

    static func process(fingerTips: FingerTips) -> HandGestureState {
        for definition in GestureDefinition.priorityOrdered {
            if definition.matches(fingerTips: fingerTips, threshold: threshold) {
                return definition.state
            }
        }

        return .none
    }
}

private struct GestureDefinition {
    let state: HandGestureState
    let requiredPairs: [(FingerTipKeyPath, FingerTipKeyPath)]
    let excludedPairs: [(FingerTipKeyPath, FingerTipKeyPath)]

    static let priorityOrdered: [GestureDefinition] = [
        .init(
            state: .threeFingerPinch,
            requiredPairs: [
                (FingerTipKeyPath.thumb, FingerTipKeyPath.index),
                (FingerTipKeyPath.thumb, FingerTipKeyPath.middle)
            ],
            excludedPairs: [
                (FingerTipKeyPath.thumb, FingerTipKeyPath.ring),
                (FingerTipKeyPath.thumb, FingerTipKeyPath.little)
            ]
        ),
        .init(state: .indexPinch, requiredPairs: [(FingerTipKeyPath.thumb, FingerTipKeyPath.index)]),
        .init(state: .middlePinch, requiredPairs: [(FingerTipKeyPath.thumb, FingerTipKeyPath.middle)]),
        .init(state: .ringPinch, requiredPairs: [(FingerTipKeyPath.thumb, FingerTipKeyPath.ring)]),
        .init(state: .littlePinch, requiredPairs: [(FingerTipKeyPath.thumb, FingerTipKeyPath.little)]),
        .init(state: .indexMiddlePinch, requiredPairs: [(FingerTipKeyPath.index, FingerTipKeyPath.middle)]),
        .init(state: .middleRingPinch, requiredPairs: [(FingerTipKeyPath.middle, FingerTipKeyPath.ring)]),
        .init(state: .ringLittlePinch, requiredPairs: [(FingerTipKeyPath.ring, FingerTipKeyPath.little)])
    ]

    init(
        state: HandGestureState,
        requiredPairs: [(FingerTipKeyPath, FingerTipKeyPath)],
        excludedPairs: [(FingerTipKeyPath, FingerTipKeyPath)] = []
    ) {
        self.state = state
        self.requiredPairs = requiredPairs
        self.excludedPairs = excludedPairs
    }

    func matches(fingerTips: FingerTips, threshold: Double) -> Bool {
        let requiredPairsMatch = requiredPairs.allSatisfy {
            distance(fingerTips: fingerTips, pair: $0) < threshold
        }
        let excludedPairsMatch = excludedPairs.allSatisfy {
            distance(fingerTips: fingerTips, pair: $0) >= threshold
        }

        return requiredPairsMatch && excludedPairsMatch
    }

    private func distance(
        fingerTips: FingerTips,
        pair: (FingerTipKeyPath, FingerTipKeyPath)
    ) -> Double {
        CoordinateHelper.distance(
            p1: pair.0.point(in: fingerTips),
            p2: pair.1.point(in: fingerTips)
        )
    }
}

private enum FingerTipKeyPath {
    case thumb
    case index
    case middle
    case ring
    case little

    func point(in fingerTips: FingerTips) -> CGPoint {
        switch self {
        case .thumb:
            return fingerTips.thumb
        case .index:
            return fingerTips.index
        case .middle:
            return fingerTips.middle
        case .ring:
            return fingerTips.ring
        case .little:
            return fingerTips.little
        }
    }
}
