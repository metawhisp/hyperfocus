// Tone639RendererTests.swift — the 639 Hz focus tone + its rising entrance (canon #29/#31).

import XCTest
@testable import Hyperfocus

final class Tone639RendererTests: XCTestCase {
    private let sr = 48_000.0

    /// Positive-going zero crossings over a short window → fundamental frequency estimate.
    /// Measured at points where the warmth partials haven't bloomed yet, so the tone is clean.
    private func freq(_ entrance: Tone639Renderer.Entrance, at tStart: Double, window: Double = 0.1) -> Double {
        let r = Tone639Renderer(entrance: entrance, sampleRate: sr)
        let n = Int(window * sr)
        var prev: Float = 0, crossings = 0, first = true
        for i in 0..<n {
            let s = r.render(t: tStart + Double(i) / sr).left
            if !first && prev <= 0 && s > 0 { crossings += 1 }
            prev = s; first = false
        }
        return Double(crossings) / window
    }

    private func rms(_ entrance: Tone639Renderer.Entrance, from t0: Double, to t1: Double) -> Float {
        let r = Tone639Renderer(entrance: entrance, sampleRate: sr)
        var sum: Float = 0; var n = 0
        var t = 0.0
        // render contiguously from 0 so phase/envelope match real playback, sample the window [t0,t1]
        while t < t1 {
            let s = r.render(t: t).left
            if t >= t0 { sum += s * s; n += 1 }
            t += 1 / sr
        }
        return n > 0 ? (sum / Float(n)).squareRoot() : 0
    }

    func test_outputAlwaysBoundedAndFinite() {
        for entrance in [Tone639Renderer.Entrance.glide, .rise] {
            let r = Tone639Renderer(entrance: entrance, sampleRate: sr)
            var t = 0.0
            while t < 25 {
                let s = r.render(t: t).left
                XCTAssertTrue(s.isFinite, "non-finite sample at t=\(t)")
                XCTAssertLessThanOrEqual(abs(s), 1.0, "clipped sample \(s) at t=\(t)")
                t += 1 / sr
            }
        }
    }

    func test_glideRisesInPitchThenLocksOn639() {
        let f1 = freq(.glide, at: 1.0)     // early climb — still low
        let f2 = freq(.glide, at: 4.0)     // mid climb — higher
        let f3 = freq(.glide, at: 15.0)    // long after the lock — 639
        XCTAssertLessThan(f1, f2, "pitch should rise during the glide")
        XCTAssertLessThan(f2, 639, "still climbing before the lock")
        XCTAssertEqual(f3, 639, accuracy: 25, "glide must settle on 639 Hz")
    }

    func test_riseStepsClimbAndLockOn639() {
        let first = freq(.rise, at: 0.4)   // first rung of the ladder (213 Hz)
        let lock  = freq(.rise, at: 4.6)   // final rung = 639
        let hold  = freq(.rise, at: 15.0)  // sustained tone
        XCTAssertEqual(first, 213, accuracy: 25, "first step is the 213 Hz rung")
        XCTAssertLessThan(first, lock, "the ladder climbs")
        XCTAssertEqual(hold, 639, accuracy: 25, "rise must hold 639 Hz")
    }

    func test_entranceSwellsFromQuietToSteady() {
        // The entrance is a crescendo: the onset is much quieter than the settled tone.
        let onset = rms(.glide, from: 0.0, to: 0.2)
        let settled = rms(.glide, from: 14.0, to: 15.0)
        XCTAssertLessThan(onset, settled * 0.6, "onset should be clearly quieter than the steady tone")
    }

    func test_sustainLevelMatchesTheSoundFamily() {
        // RMS-matched to the other soundscapes (~0.18 raw) so switching sounds never jumps in level.
        let level = rms(.glide, from: 14.0, to: 16.0)
        XCTAssertGreaterThan(level, 0.10, "sustained tone must be audible")
        XCTAssertLessThan(level, 0.26, "sustained tone must stay a whisper, matched to the family")
    }
}
