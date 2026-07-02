// AuraPreviews.swift — DEBUG-only LIVE aura gallery (HF_AURA_PREVIEW=1): uniform perimeter frame
// variants around a mock screen. The current 4-strip aura leaves corner gaps; the replacement is a
// single frame stroke — even glow along the whole perimeter, corners included. Preview → user picks
// → only then production changes.

#if DEBUG
import SwiftUI
import AppKit

private struct AuraMockCell: View {
    let variant: Int
    private let green = Color(red: 0.16, green: 0.92, blue: 0.55)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            let breathe: Double = {
                switch variant {
                case 1: return 0.92 + 0.08 * sin(t * 0.7)     // near-steady
                case 2: return 0.72 + 0.28 * sin(t * 1.1)     // clear breathing
                default: return 0.85 + 0.15 * sin(t * 0.8)    // deep spread, gentle breathe
                }
            }()
            ZStack {
                // mock desktop
                RoundedRectangle(cornerRadius: 9)
                    .fill(LinearGradient(colors: [Color(red: 0.09, green: 0.10, blue: 0.14),
                                                  Color(red: 0.13, green: 0.12, blue: 0.18)],
                                         startPoint: .top, endPoint: .bottom))
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.08)).frame(width: 90, height: 40)
                    RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.05)).frame(width: 120, height: 24)
                }
                // aura frame — ONE closed stroke: uniform along the whole perimeter, no corner gaps
                Group {
                    if variant == 3 {
                        RoundedRectangle(cornerRadius: 9)
                            .strokeBorder(green, lineWidth: 22)
                            .blur(radius: 22)
                            .opacity(0.30 * breathe)
                    }
                    RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(green, lineWidth: variant == 3 ? 9 : 7)
                        .blur(radius: variant == 3 ? 12 : 9)
                        .opacity((variant == 2 ? 0.90 : 0.80) * breathe)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .frame(width: 216, height: 136)
        }
    }
}

struct AuraPreviewGalleryView: View {
    private let names = ["A1 · Ровная рамка", "A2 · Дыхание", "A3 · Глубокое свечение"]

    var body: some View {
        VStack(spacing: 14) {
            Text("Аура по периметру экрана — равномерная, углы без дырок (мини-макет экрана)")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
            HStack(spacing: 20) {
                ForEach(1...3, id: \.self) { v in
                    VStack(spacing: 8) {
                        AuraMockCell(variant: v)
                        Text(names[v - 1])
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
            }
        }
        .padding(24)
        .background(Color(red: 0.055, green: 0.065, blue: 0.09))
    }
}

@MainActor
enum AuraPreviewWindow {
    private static var window: NSWindow?

    static func show() {
        let w = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 800, height: 280),
                         styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Hyperfocus — Aura Preview"
        w.level = .floating
        w.isReleasedWhenClosed = false
        w.contentView = NSHostingView(rootView: AuraPreviewGalleryView())
        w.center()
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = w
    }
}
#endif
