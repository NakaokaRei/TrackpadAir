//
//  HandGestureView.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/18.
//

import SwiftUI

struct HandGestureView: View {

    @StateObject var viewModel = HandGestureViewModel()
    @State private var startVideo = false

    var body: some View {
        VStack(spacing: 18) {
            header
            videoView
            statusStrip
        }
        .padding(24)
        .frame(minWidth: viewModel.imageWidth + 48, minHeight: viewModel.imageHeight + 170)
    }
}

extension HandGestureView {
    var header: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TrackpadAir")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Gesture diagnostics")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            statusBadge
            videoButton
        }
    }

    var statusBadge: some View {
        Label(startVideo ? "Running" : "Stopped", systemImage: startVideo ? "video.fill" : "video.slash.fill")
            .foregroundStyle(startVideo ? .green : .secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.thinMaterial, in: Capsule())
    }

    var videoView: some View {
        Group {
            if let nsImage = viewModel.buffImage, startVideo {
                ZStack {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .opacity(0.5)
                    if let fingerTips = viewModel.fingerTips {
                        FingerTipsView(fingerTips: fingerTips)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(viewModel.recognizedGesture.displayName)
                            .font(.headline)
                        Text(viewModel.event?.displayName ?? "No action")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .padding(12)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "video.slash")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                    Text("Capture is stopped")
                        .font(.title3)
                        .fontWeight(.medium)
                    Text("Start capture to preview hand tracking and verify gesture actions.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
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
                    Label("Stop", systemImage: "stop.fill")
                }
            } else {
                Button(action: {
                    viewModel.startCapture()
                    startVideo = true
                }) {
                    Label("Start", systemImage: "play.fill")
                }
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    var statusStrip: some View {
        HStack(spacing: 12) {
            DiagnosticItem(
                title: "Recognized Gesture",
                value: viewModel.recognizedGesture == .none ? "None" : viewModel.recognizedGesture.displayName,
                symbolName: viewModel.recognizedGesture.symbolName
            )
            DiagnosticItem(
                title: "Executed Action",
                value: viewModel.event?.displayName ?? "None",
                symbolName: viewModel.event?.symbolName ?? "minus.circle"
            )
            DiagnosticItem(
                title: "Finger Tips",
                value: viewModel.fingerTips == nil ? "Not detected" : "Detected",
                symbolName: viewModel.fingerTips == nil ? "hand.raised.slash" : "hand.raised"
            )
        }
    }
}

private struct DiagnosticItem: View {
    let title: String
    let value: String
    let symbolName: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbolName)
                .frame(width: 20)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
