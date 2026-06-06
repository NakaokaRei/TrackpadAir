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

struct HandGestureUpdate {
    let gesture: HandGestureState
    let fingerTips: FingerTips?
    let didTransition: Bool
}

final class HandGestureProcessor {
    struct Configuration {
        let smoothingAlpha: CGFloat
        let activationThreshold: CGFloat
        let releaseThreshold: CGFloat
        let confirmationFrames: Int
        let missingFramesBeforeReset: Int

        static let balanced = Configuration(
            smoothingAlpha: 0.55,
            activationThreshold: 0.34,
            releaseThreshold: 0.46,
            confirmationFrames: 2,
            missingFramesBeforeReset: 2
        )
    }

    private let configuration: Configuration
    private var filteredFrame: HandPoseFrame?
    private var stableGesture: HandGestureState = .none
    private var candidateGesture: HandGestureState?
    private var candidateFrameCount = 0
    private var missingFrameCount = 0

    init(configuration: Configuration = .balanced) {
        self.configuration = configuration
    }

    func process(frame: HandPoseFrame?) -> HandGestureUpdate {
        guard let frame else {
            return processMissingFrame()
        }

        missingFrameCount = 0
        let smoothedFrame = smooth(frame)
        filteredFrame = smoothedFrame

        let detectedGesture: HandGestureState
        if stableGesture != .none,
           Self.matches(
               stableGesture,
               frame: smoothedFrame,
               threshold: configuration.releaseThreshold
           ) {
            detectedGesture = stableGesture
        } else {
            detectedGesture = Self.classify(
                frame: smoothedFrame,
                threshold: configuration.activationThreshold
            )
        }

        let didTransition = confirm(detectedGesture)
        return HandGestureUpdate(
            gesture: stableGesture,
            fingerTips: smoothedFrame.fingerTips,
            didTransition: didTransition
        )
    }

    func reset() {
        filteredFrame = nil
        stableGesture = .none
        candidateGesture = nil
        candidateFrameCount = 0
        missingFrameCount = 0
    }

    static func classify(
        frame: HandPoseFrame,
        threshold: CGFloat = Configuration.balanced.activationThreshold
    ) -> HandGestureState {
        for definition in GestureDefinition.priorityOrdered {
            if definition.matches(frame: frame, threshold: threshold) {
                return definition.state
            }
        }
        return .none
    }

    private static func matches(
        _ gesture: HandGestureState,
        frame: HandPoseFrame,
        threshold: CGFloat
    ) -> Bool {
        guard let definition = GestureDefinition.priorityOrdered.first(where: {
            $0.state == gesture
        }) else {
            return false
        }
        return definition.matches(frame: frame, threshold: threshold)
    }

    private func processMissingFrame() -> HandGestureUpdate {
        missingFrameCount += 1
        guard missingFrameCount >= configuration.missingFramesBeforeReset else {
            return HandGestureUpdate(
                gesture: stableGesture,
                fingerTips: filteredFrame?.fingerTips,
                didTransition: false
            )
        }

        let didTransition = stableGesture != .none
        filteredFrame = nil
        stableGesture = .none
        candidateGesture = nil
        candidateFrameCount = 0
        return HandGestureUpdate(
            gesture: .none,
            fingerTips: nil,
            didTransition: didTransition
        )
    }

    private func confirm(_ detectedGesture: HandGestureState) -> Bool {
        guard detectedGesture != stableGesture else {
            candidateGesture = nil
            candidateFrameCount = 0
            return false
        }

        if candidateGesture == detectedGesture {
            candidateFrameCount += 1
        } else {
            candidateGesture = detectedGesture
            candidateFrameCount = 1
        }

        guard candidateFrameCount >= configuration.confirmationFrames else {
            return false
        }

        stableGesture = detectedGesture
        candidateGesture = nil
        candidateFrameCount = 0
        return true
    }

    private func smooth(_ frame: HandPoseFrame) -> HandPoseFrame {
        guard let previous = filteredFrame else {
            return frame
        }

        return HandPoseFrame(
            fingerTips: FingerTips(
                thumb: smooth(previous.fingerTips.thumb, frame.fingerTips.thumb),
                index: smooth(previous.fingerTips.index, frame.fingerTips.index),
                middle: smooth(previous.fingerTips.middle, frame.fingerTips.middle),
                ring: smooth(previous.fingerTips.ring, frame.fingerTips.ring),
                little: smooth(previous.fingerTips.little, frame.fingerTips.little)
            ),
            handScale: interpolate(previous.handScale, frame.handScale),
            confidence: frame.confidence,
            aspectRatio: frame.aspectRatio
        )
    }

    private func smooth(_ previous: CGPoint, _ current: CGPoint) -> CGPoint {
        CGPoint(
            x: interpolate(previous.x, current.x),
            y: interpolate(previous.y, current.y)
        )
    }

    private func interpolate(_ previous: CGFloat, _ current: CGFloat) -> CGFloat {
        previous + configuration.smoothingAlpha * (current - previous)
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

    func matches(frame: HandPoseFrame, threshold: CGFloat) -> Bool {
        let distanceThreshold = frame.handScale * threshold
        let requiredPairsMatch = requiredPairs.allSatisfy {
            distance(
                fingerTips: frame.fingerTips,
                pair: $0,
                aspectRatio: frame.aspectRatio
            ) < distanceThreshold
        }
        let excludedPairsMatch = excludedPairs.allSatisfy {
            distance(
                fingerTips: frame.fingerTips,
                pair: $0,
                aspectRatio: frame.aspectRatio
            ) >= distanceThreshold
        }

        return requiredPairsMatch && excludedPairsMatch
    }

    private func distance(
        fingerTips: FingerTips,
        pair: (FingerTipKeyPath, FingerTipKeyPath),
        aspectRatio: CGFloat
    ) -> Double {
        let p1 = pair.0.point(in: fingerTips)
        let p2 = pair.1.point(in: fingerTips)
        let dx = (p1.x - p2.x) * aspectRatio
        let dy = p1.y - p2.y
        return hypot(dx, dy)
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
