// MiniTimerView.swift — collapsed HUD readout docked under the orb (canon #33).
// Double-click the timer card → it gives way to this compact pill; click the digits → the
// card comes back. Design/motion approved in the HF_MINI_PREVIEW demo.

import SwiftUI

/// Compact matrix readout in a dark capsule with the orb-green glow.
struct MiniTimerPill: View {
    let mm: String
    let ss: String

    var body: some View {
        MatrixTimer(mm: mm, ss: ss, size: 15, color: .white)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Capsule().fill(Color.black.opacity(0.55)))
            .overlay(Capsule().strokeBorder(.white.opacity(0.10), lineWidth: 1))
            .shadow(color: Palette.green.opacity(0.4), radius: 10)   // same green as the orb
    }
}

/// Live session readout for the collapsed state; a click expands back to the full HUD.
struct MiniTimerHUDView: View {
    @EnvironmentObject var app: AppState
    var onExpand: () -> Void

    var body: some View {
        let total = Int(app.context.remainingFocusTime.rounded())
        MiniTimerPill(mm: String(format: "%02d", total / 60),
                      ss: String(format: "%02d", total % 60))
            .contentShape(Capsule())
            .onTapGesture { onExpand() }
    }
}
