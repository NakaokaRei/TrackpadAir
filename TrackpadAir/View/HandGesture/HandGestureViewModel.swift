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
    private let setting: Setting
    private let actionExecutor: any GestureActionExecuting

    let imageWidth: CGFloat = 384 * 2
    let imageHeight: CGFloat = 216 * 2

    var buffTips: FingerTips?

    init(
        setting: Setting? = nil,
        actionExecutor: (any GestureActionExecuting)? = nil
    ) {
        self.setting = setting ?? Setting.shared
        self.actionExecutor = actionExecutor ?? GestureActionExecutor()
    }

    func startCapture() {
        videoCapture.run { sampleBuffer in
            Task {
                self.buffImage = NSImageFromSampleBuffer(sampleBuffer)
                let fingerTips = try await self.handPoseManager.recognize(sampleBuffer)

                guard let fingerTips else { return }
                self.buffTips = self.fingerTips
                self.fingerTips = CoordinateHelper.transform(
                    fingerTips: fingerTips,
                    width: self.imageWidth,
                    height: self.imageHeight
                )

                await self.operate()
            }
        }
    }

    func stop() {
        videoCapture.stop()
        recognizedGesture = .none
        event = nil
    }

    func operate() async {
        guard let fingerTips else { return }
        let gesture = HandGestureProcessor.process(fingerTips: fingerTips)
        let previousGesture = recognizedGesture
        recognizedGesture = gesture

        guard let action = setting.action(for: gesture) else {
            event = nil
            return
        }

        if action.behavior == .sequence, gesture == previousGesture {
            event = nil
            return
        }

        event = await actionExecutor.execute(
            action: action,
            fingerTips: fingerTips,
            previousFingerTips: buffTips
        )
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
    func execute(
        action: Event,
        fingerTips: FingerTips?,
        previousFingerTips: FingerTips?
    ) async -> Event? {
        switch action.behavior {
        case .moveMouse:
            guard let fingerTips, let previousFingerTips else { return nil }
            let dx = fingerTips.index.x - previousFingerTips.index.x
            let dy = fingerTips.index.y - previousFingerTips.index.y
            await Action.moveMouse(dx: dx * 5, dy: dy * 5).execute()
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
