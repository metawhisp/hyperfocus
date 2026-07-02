// GlassCard.swift — shared glass-card container style + palette + helpers used by all card UIs (canon §2).

import SwiftUI

/// Focus-mode palette (canon §9 "expensive macOS, not gaming UI"): calm green, warm amber, soft red.
enum Palette {
    static let green = Color(red: 0.16, green: 0.92, blue: 0.55)
    static let amber = Color(red: 1.00, green: 0.72, blue: 0.23)
    static let red   = Color(red: 1.00, green: 0.36, blue: 0.36)
}

/// mm:ss for a whole-second count.
func mmss(_ seconds: Int) -> String {
    let s = max(0, seconds)
    return String(format: "%02d:%02d", s / 60, s % 60)
}

/// Segmented "analog" display font (DSEG, bundled under Resources/Fonts). Falls back to system if the
/// font failed to register. DSEG7 = 7-segment (numbers/clock), DSEG14 = 14-segment (alphanumeric).
enum SegFont {
    static func seg7(_ size: CGFloat) -> Font { .custom("DSEG7Classic-Bold", size: size) }
    static func seg14(_ size: CGFloat) -> Font { .custom("DSEG14Classic-Bold", size: size) }
}

/// Dark translucent glass card: ultraThinMaterial, continuous corners, hairline stroke, soft shadow.
struct GlassCard<Content: View>: View {
    var width: CGFloat? = nil
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(22)
            .frame(width: width)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.75)
            )
            .shadow(color: .black.opacity(0.38), radius: 26, x: 0, y: 14)
            .preferredColorScheme(.dark)
    }
}
