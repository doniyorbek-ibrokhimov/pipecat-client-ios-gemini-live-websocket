//
//  VideoRecorderDelegate.swift
//  PipecatClientIOSGeminiLiveWebSocket
//
//  Created by Doniyorbek Ibrokhimov on 27/04/25.
//


import AVFoundation
import UIKit

protocol VideoRecorderDelegate: AnyObject {
    func videoRecorder(_ videoRecorder: VideoRecorder, didGetFrameWithSize size: CGSize)
}

class VideoRecorder: NSObject{
    // MARK: - Public
    public weak var delegate: VideoRecorderDelegate?

    private let sessionQueue = DispatchQueue(label: "SessionQueue")
//    private var lastFrameSent = Date()
//    private let minFrameInterval: TimeInterval = 0.1

    var isRecording: Bool {
        captureSession?.isRunning ?? false
    }

    func resume() {
        // If already setup, simply restart capture session
        sessionQueue.async {
            if self.didSetup {
                self.captureSession?.startRunning()
                return
            }
        

            let session = AVCaptureSession()
            session.beginConfiguration()
            session.sessionPreset = .hd1280x720

            // Input (front camera preferred)
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) ??
                    AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .unspecified) else {
                print("No video device found")
                return
            }
            
            do {
                let cameraInput = try AVCaptureDeviceInput(device: camera)
                guard session.canAddInput(cameraInput) else {
                    print("Cannot add video input")
                    return
                }
                session.addInput(cameraInput)
            } catch {
                print("cannot find camera input")
            }

            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            let queue = DispatchQueue(label: "com.pipecat.GeminiLiveWebSocketTransport.VideoRecorder")
            videoOutput.setSampleBufferDelegate(self, queue: queue)
            guard session.canAddOutput(videoOutput) else {
                print("Cannot add video output")
                return
            }
            session.addOutput(videoOutput)

            session.commitConfiguration()
            session.startRunning()

            self.captureSession = session
            self.didSetup = true
        }
    }

    func pause() {
        sessionQueue.async {
            self.captureSession?.stopRunning()
        }
    }

    func stop() {
        guard didSetup else { return }
        sessionQueue.async {
            self.captureSession?.stopRunning()
            self.captureSession = nil
            self.didSetup = false
        }
    }

    func terminateVideoStream() {
        streamContinuation?.finish()
    }

    func streamVideo() -> AsyncStream<Data> {
        return AsyncStream { continuation in
            self.streamContinuation = continuation
        }
    }

    func adaptToDeviceChange() throws {
        let wasRunning = captureSession?.isRunning ?? false
        stop()
        if wasRunning {
            try resume()
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
        delegate?.videoRecorder(self, didGetFrameWithSize: uiImage.size)

        // Only yield frames at appropriate intervals
//        if Date().timeIntervalSince(lastFrameSent) >= minFrameInterval {
            streamContinuation?.yield(jpegData)
//            lastFrameSent = Date()
//        }
    }
}
