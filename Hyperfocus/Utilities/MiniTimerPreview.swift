// MiniTimerPreview.swift — DEBUG-only interactive demo (HF_MINI_PREVIEW=1) of the proposed
// HUD collapse: double-click the timer card → it flies into the orb and a compact matrix
// readout appears under the orb; click the digits → the card flies back. Preview-before-prod:
// the user approves the design + motion here before the real windows get the behavior.

#if DEBUG
import SwiftUI
import AppKit

/// Compact readout that lives under the orb while the HUD is collapsed.
struct MiniTimerPill: View {
    let mm: String
    let ss: String

    var body: some View {
        MatrixTimer(mm: mm, ss: ss, size: 15, color: .white)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Capsule().fill(Color.black.opacity(0.55)))
            .overlay(Capsule().strokeBorder(.white.opacity(0.10), lineWidth: 1))
            .shadow(color: FD.lime.opacity(0.35), radius: 10)
    }
}

private struct DemoHUDCard: View {
    let mm: String
    let ss: String
    let fraction: CGFloat
    var onClose: () -> Void

    var body: some View {
        FDCard(width: 360) {
            VStack(spacing: 14) {
                VStack(spacing: 6) {
                    MatrixTimer(mm: mm, ss: ss, size: 36, color: .white)
                    Text("hyper fast task")
                        .font(.system(size: 12)).foregroundStyle(FD.label)
                }
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.black.opacity(0.35))
                    Capsule().fill(FD.limeGradient)
                        .frame(width: max(14, fraction * 312))
                        .shadow(color: FD.lime.opacity(0.8), radius: 10)
                }
                .frame(width: 312, height: 26)
            }
            // Same X as the real HUD — here it opens the STOP HYPERFOCUS? mock.
            .overlay(alignment: .topTrailing) {
                FDCloseButton { onClose() }
                    .offset(x: 8, y: -8)
            }
        }
    }
}

struct MiniCollapseDemoView: View {
    @State private var collapsed = false
    @State private var showConfirm = false
    // Gentle glide, not a snap; the pill lands a beat after the card leaves.
    private let glide = Animation.spring(response: 0.6, dampingFraction: 0.88)

    // Demo geometry: orb top-right (like real usage), card mid-left.
    private let orbCenter = CGPoint(x: 600, y: 96)
    private let pillCenter = CGPoint(x: 600, y: 168)
    private let cardCenter = CGPoint(x: 280, y: 240)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            let total = 25 * 60
            let remaining = total - Int(t) % total
            let mm = String(format: "%02d", remaining / 60)
            let ss = String(format: "%02d", remaining % 60)
            let fraction = CGFloat(total - remaining) / CGFloat(total)

            ZStack {
                // Orb — always on screen; the collapsed readout docks under it.
                RingToParticlesOrb(t: t, progress: 1, diameter: 56, brightness: 2.7)
                    .frame(width: 110, height: 110)
                    .position(orbCenter)

                // All effects are applied BEFORE .position so hit areas stay element-sized —
                // a contentShape after .position would swallow clicks across the whole window.
                MiniTimerPill(mm: mm, ss: ss)
                    .contentShape(Capsule())
                    .onTapGesture { collapsed = false }
                    .scaleEffect(collapsed ? 1 : 0.5, anchor: .top)
                    .offset(y: collapsed ? 0 : -14)
                    .opacity(collapsed ? 1 : 0)
                    .animation(glide.delay(collapsed ? 0.12 : 0), value: collapsed)
                    .position(pillCenter)
                    .allowsHitTesting(collapsed && !showConfirm)

                DemoHUDCard(mm: mm, ss: ss, fraction: fraction,
                            onClose: { withAnimation(.easeOut(duration: 0.2)) { showConfirm = true } })
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) { collapsed = true }
                    // Shrinks toward the orb (anchor lies beyond the card, at the orb's corner);
                    // fades out early so the final part of the shrink is invisible → soft feel.
                    .scaleEffect(collapsed ? 0.12 : 1, anchor: UnitPoint(x: 1.4, y: -0.35))
                    .opacity(collapsed ? 0 : 1)
                    .animation(glide.delay(collapsed ? 0 : 0.12), value: collapsed)
                    .position(cardCenter)
                    .allowsHitTesting(!collapsed && !showConfirm)

                if showConfirm {
                    Color.black.opacity(0.45)
                        .onTapGesture { withAnimation(.easeOut(duration: 0.2)) { showConfirm = false } }
                    ExitConfirmView(
                        onStay: { withAnimation(.easeOut(duration: 0.2)) { showConfirm = false } },
                        onExit: { withAnimation(.easeOut(duration: 0.2)) { showConfirm = false } })
                        .transition(.scale(scale: 0.92).combined(with: .opacity))
                }

                VStack {
                    Spacer()
                    Text("2× КЛИК ПО КАРТОЧКЕ — СВЕРНУТЬ   ·   КЛИК ПО ЦИФРАМ — РАЗВЕРНУТЬ   ·   ✕ — STOP?")
                        .font(.system(size: 10, weight: .bold)).tracking(1.1)
                        .foregroundStyle(FD.label)
                        .padding(.bottom, 14)
                }
                .allowsHitTesting(false)
            }
            .frame(width: 720, height: 430)
        }
        .background(
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [FD.deviceHi, FD.device], startPoint: .top, endPoint: .bottom)
                FDDotGrid()
            }
        )
        .preferredColorScheme(.dark)
    }
}

@MainActor
enum MiniTimerPreviewWindow {
    private static var window: NSWindow?

    static func show() {
        let w = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 720, height: 430),
                         styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Hyperfocus — HUD Collapse Demo"
        w.level = .floating
        w.isReleasedWhenClosed = false
        w.contentView = NSHostingView(rootView: MiniCollapseDemoView())
        w.center()
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = w
    }
}
#endif
