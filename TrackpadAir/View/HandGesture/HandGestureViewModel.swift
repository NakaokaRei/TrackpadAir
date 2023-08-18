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

    private let videoCapture = VideoCapture()
    private let handPoseManager = HandPoseManager()

    let imageWidth: CGFloat = 384 * 2
    let imageHeight: CGFloat = 216 * 2

    var buffTips: FingerTips?

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

                self.operate()
            }
        }
    }

    func stop() {
        videoCapture.stop()
    }

    func operate() {
        guard let fingerTips else { return }
        let state = HandGestureProcessor.process(fingerTips: fingerTips)
        switch state {
        case .indexPinch:
            moveMouse()
        case .middlePinch:
            leftClick()
        case .indexMiddlePinch:
            scroll()
        default:
            print("none")
        }
    }

    func moveMouse() {
        guard let fingerTips = self.fingerTips,
              let buffTips = self.buffTips else { return }

        let dx = fingerTips.index.x - buffTips.index.x
        let dy = fingerTips.index.y - buffTips.index.y

        SwiftAutoGUI.moveMouse(dx: dx * 5, dy: dy * 5)
        event = .moveMouse
    }

    func scroll() {
        guard let fingerTips = self.fingerTips,
              let buffTips = self.buffTips else { return }

        let dx = buffTips.index.x - fingerTips.index.x
        let dy =  buffTips.index.y - fingerTips.index.y

        if abs(dx) >= abs(dy) {
            SwiftAutoGUI.hscroll(clicks: Int(dx/3))
        } else {
            SwiftAutoGUI.vscroll(clicks: Int(dy/3))
        }
        event = .scroll
    }

    func leftClick() {
        SwiftAutoGUI.leftClick()
        event = .leftClick
    }

}
