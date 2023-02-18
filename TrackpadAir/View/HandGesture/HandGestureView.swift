//
//  HandGestureView.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/18.
//

import SwiftUI

public struct HandGestureView: View {

    @ObservedObject var viewModel = HandGestureViewModel()
    @State private var startVideo = false

    public init() {}

    public var body: some View {
        VStack(spacing: 15) {
            videoView
                .padding([.leading, .top, .trailing])
            videoButton
                .padding(.bottom)
        }
    }
}

extension HandGestureView {

    var videoView: some View {
        Group {
            if let nsImage = viewModel.buffImage, startVideo {
                ZStack {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .cornerRadius(10)
                    if let fingerTips = viewModel.fingerTips {
                        FingerTipsView(fingerTips: fingerTips)
                    }
                }
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
                VStack {
                    Text("Please run video")
                }
            }
        }
        .frame(width: viewModel.imageWidth, height: viewModel.imageHeight)
    }

    var videoButton: some View {
        Group {
            if startVideo {
                Button(action: {
                    viewModel.stop()
                    startVideo = false
                }) {
                    Image(systemName: "video.fill")
                }
            } else {
                Button(action: {
                    viewModel.startCapture()
                    startVideo = true
                }) {
                    Image(systemName: "video.slash.fill")
                }
            }
        }
    }
}
