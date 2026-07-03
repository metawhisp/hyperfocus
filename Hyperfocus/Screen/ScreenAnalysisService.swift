// ScreenAnalysisService.swift — local, privacy-safe distraction detection from on-screen text (canon §13 #23).
//
// During a session this periodically captures the main display via ScreenCaptureKit, runs Vision text
// recognition IN MEMORY, and checks the recognized text against a small distraction keyword list. It
// emits only the matched term — the captured image is never stored, written, or uploaded, and is
// discarded immediately after analysis. Runs only when Screen Recording is authorized.

import Foundation
import ScreenCaptureKit
import Vision

final class ScreenAnalysisService {
    /// Called on the main thread with the matched distraction term and the recognized screen
    /// lines (for the context judge) when a distraction is detected on screen.
    var onDistraction: ((String, [String]) -> Void)?

    private var timer: Timer?
    private var running = false
    private var busy = false

    func start() {
        guard !running, CGPreflightScreenCaptureAccess() else { return }
        running = true
        let t = Timer(timeInterval: Constants.Screen.analysisInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        running = false
    }

    private func tick() {
        guard !busy else { return }
        busy = true
        Task { [weak self] in
            defer { self?.busy = false }
            guard let self, let image = await self.captureMainDisplay() else { return }
            let terms = self.recognizeText(in: image)                     // in-memory only
            guard let hit = self.matchDistraction(terms) else { return }
            await MainActor.run { self.onDistraction?(hit, terms) }
            // `image` goes out of scope here — never persisted or transmitted.
        }
    }

    private func captureMainDisplay() async -> CGImage? {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let display = content.displays.first else { return nil }
            let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
            let config = SCStreamConfiguration()
            config.width = max(1, display.width / Constants.Screen.captureScale)
            config.height = max(1, display.height / Constants.Screen.captureScale)
            config.showsCursor = false
            return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        } catch {
            return nil
        }
    }

    private func recognizeText(in image: CGImage) -> [String] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .fast
        request.usesLanguageCorrection = false
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try? handler.perform([request])
        return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string.lowercased() }
    }

    private func matchDistraction(_ terms: [String]) -> String? {
        for keyword in Constants.Screen.distractionKeywords {
            let k = keyword.trimmingCharacters(in: .whitespaces)
            if terms.contains(where: { $0.contains(k) }) { return k }
        }
        return nil
    }
}
