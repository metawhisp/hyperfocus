// ScreenAnalysisService.swift — local, privacy-safe distraction detection from on-screen text
// (canon §13 #23, hardened per the corner-case hunt in canon #37).
//
// During a session this periodically captures EVERY display via ScreenCaptureKit at PIXEL
// resolution (SCDisplay reports points; dividing them made OCR blind to normal-sized text),
// excluding Hyperfocus's own windows (the HUD shows the mission — capturing it made the lexical
// judge see the mission "on screen" forever). Vision text recognition runs IN MEMORY at .accurate
// (the .fast path has no Cyrillic support — verified), and keywords match on WORD BOUNDARIES
// ("for you" must not fire on "for your convenience"). It emits only the matched term + the
// recognized lines — captured images are never stored, written, or uploaded. Runs only when
// Screen Recording is authorized.

import AppKit
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
            guard let self else { return }
            let images = await self.captureAllDisplays()
            let terms = images.flatMap { self.recognizeText(in: $0) }     // in-memory only;
            // the images go out of scope here — never persisted or transmitted
            guard let hit = Self.matchDistraction(terms) else { return }
            await MainActor.run { self.onDistraction?(hit, terms) }
        }
    }

    /// All displays at pixel resolution, Hyperfocus's own windows excluded.
    private func captureAllDisplays() async -> [CGImage] {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            let ownApps = content.applications.filter {
                $0.bundleIdentifier == Bundle.main.bundleIdentifier
            }
            var images: [CGImage] = []
            for display in content.displays {
                let filter = SCContentFilter(display: display,
                                             excludingApplications: ownApps, exceptingWindows: [])
                let config = SCStreamConfiguration()
                let scale = Self.pixelScale(for: display.displayID)
                // SCDisplay dimensions are POINTS; the config wants PIXELS — capturing at
                // points/2 starved the OCR (12 pt text became 6 px — unreadable).
                config.width = max(1, Int(Double(display.width) * scale))
                config.height = max(1, Int(Double(display.height) * scale))
                config.showsCursor = false
                if let image = try? await SCScreenshotManager.captureImage(contentFilter: filter,
                                                                           configuration: config) {
                    images.append(image)
                }
            }
            return images
        } catch {
            return []
        }
    }

    private static func pixelScale(for displayID: CGDirectDisplayID) -> Double {
        for screen in NSScreen.screens {
            if (screen.deviceDescription[.init("NSScreenNumber")] as? CGDirectDisplayID) == displayID {
                return screen.backingScaleFactor
            }
        }
        return 2
    }

    private func recognizeText(in image: CGImage) -> [String] {
        let request = VNRecognizeTextRequest()
        // .accurate is required: the .fast recognizer supports no Cyrillic at all (verified) —
        // RU screen text came out as Latin garbage and broke the lexical judge.
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US", "ru-RU"]
        request.usesLanguageCorrection = false
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try? handler.perform([request])
        return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string.lowercased() }
    }

    /// Word-boundary keyword matching over the recognized lines (internal for tests).
    static func matchDistraction(_ terms: [String]) -> String? {
        for keyword in Constants.Screen.distractionKeywords {
            guard let regex = boundaryRegexes[keyword] else { continue }
            for line in terms {
                let range = NSRange(line.startIndex..., in: line)
                if regex.firstMatch(in: line, range: range) != nil { return keyword }
            }
        }
        return nil
    }

    private static let boundaryRegexes: [String: NSRegularExpression] = {
        var out: [String: NSRegularExpression] = [:]
        for keyword in Constants.Screen.distractionKeywords {
            let escaped = NSRegularExpression.escapedPattern(for: keyword)
            out[keyword] = try? NSRegularExpression(pattern: "\\b\(escaped)\\b",
                                                    options: [.caseInsensitive])
        }
        return out
    }()
}
