// OrbPositionStore.swift — persists the orb position (hf.orbPosition) and clamps it to visible screen bounds (canon §2, §8).
//
// The stored position is the orb window's bottom-left origin, encoded as JSON `{x,y}` under
// `hf.orbPosition`. On load it is clamped so the whole orb stays inside the given visible bounds
// (canon §3.6 screen-change handling); a missing or malformed value falls back to the default
// bottom-right corner with an 8 pt margin (canon §8).

import Foundation

final class OrbPositionStore {
    private let settings: SettingsStore

    init(settings: SettingsStore = SettingsStore()) {
        self.settings = settings
    }

    /// Loads the saved position clamped into `visibleBounds`, or the default if none/invalid.
    func load(visibleBounds: CGRect) -> CGPoint {
        guard let json = settings.orbPosition, let point = Self.decode(json) else {
            return defaultPosition(in: visibleBounds)
        }
        return clamp(point, in: visibleBounds)
    }

    func save(_ position: CGPoint) {
        settings.orbPosition = Self.encode(position)
    }

    /// Clears the stored position; the next load returns the default.
    func reset() {
        settings.orbPosition = nil
    }

    /// Default: top-right of the visible area, 8 pt margin, orb fully on-screen (canon §8, §13 #17).
    /// AppKit y grows upward, so "top" is `maxY - size - margin`.
    func defaultPosition(in bounds: CGRect) -> CGPoint {
        let size = settings.orbSize
        let margin = Constants.Orb.edgeMargin
        return CGPoint(x: bounds.maxX - size - margin, y: bounds.maxY - size - margin)
    }

    // MARK: Clamping

    private func clamp(_ p: CGPoint, in bounds: CGRect) -> CGPoint {
        let size = settings.orbSize
        let maxX = max(bounds.minX, bounds.maxX - size)
        let maxY = max(bounds.minY, bounds.maxY - size)
        return CGPoint(x: min(max(p.x, bounds.minX), maxX),
                       y: min(max(p.y, bounds.minY), maxY))
    }

    // MARK: JSON {x,y}

    private struct StoredPoint: Codable { let x: Double; let y: Double }

    private static func encode(_ p: CGPoint) -> String? {
        guard let data = try? JSONEncoder().encode(StoredPoint(x: p.x, y: p.y)) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func decode(_ json: String) -> CGPoint? {
        guard let data = json.data(using: .utf8),
              let sp = try? JSONDecoder().decode(StoredPoint.self, from: data) else { return nil }
        return CGPoint(x: sp.x, y: sp.y)
    }
}
