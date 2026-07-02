// CameraPresenceService.swift — real presence detection: AVCaptureSession (640×480) + Vision at 2 Hz (canon §6).
//
// PRIVACY (canon §6, enforced): frames are analyzed in-memory and discarded. No file output, no
// AVAssetWriter, no pixel-buffer persistence, no network. Only a Bool (face present) ever leaves
// this class. The capture session is fully torn down on stop().

import AVFoundation
import Vision

final class CameraPresenceService: NSObject, PresenceDetecting, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onEvent: ((PresenceEvent) -> Void)?

    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: Constants.Camera.queueLabel)
    private let request = VNDetectFaceRectanglesRequest()

    private var lastDetection: CFTimeInterval = 0
    private var lastReported: Bool?          // nil until first reading — emit change-only + initial

    func startWarmup() { configureAndStart() }

    func startDetection() { configureAndStart() }

    func stop() {
        queue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning { self.session.stopRunning() }
            for input in self.session.inputs { self.session.removeInput(input) }
            for out in self.session.outputs { self.session.removeOutput(out) }
        }
        output.setSampleBufferDelegate(nil, queue: nil)
        lastReported = nil
    }

    // MARK: Setup

    private func configureAndStart() {
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            emit(.cameraState(.notAuthorized)); return
        }
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
                ?? AVCaptureDevice.default(for: .video) else {
            emit(.cameraState(.unavailable)); return
        }
        queue.async { [weak self] in
            guard let self else { return }
            guard !self.session.isRunning else { return }
            self.session.beginConfiguration()
            if self.session.canSetSessionPreset(.vga640x480) { self.session.sessionPreset = .vga640x480 }
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if self.session.canAddInput(input) { self.session.addInput(input) }
                self.output.alwaysDiscardsLateVideoFrames = true
                self.output.setSampleBufferDelegate(self, queue: self.queue)
                if self.session.canAddOutput(self.output) { self.session.addOutput(self.output) }
                self.session.commitConfiguration()
                self.session.startRunning()
            } catch {
                self.session.commitConfiguration()
                self.emit(.cameraState(.unavailable))
            }
        }
    }

    // MARK: Frame handling (2 Hz throttle, change-only emission)

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        let now = CACurrentMediaTime()
        guard now - lastDetection >= Constants.Camera.detectionInterval else { return }
        lastDetection = now
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored, options: [:])
        try? handler.perform([request])
        let facePresent = !(request.results?.isEmpty ?? true)

        if lastReported != facePresent {
            lastReported = facePresent
            emit(facePresent ? .facePresent : .faceMissing)
        }
        // pixelBuffer is not retained, copied, or written anywhere — discarded here.
    }

    private func emit(_ event: PresenceEvent) {
        DispatchQueue.main.async { [weak self] in self?.onEvent?(event) }
    }
}
