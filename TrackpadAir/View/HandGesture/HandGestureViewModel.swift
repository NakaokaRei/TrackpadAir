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
        recognizedGesture = gesture

        guard let action = setting.action(for: gesture) else {
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
        switch action {
        case .moveMouse:
            guard let fingerTips, let previousFingerTips else { return nil }
            let dx = fingerTips.index.x - previousFingerTips.index.x
            let dy = fingerTips.index.y - previousFingerTips.index.y
            await Action.moveMouse(dx: dx * 5, dy: dy * 5).execute()
            return .moveMouse
        case .leftClick:
            await Action.leftClick.execute()
            return .leftClick
        case .scroll:
            guard let fingerTips, let previousFingerTips else { return nil }
            let dx = previousFingerTips.index.x - fingerTips.index.x
            let dy = previousFingerTips.index.y - fingerTips.index.y

            if abs(dx) >= abs(dy) {
                await Action.hscroll(clicks: Int(dx / 3)).execute()
            } else {
                await Action.vscroll(clicks: Int(dy / 3)).execute()
            }
            return .scroll
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
