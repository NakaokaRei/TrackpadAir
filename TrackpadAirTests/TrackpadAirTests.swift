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

    @Test(arguments: [
        (FingerTips(thumb: .zero, index: .zero, middle: .zero, ring: .zero, little: .zero), HandGestureState.indexPinch),
        (FingerTips(thumb: .zero, index: .init(x: 10, y: 10), middle: .zero, ring: .init(x: 10, y: 10), little: .init(x: 10, y: 10)), HandGestureState.middlePinch),
        (FingerTips(thumb: .zero, index: .init(x: 20, y: 0), middle: .init(x: 40, y: 0), ring: .init(x: 1, y: 1), little: .init(x: 60, y: 0)), HandGestureState.ringPinch),
        (FingerTips(thumb: .zero, index: .init(x: 20, y: 0), middle: .init(x: 40, y: 0), ring: .init(x: 60, y: 0), little: .init(x: 1, y: 1)), HandGestureState.littlePinch),
        (FingerTips(thumb: .init(x: 40, y: 0), index: .zero, middle: .init(x: 1, y: 1), ring: .init(x: 80, y: 0), little: .init(x: 120, y: 0)), HandGestureState.indexMiddlePinch),
        (FingerTips(thumb: .init(x: 40, y: 0), index: .init(x: 80, y: 0), middle: .zero, ring: .init(x: 1, y: 1), little: .init(x: 120, y: 0)), HandGestureState.middleRingPinch),
        (FingerTips(thumb: .init(x: 40, y: 0), index: .init(x: 80, y: 0), middle: .init(x: 120, y: 0), ring: .zero, little: .init(x: 1, y: 1)), HandGestureState.ringLittlePinch),
        (FingerTips(thumb: .zero, index: .init(x: 1, y: 0), middle: .init(x: 0, y: 1), ring: .init(x: 40, y: 0), little: .init(x: 80, y: 0)), HandGestureState.threeFingerPinch),
    ]) func handposeGesture(fingerTips: FingerTips, expectedState: HandGestureState) {
        let event = HandGestureProcessor.process(fingerTips: fingerTips)
        #expect(event == expectedState)
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
        let fingerTips = FingerTips(
            thumb: .zero,
            index: .init(x: 1, y: 0),
            middle: .init(x: 0, y: 1),
            ring: .init(x: 40, y: 0),
            little: .init(x: 80, y: 0)
        )

        #expect(HandGestureProcessor.process(fingerTips: fingerTips) == .threeFingerPinch)
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
        let viewModel = HandGestureViewModel(
            setting: setting,
            actionExecutor: FakeGestureActionExecutor()
        )
        viewModel.fingerTips = FingerTips(
            thumb: .zero,
            index: .init(x: 20, y: 0),
            middle: .init(x: 40, y: 0),
            ring: .init(x: 1, y: 1),
            little: .init(x: 60, y: 0)
        )

        await viewModel.operate()

        #expect(viewModel.recognizedGesture == .ringPinch)
        #expect(viewModel.event == .leftClick)
    }

    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "TrackpadAirTests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }
}

private struct FakeGestureActionExecutor: GestureActionExecuting {
    func execute(
        action: Event,
        fingerTips: FingerTips?,
        previousFingerTips: FingerTips?
    ) async -> Event? {
        action
    }
}
