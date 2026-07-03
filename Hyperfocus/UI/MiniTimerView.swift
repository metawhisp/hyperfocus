// MiniTimerView.swift — collapsed HUD readout docked under the orb (canon #33).
// Double-click the timer card → it gives way to this compact pill; click the digits → the
// card comes back. Design/motion approved in the HF_MINI_PREVIEW demo.

import SwiftUI

/// Compact matrix readout in a dark capsule with the orb-green glow.
struct MiniTimerPill: View {
    let mm: String
    let ss: String

    var body: some View {
        MatrixTimer(mm: mm, ss: ss, size: 16, color: .white)
            .fixedSize()   // panel fittingSize under-measures text → digits truncate to "…"
            .padding(.horizontal, 13).padding(.vertical, 7)
            .background(Capsule().fill(Color.black.opacity(0.78)))   // readable on light desktops
            .overlay(Capsule().strokeBorder(.white.opacity(0.14), lineWidth: 1))
            .shadow(color: Palette.green.opacity(0.5), radius: 11)   // same green as the orb
    }
}

/// Live session readout for the collapsed state; a click expands back to the full HUD.
/// Lands with the same springy drop the demo had.
struct MiniTimerHUDView: View {
    @EnvironmentObject var app: AppState
    var onExpand: () -> Void
    @State private var appeared = false

    var body: some View {
        let total = Int(app.context.remainingFocusTime.rounded())
        MiniTimerPill(mm: String(format: "%02d", total / 60),
                      ss: String(format: "%02d", total % 60))
            .contentShape(Capsule())
            .onTapGesture { onExpand() }
            .scaleEffect(appeared ? 1 : 0.5, anchor: .top)
            .offset(y: appeared ? 0 : -14)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.88).delay(0.08)) {
                    appeared = true
                }
            }
    }
}
