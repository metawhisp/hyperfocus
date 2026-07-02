// ScreenContextService.swift — the magic wand (canon #29): suggests a mission from the local screen
// context — the frontmost non-Hyperfocus window's title (or app name). Read-only, local, instant;
// nothing is stored or transmitted.

import AppKit

final class ScreenContextService {
    /// A mission suggestion from what the user was just working on, e.g. "Continue: Q3 report.numbers".
    func suggestMission() -> String? {
        let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements],
                                              kCGNullWindowID) as? [[String: Any]] ?? []
        for w in info {
            guard (w[kCGWindowLayer as String] as? Int) == 0,
                  let owner = w[kCGWindowOwnerName as String] as? String,
                  owner != "Hyperfocus" else { continue }
            // Window titles need the Screen Recording grant; fall back to the app name without it.
            let title = (w[kCGWindowName as String] as? String) ?? ""
            let subject = title.isEmpty ? owner : title
            guard !subject.isEmpty else { continue }
            return "Continue: \(String(subject.prefix(60)))"
        }
        return nil
    }
}
