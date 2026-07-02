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
