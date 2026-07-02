// DesignSystem.swift — «NEON VOID» tokens & core components (specs/07, canon #29).
// One neon energy accent on deep dark glass; caps-labels; DSEG for numbers; top edge-light.

import SwiftUI

enum HF {
    // MARK: Colors
    static let void_ = Color(red: 0.043, green: 0.055, blue: 0.078)          // #0B0E14
    static let green = Color(red: 0.16, green: 0.92, blue: 0.55)             // #29EB8C
    static let teal = Color(red: 0.24, green: 0.90, blue: 0.88)              // #3DE6E0
    static let amber = Color(red: 1.00, green: 0.72, blue: 0.23)
    static let red = Color(red: 1.00, green: 0.36, blue: 0.36)
    static let textPrimary = Color.white.opacity(0.95)
    static let textSecondary = Color.white.opacity(0.60)
    static let textTertiary = Color.white.opacity(0.38)
    static let hairline = Color.white.opacity(0.08)
    static let fieldBG = Color.white.opacity(0.055)
    static let ghostBG = Color.white.opacity(0.07)

    static let accentGradient = LinearGradient(colors: [green, teal],
                                               startPoint: .leading, endPoint: .trailing)

    // MARK: Type
    static func display(_ size: CGFloat) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func body(_ size: CGFloat = 13) -> Font { .system(size: size) }
    static let caps = Font.system(size: 11, weight: .semibold)

    // MARK: Radius
    static let rCard: CGFloat = 24
    static let rControl: CGFloat = 12
}

/// Dark glass card with hairline border, top edge-light in the accent color, and dual shadow.
struct HFCard<Content: View>: View {
    var width: CGFloat? = nil
    var accent: Color = HF.green
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(24)
            .frame(width: width)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: HF.rCard, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: HF.rCard, style: .continuous)
                        .fill(HF.void_.opacity(0.55))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: HF.rCard, style: .continuous)
                    .strokeBorder(HF.hairline, lineWidth: 1)
            )
            .overlay(alignment: .top) {
                LinearGradient(colors: [accent.opacity(0), accent.opacity(0.8), accent.opacity(0)],
                               startPoint: .leading, endPoint: .trailing)
                    .frame(height: 1.5)
                    .padding(.horizontal, 28)
            }
            .shadow(color: .black.opacity(0.5), radius: 30, y: 18)
            .shadow(color: accent.opacity(0.10), radius: 40)
            .preferredColorScheme(.dark)
    }
}

/// Primary CTA: gradient capsule, black text, neon glow. Exactly one per screen.
struct HFPrimaryButton: View {
    let title: String
    var disabled = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(disabled ? HF.textTertiary : .black)
                .padding(.horizontal, 20).padding(.vertical, 10)
                .frame(minWidth: 44)
                .background(
                    Group {
                        if disabled { Capsule().fill(HF.ghostBG) }
                        else { Capsule().fill(HF.accentGradient) }
                    }
                )
                .shadow(color: disabled ? .clear : HF.green.opacity(0.5), radius: 14, y: 2)
        }
        .buttonStyle(HFPressStyle())
        .disabled(disabled)
    }
}

/// Secondary: quiet ghost capsule. `destructive` tints it red.
struct HFGhostButton: View {
    let title: String
    var destructive = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(destructive ? HF.red : HF.textPrimary)
                .padding(.horizontal, 16).padding(.vertical, 9)
                .background(Capsule().fill(destructive ? HF.red.opacity(0.12) : HF.ghostBG))
        }
        .buttonStyle(HFPressStyle())
    }
}

/// Selection chip: selected = gradient + glow, unselected = quiet ghost (no border).
struct HFChip: View {
    let label: String
    var icon: String? = nil
    let selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon { Image(systemName: icon).font(.system(size: 11, weight: .semibold)) }
                Text(label).font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(selected ? .black : HF.textSecondary)
            .padding(.horizontal, 14).padding(.vertical, 7)
            .background(
                Group {
                    if selected { Capsule().fill(HF.accentGradient) }
                    else { Capsule().fill(HF.ghostBG) }
                }
            )
            .shadow(color: selected ? HF.green.opacity(0.45) : .clear, radius: 10, y: 1)
        }
        .buttonStyle(HFPressStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: selected)
    }
}

/// UPPERCASE tracked section label.
struct HFCapsLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(HF.caps)
            .tracking(1.5)
            .foregroundStyle(HF.textTertiary)
    }
}

/// Stat mini-card: caps label over a DSEG value.
struct HFStatCell: View {
    let label: String
    let value: String
    var tint: Color = HF.green

    var body: some View {
        VStack(spacing: 6) {
            HFCapsLabel(text: label)
            Text(value)
                .font(SegFont.seg7(15))
                .foregroundStyle(tint)
                .shadow(color: tint.opacity(0.5), radius: 5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: HF.rControl).fill(Color.white.opacity(0.04)))
    }
}

/// Status pill: state dot + short label.
struct HFStatusPill: View {
    let label: String
    var color: Color = HF.green

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 7, height: 7)
                .shadow(color: color.opacity(0.8), radius: 3)
            Text(label).font(HF.body(12)).foregroundStyle(HF.textSecondary)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Capsule().fill(HF.ghostBG))
    }
}

/// Press feedback: 0.98 scale.
struct HFPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: — FLIGHT DECK (production design, user-approved; specs/07 v2, canon #29)
// Hardware-gadget language: dot-matrix display type (Doto), warm charcoal device cards with a
// dot-grid texture and corner glow bleed, acid-lime glowing progress, amber LED caps, pixel badges.

enum FD {
    static let device = Color(red: 0.075, green: 0.082, blue: 0.095)
    static let deviceHi = Color(red: 0.115, green: 0.125, blue: 0.140)
    static let lime = Color(red: 0.72, green: 0.95, blue: 0.21)
    static let limeDeep = Color(red: 0.55, green: 0.85, blue: 0.10)
    static let amber = Color(red: 1.00, green: 0.62, blue: 0.18)
    static let redLED = Color(red: 1.00, green: 0.30, blue: 0.28)
    static let label = Color.white.opacity(0.45)

    static func matrix(_ size: CGFloat) -> Font { .custom("Doto-Black", size: size) }

    static let limeGradient = LinearGradient(colors: [lime, limeDeep],
                                             startPoint: .top, endPoint: .bottom)
}

/// Faint dot-grid texture over the device body.
struct FDDotGrid: View {
    var body: some View {
        Canvas { ctx, size in
            let step: CGFloat = 8
            var y: CGFloat = 5
            while y < size.height {
                var x: CGFloat = 5
                while x < size.width {
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.6, height: 1.6)),
                             with: .color(.white.opacity(0.045)))
                    x += step
                }
                y += step
            }
        }
    }
}

/// The device card: charcoal gradient + dot grid + corner glow bleed + bevel highlight.
struct FDCard<Content: View>: View {
    var width: CGFloat? = nil
    var glow: Color = FD.lime
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(24)
            .frame(width: width)
            .background(
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(LinearGradient(colors: [FD.deviceHi, FD.device],
                                             startPoint: .top, endPoint: .bottom))
                    FDDotGrid()
                    Circle().fill(glow.opacity(0.22)).frame(width: 150, height: 150)
                        .blur(radius: 55).offset(x: -30, y: -40)
                }
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            )
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.06), lineWidth: 1))
            .overlay(alignment: .top) {
                LinearGradient(colors: [.white.opacity(0), .white.opacity(0.14), .white.opacity(0)],
                               startPoint: .leading, endPoint: .trailing)
                    .frame(height: 1).padding(.horizontal, 22)
            }
            .shadow(color: .black.opacity(0.6), radius: 34, y: 20)
            .preferredColorScheme(.dark)
    }
}

/// Inset sub-panel (fields, stat cells, banners).
struct FDInset<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.30)))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.white.opacity(0.05), lineWidth: 1))
    }
}

/// Matrix countdown with a clean custom separator (the Doto colon reads as plus signs).
struct MatrixTimer: View {
    let mm: String
    let ss: String
    var size: CGFloat = 40
    var color: Color = .white

    var body: some View {
        HStack(spacing: size * 0.16) {
            Text(mm).font(FD.matrix(size))
            VStack(spacing: size * 0.18) { dot; dot }
            Text(ss).font(FD.matrix(size))
        }
        .foregroundStyle(color)
    }

    private var dot: some View {
        RoundedRectangle(cornerRadius: 1.5).fill(color)
            .frame(width: size * 0.12, height: size * 0.12)
    }
}

/// Session progress pill: % appears from 10%; burns lime → amber (70%) → red (85%) to the end.
struct FDProgress: View {
    let fraction: CGFloat
    var width: CGFloat

    private func mix(_ a: (Double, Double, Double), _ b: (Double, Double, Double), _ t: Double) -> Color {
        Color(red: a.0 + (b.0 - a.0) * t, green: a.1 + (b.1 - a.1) * t, blue: a.2 + (b.2 - a.2) * t)
    }

    private var barColor: Color {
        // Session progress wears the ORB's green (#29EB8C, = Palette.green) — one green
        // across orb/aura/progress (user feedback), burning to amber @70% and red @85%.
        let green = (0.16, 0.92, 0.55), amber = (1.0, 0.62, 0.18), red = (1.0, 0.30, 0.28)
        if fraction < 0.70 { return mix(green, green, 0) }
        if fraction < 0.85 { return mix(green, amber, Double((fraction - 0.70) / 0.15)) }
        return mix(amber, red, Double(min(1, (fraction - 0.85) / 0.15)))
    }

    var body: some View {
        let color = barColor
        ZStack(alignment: .leading) {
            Capsule().fill(Color.black.opacity(0.35))
            Capsule()
                .fill(LinearGradient(colors: [color, color.opacity(0.75)],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: max(52, fraction * width))
                .overlay(alignment: .trailing) {
                    HStack(spacing: 8) {
                        if fraction >= 0.10 {
                            Text("\(Int(fraction * 100))%")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundStyle(.black.opacity(0.75))
                        }
                        Image(systemName: "circle.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.black.opacity(0.8))
                    }
                    .padding(.trailing, 12)
                }
                .shadow(color: color.opacity(0.8), radius: 12)
                .shadow(color: color.opacity(0.45), radius: 30)
        }
        .frame(width: width, height: 42)
    }
}

/// Pixel-art badge icon (dot-matrix world: achievements are pixels).
struct PixelIcon: View {
    let pattern: [String]
    var color: Color = FD.amber
    var pixel: CGFloat = 2.6

    var body: some View {
        Canvas { ctx, _ in
            for (y, row) in pattern.enumerated() {
                for (x, ch) in Array(row).enumerated() where ch == "X" {
                    ctx.fill(Path(CGRect(x: CGFloat(x) * pixel, y: CGFloat(y) * pixel,
                                         width: pixel - 0.4, height: pixel - 0.4)),
                             with: .color(color))
                }
            }
        }
        .frame(width: pixel * CGFloat(pattern.first?.count ?? 0),
               height: pixel * CGFloat(pattern.count))
    }

    static let flame = ["...X...", "..XX...", "..XXX..", ".XXXXX.", "XXXXXXX", "XX.XXXX", ".XXXXX.", "..XXX.."]
    static let bolt  = ["...XX..", "..XXX..", ".XXX...", "XXXXXX.", "...XXX.", "..XXX..", ".XXX...", ".XX...."]
    static let star  = ["...X...", "..XXX..", "XXXXXXX", ".XXXXX.", "..XXX..", ".XX.XX.", "XX...XX", "......."]
    static let skull = [".XXXXX.", "XXXXXXX", "XX.X.XX", "XXXXXXX", ".XXXXX.", ".X.X.X.", ".XXXXX.", "......."]
    static let sun   = ["X..X..X", ".XXXXX.", "XXXXXXX", ".XXXXX.", "X..X..X", "...X...", ".......", "......."]
    static let moon  = ["..XXX..", ".XX....", "XX.....", "XX.....", "XX.....", ".XX....", "..XXX..", "......."]
    static let target = ["..XXX..", ".X...X.", "X..X..X", "X.XXX.X", "X..X..X", ".X...X.", "..XXX..", "......."]

    static func pattern(named name: String) -> [String] {
        switch name {
        case "flame": return flame
        case "bolt": return bolt
        case "star": return star
        case "skull": return skull
        case "sun": return sun
        case "moon": return moon
        case "target": return target
        default: return star
        }
    }
}

/// Achievement badge chip: pixel icon + short caps label.
struct FDBadge: View {
    let icon: [String]
    let label: String
    var color: Color = FD.amber

    var body: some View {
        FDInset {
            HStack(spacing: 8) {
                PixelIcon(pattern: icon, color: color)
                Text(label).font(.system(size: 10, weight: .bold)).tracking(0.8)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }
}

/// Primary lime CTA — exactly one per screen.
struct FDPrimaryButton: View {
    let title: String
    var fullWidth = false
    var disabled = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .heavy)).tracking(0.5)
                .foregroundStyle(disabled ? FD.label : .black)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .padding(.horizontal, 22).padding(.vertical, 12)
                .background(
                    Group {
                        if disabled { Capsule().fill(Color.black.opacity(0.30)) }
                        else { Capsule().fill(FD.limeGradient) }
                    }
                )
                .shadow(color: disabled ? .clear : FD.lime.opacity(0.8), radius: 14)
                .shadow(color: disabled ? .clear : FD.lime.opacity(0.4), radius: 34)
        }
        .buttonStyle(HFPressStyle())
        .disabled(disabled)
    }
}

/// Quiet secondary; destructive tints red.
struct FDGhostButton: View {
    let title: String
    var destructive = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(destructive ? FD.redLED : FD.label)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Capsule().fill(destructive ? FD.redLED.opacity(0.12) : Color.black.opacity(0.30)))
        }
        .buttonStyle(HFPressStyle())
    }
}

/// Duration/selection chip: hot = lime gradient + glow.
struct FDChip: View {
    let label: String
    let selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label).font(.system(size: 12, weight: .bold))
                .foregroundStyle(selected ? .black : FD.label)
                .padding(.horizontal, 14)
                .frame(height: 32)
                .background(
                    Group {
                        if selected { Capsule().fill(FD.limeGradient) }
                        else { Capsule().fill(Color.black.opacity(0.30)) }
                    }
                )
                .shadow(color: selected ? FD.lime.opacity(0.7) : .clear, radius: 10)
        }
        .buttonStyle(HFPressStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: selected)
    }
}

/// Circular quiet close button (X) for card corners.
struct FDCloseButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(FD.label)
                .padding(8)
                .background(Circle().fill(Color.black.opacity(0.35)))
        }
        .buttonStyle(HFPressStyle())
    }
}
