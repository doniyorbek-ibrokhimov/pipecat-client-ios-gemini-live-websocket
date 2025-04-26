//
//  VideoRecorderDelegate.swift
//  PipecatClientIOSGeminiLiveWebSocket
//
//  Created by Doniyorbek Ibrokhimov on 27/04/25.
//


import AVFoundation
import UIKit

protocol VideoRecorderDelegate: AnyObject {
    func streamVideo() -> AsyncStream<Data>
}

class VideoRecorder: NSObject {

    func streamVideo() -> AsyncStream<Data> {
        return AsyncStream { continuation in
            self.streamContinuation = continuation
        }
    }

    // MARK: - Private
    private var captureSession: AVCaptureSession?
    private var didSetup = false
    private var streamContinuation: AsyncStream<Data>.Continuation?
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension VideoRecorder: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let uiImage = UIImage(cgImage: cgImage)
        guard let jpegData = uiImage.jpegData(compressionQuality: 0.3) else { return }

        // Notify delegate about frame size (optional)
//        delegate?.videoRecorder(self)

        // Only yield frames at appropriate intervals
//        if Date().timeIntervalSince(lastFrameSent) >= minFrameInterval {
            streamContinuation?.yield(jpegData)
//            lastFrameSent = Date()
//        }
    }
}
