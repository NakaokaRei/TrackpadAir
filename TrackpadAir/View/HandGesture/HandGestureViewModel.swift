//
//  HandGestureViewModel.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/18.
//

import Foundation
import SwiftUI
import Combine
import SwiftAutoGUI

@MainActor
class HandGestureViewModel: ObservableObject {

    @Published var buffImage: NSImage?
    @Published var fingerTips: FingerTips?
    @Published var event: Event?
    @Published var recognizedGesture: HandGestureState = .none

    private let videoCapture = VideoCapture()
    private let handPoseManager = HandPoseManager()
    private let gestureProcessor = HandGestureProcessor()
    private let setting: Setting
    private let actionExecutor: any GestureActionExecuting
    private var captureGeneration = 0

    let imageWidth: CGFloat = 384 * 2
    let imageHeight: CGFloat = 216 * 2

    private(set) var buffTips: FingerTips?

    init(
        setting: Setting? = nil,
        actionExecutor: (any GestureActionExecuting)? = nil
    ) {
        self.setting = setting ?? Setting.shared
        self.actionExecutor = actionExecutor ?? GestureActionExecutor()
    }

    func startCapture() {
        captureGeneration += 1
        let generation = captureGeneration
        let handPoseManager = handPoseManager
        videoCapture.run { sampleBuffer in
            handPoseManager.submit(sampleBuffer) { [weak self] result in
                guard let self, self.captureGeneration == generation else { return }
                Task { @MainActor in
                    await self.consume(result)
                }
            }
        }
    }

    func stop() {
        captureGeneration += 1
        videoCapture.stop()
        handPoseManager.reset()
        gestureProcessor.reset()
        buffImage = nil
        fingerTips = nil
        buffTips = nil
        recognizedGesture = .none
        event = nil
    }

    func process(frame: HandPoseFrame?) async {
        let update = gestureProcessor.process(frame: frame)
        buffTips = fingerTips
        fingerTips = update.fingerTips
        recognizedGesture = update.gesture

        guard let action = setting.action(for: update.gesture) else {
            event = nil
            return
        }

        if action.behavior == .sequence, !update.didTransition {
            event = nil
            return
        }

        event = await actionExecutor.execute(
            action: action,
            fingerTips: fingerTips,
            previousFingerTips: buffTips
        )
    }

    private func consume(_ result: HandPoseProcessingResult) async {
        buffImage = result.image
        let transformedFrame = result.frame?.transformed(
            width: imageWidth,
            height: imageHeight
        )
        await process(frame: transformedFrame)
    }
}

protocol GestureActionExecuting {
    @MainActor
    func execute(
        action: Event,
        fingerTips: FingerTips?,
        previousFingerTips: FingerTips?
    ) async -> Event?
}

struct GestureActionExecutor: GestureActionExecuting {
    private let movementDeadZone: CGFloat = 0.8
    private let maximumMovement: CGFloat = 18
    private let movementGain: CGFloat = 5

    func execute(
        action: Event,
        fingerTips: FingerTips?,
        previousFingerTips: FingerTips?
    ) async -> Event? {
        switch action.behavior {
        case .moveMouse:
            guard let fingerTips, let previousFingerTips else { return nil }
            let movement = pointerMovement(
                from: previousFingerTips.index,
                to: fingerTips.index
            )
            guard movement != .zero else { return nil }
            await Action.moveMouse(
                dx: movement.x * movementGain,
                dy: movement.y * movementGain
            ).execute()
            return action
        case .scroll:
            guard let fingerTips, let previousFingerTips else { return nil }
            let dx = previousFingerTips.index.x - fingerTips.index.x
            let dy = previousFingerTips.index.y - fingerTips.index.y

            if abs(dx) >= abs(dy) {
                await Action.hscroll(clicks: Int(dx / 3)).execute()
            } else {
                await Action.vscroll(clicks: Int(dy / 3)).execute()
            }
            return action
        case .sequence:
            await action.steps.compactMap(\.swiftAutoGUIAction).execute()
            return action
        }
    }

    func pointerMovement(from previous: CGPoint, to current: CGPoint) -> CGPoint {
        boundedMovement(
            dx: previous.x - current.x,
            dy: current.y - previous.y
        )
    }

    private func boundedMovement(dx: CGFloat, dy: CGFloat) -> CGPoint {
        let magnitude = hypot(dx, dy)
        guard magnitude >= movementDeadZone else {
            return .zero
        }
        guard magnitude > maximumMovement else {
            return CGPoint(x: dx, y: dy)
        }

        let scale = maximumMovement / magnitude
        return CGPoint(x: dx * scale, y: dy * scale)
    }
}

private extension CommandStep {
    var swiftAutoGUIAction: Action? {
        switch kind {
        case .leftClick:
            return .leftClick
        case .rightClick:
            return .rightClick
        case .doubleClick:
            return .doubleClick()
        case .typeText:
            return .write(value)
        case .shortcut:
            let keys = value
                .split(separator: "+")
                .compactMap { Key(commandName: String($0)) }
            return keys.isEmpty ? nil : .keyShortcut(keys)
        case .wait:
            return .wait(max(0, Double(value) ?? 0))
        }
    }
}

private extension Key {
    init?(commandName: String) {
        let name = commandName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let aliases: [String: Key] = [
            "cmd": .command, "⌘": .command,
            "ctrl": .control, "⌃": .control,
            "alt": .option, "opt": .option, "⌥": .option,
            "⇧": .shift,
            "return": .returnKey, "enter": .returnKey,
            "esc": .escape,
            "left": .leftArrow, "right": .rightArrow,
            "up": .upArrow, "down": .downArrow,
            "0": .zero, "1": .one, "2": .two, "3": .three, "4": .four,
            "5": .five, "6": .six, "7": .seven, "8": .eight, "9": .nine
        ]

        if let key = aliases[name] {
            self = key
        } else {
            self.init(rawValue: name)
        }
    }
}

struct PreviewGestureActionExecutor: GestureActionExecuting {
    func execute(
        action: Event,
        fingerTips: FingerTips?,
        previousFingerTips: FingerTips?
    ) async -> Event? {
        action
    }
}
