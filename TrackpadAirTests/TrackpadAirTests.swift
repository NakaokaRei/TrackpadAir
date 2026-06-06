//
//  TrackpadAirTests.swift
//  TrackpadAirTests
//
//  Created by NakaokaRei on 2024/06/29.
//

import Testing
import Foundation
@testable import TrackpadAir

struct TrackpadAirTests {

    @Test(arguments: HandGestureState.assignableGestures)
    func handposeGesture(expectedState: HandGestureState) {
        #expect(
            HandGestureProcessor.classify(frame: makeFrame(for: expectedState)) == expectedState
        )
    }

    @Test func assignableGesturesExcludeNone() {
        #expect(!HandGestureState.assignableGestures.contains(.none))
        #expect(HandGestureState.assignableGestures.map(\.rawValue) == [
            "indexPinch",
            "middlePinch",
            "ringPinch",
            "littlePinch",
            "indexMiddlePinch",
            "middleRingPinch",
            "ringLittlePinch",
            "threeFingerPinch"
        ])
    }

    @Test func threeFingerPinchHasPriorityOverSinglePinches() {
        let frame = makeFrame(for: .threeFingerPinch)

        #expect(HandGestureProcessor.classify(frame: frame) == .threeFingerPinch)
    }

    @Test func gestureRecognitionIsIndependentOfDisplayedHandSize() {
        let smallFrame = makeFrame(for: .indexPinch, scale: 50)
        let largeFrame = makeFrame(for: .indexPinch, scale: 200)

        #expect(HandGestureProcessor.classify(frame: smallFrame) == .indexPinch)
        #expect(HandGestureProcessor.classify(frame: largeFrame) == .indexPinch)
    }

    @Test func gestureRequiresTwoConsecutiveFrames() {
        let processor = HandGestureProcessor()
        let frame = makeFrame(for: .indexPinch)

        #expect(processor.process(frame: frame).gesture == .none)
        let confirmed = processor.process(frame: frame)
        #expect(confirmed.gesture == .indexPinch)
        #expect(confirmed.didTransition)
    }

    @Test func singleFrameNoiseDoesNotReleaseGesture() {
        let processor = HandGestureProcessor()
        let pinchFrame = makeFrame(for: .indexPinch)
        _ = processor.process(frame: pinchFrame)
        _ = processor.process(frame: pinchFrame)

        let noisyFrame = makeFrame(
            fingerTips: FingerTips(
                thumb: .zero,
                index: CGPoint(x: 80, y: 0),
                middle: CGPoint(x: 200, y: 0),
                ring: CGPoint(x: 300, y: 0),
                little: CGPoint(x: 400, y: 0)
            )
        )

        #expect(processor.process(frame: noisyFrame).gesture == .indexPinch)
    }

    @Test func releaseThresholdPreventsBoundaryFlicker() {
        let processor = HandGestureProcessor()
        let pinchFrame = makeFrame(for: .indexPinch)
        _ = processor.process(frame: pinchFrame)
        _ = processor.process(frame: pinchFrame)

        let boundaryFrame = makeFrame(
            fingerTips: FingerTips(
                thumb: .zero,
                index: CGPoint(x: 40, y: 0),
                middle: CGPoint(x: 200, y: 0),
                ring: CGPoint(x: 300, y: 0),
                little: CGPoint(x: 400, y: 0)
            )
        )

        #expect(processor.process(frame: boundaryFrame).gesture == .indexPinch)
        #expect(processor.process(frame: boundaryFrame).gesture == .indexPinch)
    }

    @Test func twoMissingFramesResetGestureAndCoordinates() {
        let processor = HandGestureProcessor()
        let pinchFrame = makeFrame(for: .indexPinch)
        _ = processor.process(frame: pinchFrame)
        _ = processor.process(frame: pinchFrame)

        let firstMiss = processor.process(frame: nil)
        #expect(firstMiss.gesture == .indexPinch)
        #expect(firstMiss.fingerTips != nil)

        let secondMiss = processor.process(frame: nil)
        #expect(secondMiss.gesture == .none)
        #expect(secondMiss.fingerTips == nil)
        #expect(secondMiss.didTransition)
    }

    @Test func pointerMovementCompensatesForMirroredPreview() {
        let executor = GestureActionExecutor()

        let movement = executor.pointerMovement(
            from: CGPoint(x: 100, y: 100),
            to: CGPoint(x: 90, y: 100)
        )

        #expect(movement.x > 0)
        #expect(movement.y == 0)
    }

    @MainActor
    @Test func gestureActionSettingsUseDefaults() {
        let setting = Setting(userDefaults: makeUserDefaults())

        #expect(setting.action(for: .indexPinch) == .moveMouse)
        #expect(setting.action(for: .middlePinch) == .leftClick)
        #expect(setting.action(for: .indexMiddlePinch) == .scroll)
        #expect(setting.action(for: .ringPinch) == nil)
    }

    @MainActor
    @Test func gestureActionSettingsPersistAssignments() {
        let userDefaults = makeUserDefaults()
        let setting = Setting(userDefaults: userDefaults)

        setting.setAction(.scroll, for: .ringPinch)
        setting.setAction(nil, for: .indexPinch)

        let restoredSetting = Setting(userDefaults: userDefaults)
        #expect(restoredSetting.action(for: .ringPinch) == .scroll)
        #expect(restoredSetting.action(for: .indexPinch) == nil)
    }

    @MainActor
    @Test func gestureActionSettingsIgnoreInvalidValues() {
        let userDefaults = makeUserDefaults()
        userDefaults.set(
            [
                "indexPinch": "not_an_event",
                "not_a_gesture": Event.scroll.id,
                "ringPinch": Event.leftClick.id
            ],
            forKey: "gestureActionAssignments"
        )

        let setting = Setting(userDefaults: userDefaults)

        #expect(setting.action(for: .indexPinch) == .moveMouse)
        #expect(setting.action(for: .ringPinch) == .leftClick)
    }

    @MainActor
    @Test func customCommandsPersistAndCanBeAssigned() {
        let userDefaults = makeUserDefaults()
        let setting = Setting(userDefaults: userDefaults)
        var command = setting.addCommand()
        command.displayName = "Open Search"
        command.steps = [
            CommandStep(kind: .shortcut, value: "command+space"),
            CommandStep(kind: .typeText, value: "TrackpadAir")
        ]
        setting.updateCommand(command)
        setting.setAction(command, for: .threeFingerPinch)

        let restoredSetting = Setting(userDefaults: userDefaults)

        #expect(restoredSetting.customCommands == [command])
        #expect(restoredSetting.action(for: .threeFingerPinch) == command)
    }

    @MainActor
    @Test func deletingCommandClearsItsAssignments() {
        let setting = Setting(userDefaults: makeUserDefaults())
        let command = setting.addCommand()
        setting.setAction(command, for: .ringPinch)

        setting.deleteCommands(at: IndexSet(integer: 0))

        #expect(setting.action(for: .ringPinch) == nil)
    }

    @MainActor
    @Test func viewModelResolvesConfiguredAction() async {
        let setting = Setting(userDefaults: makeUserDefaults())
        setting.setAction(.leftClick, for: .ringPinch)
        let executor = RecordingGestureActionExecutor()
        let viewModel = HandGestureViewModel(
            setting: setting,
            actionExecutor: executor
        )
        let frame = makeFrame(for: .ringPinch)

        await viewModel.process(frame: frame)
        await viewModel.process(frame: frame)

        #expect(viewModel.recognizedGesture == .ringPinch)
        #expect(viewModel.event == .leftClick)
        #expect(executor.executedActions == [.leftClick])
    }

    @MainActor
    @Test func sequenceActionDoesNotRepeatWhileGestureIsHeld() async {
        let setting = Setting(userDefaults: makeUserDefaults())
        setting.setAction(.leftClick, for: .ringPinch)
        let executor = RecordingGestureActionExecutor()
        let viewModel = HandGestureViewModel(
            setting: setting,
            actionExecutor: executor
        )
        let frame = makeFrame(for: .ringPinch)

        await viewModel.process(frame: frame)
        await viewModel.process(frame: frame)
        await viewModel.process(frame: frame)
        await viewModel.process(frame: frame)

        #expect(executor.executedActions == [.leftClick])
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "TrackpadAirTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }

    private func makeFrame(
        for gesture: HandGestureState,
        scale: CGFloat = 100
    ) -> HandPoseFrame {
        let points: FingerTips
        switch gesture {
        case .indexPinch:
            points = FingerTips(
                thumb: .zero,
                index: CGPoint(x: 20, y: 0),
                middle: CGPoint(x: 200, y: 0),
                ring: CGPoint(x: 300, y: 0),
                little: CGPoint(x: 400, y: 0)
            )
        case .middlePinch:
            points = FingerTips(
                thumb: .zero,
                index: CGPoint(x: 100, y: 0),
                middle: CGPoint(x: 20, y: 0),
                ring: CGPoint(x: 300, y: 0),
                little: CGPoint(x: 400, y: 0)
            )
        case .ringPinch:
            points = FingerTips(
                thumb: .zero,
                index: CGPoint(x: 100, y: 0),
                middle: CGPoint(x: 200, y: 0),
                ring: CGPoint(x: 20, y: 0),
                little: CGPoint(x: 400, y: 0)
            )
        case .littlePinch:
            points = FingerTips(
                thumb: .zero,
                index: CGPoint(x: 100, y: 0),
                middle: CGPoint(x: 200, y: 0),
                ring: CGPoint(x: 300, y: 0),
                little: CGPoint(x: 20, y: 0)
            )
        case .indexMiddlePinch:
            points = FingerTips(
                thumb: CGPoint(x: -100, y: 0),
                index: .zero,
                middle: CGPoint(x: 20, y: 0),
                ring: CGPoint(x: 200, y: 0),
                little: CGPoint(x: 300, y: 0)
            )
        case .middleRingPinch:
            points = FingerTips(
                thumb: CGPoint(x: -100, y: 0),
                index: CGPoint(x: 100, y: 0),
                middle: .zero,
                ring: CGPoint(x: 20, y: 0),
                little: CGPoint(x: 200, y: 0)
            )
        case .ringLittlePinch:
            points = FingerTips(
                thumb: CGPoint(x: -100, y: 0),
                index: CGPoint(x: 100, y: 0),
                middle: CGPoint(x: 200, y: 0),
                ring: .zero,
                little: CGPoint(x: 20, y: 0)
            )
        case .threeFingerPinch:
            points = FingerTips(
                thumb: .zero,
                index: CGPoint(x: 20, y: 0),
                middle: CGPoint(x: 0, y: 20),
                ring: CGPoint(x: 200, y: 0),
                little: CGPoint(x: 300, y: 0)
            )
        case .none:
            points = FingerTips(
                thumb: .zero,
                index: CGPoint(x: 100, y: 0),
                middle: CGPoint(x: 200, y: 0),
                ring: CGPoint(x: 300, y: 0),
                little: CGPoint(x: 400, y: 0)
            )
        }

        let ratio = scale / 100
        return makeFrame(
            fingerTips: FingerTips(
                thumb: scaled(points.thumb, by: ratio),
                index: scaled(points.index, by: ratio),
                middle: scaled(points.middle, by: ratio),
                ring: scaled(points.ring, by: ratio),
                little: scaled(points.little, by: ratio)
            ),
            scale: scale
        )
    }

    private func makeFrame(
        fingerTips: FingerTips,
        scale: CGFloat = 100
    ) -> HandPoseFrame {
        HandPoseFrame(
            fingerTips: fingerTips,
            handScale: scale,
            confidence: 1
        )
    }

    private func scaled(_ point: CGPoint, by ratio: CGFloat) -> CGPoint {
        CGPoint(x: point.x * ratio, y: point.y * ratio)
    }
}

@MainActor
private final class RecordingGestureActionExecutor: GestureActionExecuting {
    private(set) var executedActions: [Event] = []

    func execute(
        action: Event,
        fingerTips: FingerTips?,
        previousFingerTips: FingerTips?
    ) async -> Event? {
        executedActions.append(action)
        return action
    }
}
