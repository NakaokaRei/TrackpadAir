//
//  ImageHelper.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/18.
//

import Foundation
import AVFoundation
import Cocoa

private let imageContext = CIContext(options: [.cacheIntermediates: false])

func NSImageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> NSImage? {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
        return nil
    }

    let ciImage = CIImage(cvImageBuffer: pixelBuffer)
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)

    guard let cgImage = imageContext.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: width, height: height)) else {
        return nil
    }

    let nsImage = NSImage(cgImage: cgImage, size: CGSize(width: width, height: height))
    return nsImage
}
