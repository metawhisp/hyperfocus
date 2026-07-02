// DesignPreviews.swift — DEBUG-only NEON VOID redesign previews (HF_DESIGN_PREVIEW=1).
// Static mockups of the four key screens with the new design system — production views stay
// untouched until the user approves (preview-before-prod rule).

#if DEBUG
import SwiftUI
import AppKit

// MARK: Prepare Hyperfocus v2 (the screen the user called ugly)

private struct StartCardV2Mock: View {
    var body: some View {
        HFCard(width: 360, accent: HF.green) {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    RingToParticlesOrb(t: 1.4, progress: 1, diameter: 26, brightness: 2.2)
                        .frame(width: 34, height: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Prepare Hyperfocus").font(HF.display(22)).foregroundStyle(HF.textPrimary)
                        Text("One task. One session.").font(HF.body(12)).foregroundStyle(HF.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HFCapsLabel(text: "Mission")
                    mockField("Write the report intro", filled: true, tall: true)
                    mockField("This session is successful if…", filled: false, tall: false)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HFCapsLabel(text: "Time")
                    HStack(spacing: 8) {
                        HFChip(label: "5", selected: false) {}
                        HFChip(label: "15", selected: false) {}
                        HFChip(label: "25", selected: true) {}
                        HFChip(label: "45", selected: false) {}
                        HFChip(label: "Custom", selected: false) {}
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HFCapsLabel(text: "Intensity")
                    HStack(spacing: 8) {
                        HFChip(label: "Calm", icon: "water.waves", selected: false) {}
                        HFChip(label: "Strict", icon: "bolt.fill", selected: false) {}
                        HFChip(label: "Cinematic", icon: "sparkles", selected: true) {}
                    }
                }

                HStack {
                    HFGhostButton(title: "Cancel") {}
                    Spacer()
                    HFPrimaryButton(title: "Enter Hyperfocus") {}
                }
            }
        }
    }

    private func mockField(_ text: String, filled: Bool, tall: Bool) -> some View {
        HStack {
            Text(text)
                .font(HF.body(tall ? 15 : 13))
                .foregroundStyle(filled ? HF.textPrimary : HF.textTertiary)
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, tall ? 12 : 9)
        .background(RoundedRectangle(cornerRadius: HF.rControl).fill(HF.fieldBG))
        .overlay(
            RoundedRectangle(cornerRadius: HF.rControl)
                .strokeBorder(filled ? HF.green.opacity(0.45) : .clear, lineWidth: 1)
        )
        .shadow(color: filled ? HF.green.opacity(0.15) : .clear, radius: 8)
    }
}

// MARK: Active HUD v2

private struct HUDV2Mock: View {
    var body: some View {
        HFCard(width: 250, accent: HF.green) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Write the report intro").font(HF.body(12)).foregroundStyle(HF.textSecondary)
                    .lineLimit(1)
                Text("18:42")
                    .font(SegFont.seg7(30))
                    .foregroundStyle(HF.green)
                    .shadow(color: HF.green.opacity(0.6), radius: 8)
                HStack {
                    HFStatusPill(label: "Present", color: HF.green)
                    Spacer()
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(HF.textTertiary)
                        .padding(7)
                        .background(Circle().fill(HF.ghostBG))
                }
            }
        }
    }
}

// MARK: Away card v2

private struct AwayV2Mock: View {
    var body: some View {
        HFCard(width: 300, accent: HF.red) {
            VStack(spacing: 14) {
                Text("Session paused").font(HF.display(20)).foregroundStyle(HF.red)
                Text("Return to Hyperfocus or exit the session.")
                    .font(HF.body(13)).foregroundStyle(HF.textSecondary)
                    .multilineTextAlignment(.center)
                Text("12:07")
                    .font(SegFont.seg7(22))
                    .foregroundStyle(HF.red)
                    .shadow(color: HF.red.opacity(0.6), radius: 7)
                HStack(spacing: 10) {
                    HFGhostButton(title: "Exit Session", destructive: true) {}
                    HFPrimaryButton(title: "Return") {}
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: Completion v2

private struct CompletionV2Mock: View {
    var body: some View {
        HFCard(width: 340, accent: HF.green) {
            VStack(spacing: 18) {
                Text("Mission complete").font(HF.display(22)).foregroundStyle(HF.textPrimary)
                VStack(spacing: 4) {
                    Text("25:00")
                        .font(SegFont.seg7(34))
                        .foregroundStyle(HF.green)
                        .shadow(color: HF.green.opacity(0.6), radius: 10)
                    HFCapsLabel(text: "Focus time")
                }
                HStack(spacing: 8) {
                    HFStatCell(label: "Paused", value: "01:36")
                    HFStatCell(label: "Breaks", value: "2")
                }
                HStack(spacing: 8) {
                    HFStatCell(label: "Streak", value: "10:15")
                    HFStatCell(label: "Planned", value: "25:00")
                }
                Text("Did you complete the mission?")
                    .font(HF.body(13)).foregroundStyle(HF.textSecondary)
                HStack(spacing: 8) {
                    HFPrimaryButton(title: "Done") {}
                    HFGhostButton(title: "Partial") {}
                    HFGhostButton(title: "Not done", destructive: true) {}
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: — Variant B «FLIGHT DECK» (hardware-gadget: dot-matrix display, dot-grid device, lime glow)

private enum FD {
    static let device = Color(red: 0.075, green: 0.082, blue: 0.095)
    static let deviceHi = Color(red: 0.115, green: 0.125, blue: 0.140)
    static let lime = Color(red: 0.72, green: 0.95, blue: 0.21)
    static let limeDeep = Color(red: 0.55, green: 0.85, blue: 0.10)
    static let amber = Color(red: 1.00, green: 0.62, blue: 0.18)
    static let redLED = Color(red: 1.00, green: 0.30, blue: 0.28)
    static let label = Color.white.opacity(0.45)
    static func matrix(_ s: CGFloat) -> Font { .custom("Doto-Black", size: s) }
}

private struct FDDotGrid: View {
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

private struct FDCard<Content: View>: View {
    var width: CGFloat
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

/// Lime glowing progress pill with the orb at its tip (the reference's plane bar → session progress).
private struct FDProgress: View {
    let fraction: CGFloat
    let trailing: String
    var width: CGFloat

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Color.black.opacity(0.35))
                .overlay(alignment: .trailing) {
                    Text(trailing).font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(FD.label).padding(.trailing, 16)
                }
            Capsule()
                .fill(LinearGradient(colors: [FD.lime, FD.limeDeep],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: max(52, fraction * width))
                .overlay(alignment: .trailing) {
                    Image(systemName: "circle.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.black.opacity(0.8))
                        .padding(.trailing, 12)
                }
                .shadow(color: FD.lime.opacity(0.8), radius: 12)
                .shadow(color: FD.lime.opacity(0.45), radius: 30)
        }
        .frame(width: width, height: 42)
    }
}

private struct FDInset<Content: View>: View {
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

/// Matrix timer with a clean custom separator (the Doto colon reads as "plus signs").
private struct MatrixTimer: View {
    let mm: String
    let ss: String
    var size: CGFloat = 40
    var color: Color = .white

    var body: some View {
        HStack(spacing: size * 0.16) {
            Text(mm).font(FD.matrix(size))
            VStack(spacing: size * 0.18) {
                dot; dot
            }
            Text(ss).font(FD.matrix(size))
        }
        .foregroundStyle(color)
    }

    private var dot: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(color)
            .frame(width: size * 0.12, height: size * 0.12)
    }
}

/// Progress pill v2: % appears from 10%; the bar burns lime → amber → red over the last 30%.
private struct FDProgressV2: View {
    let fraction: CGFloat
    var width: CGFloat

    private func mix(_ a: (Double, Double, Double), _ b: (Double, Double, Double), _ t: Double) -> Color {
        Color(red: a.0 + (b.0 - a.0) * t, green: a.1 + (b.1 - a.1) * t, blue: a.2 + (b.2 - a.2) * t)
    }

    private var barColor: Color {
        let lime = (0.72, 0.95, 0.21), amber = (1.0, 0.62, 0.18), red = (1.0, 0.30, 0.28)
        if fraction < 0.70 { return mix(lime, lime, 0) }
        if fraction < 0.85 { return mix(lime, amber, Double((fraction - 0.70) / 0.15)) }
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

private struct FDHUDMock: View {
    var fraction: CGFloat = 0.32
    var mm = "09"
    var ss = "58"

    var body: some View {
        FDCard(width: 400) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        MatrixTimer(mm: mm, ss: ss, size: 40)
                        Text("Write the report intro")
                            .font(.system(size: 13)).foregroundStyle(FD.label).lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(FD.label)
                        .padding(8)
                        .background(Circle().fill(Color.black.opacity(0.35)))
                }
                FDProgressV2(fraction: fraction, width: 352)
            }
        }
    }
}

/// Pixel-art badge icon (dot-matrix world: achievements are pixels too).
private struct PixelIcon: View {
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
}

private struct FDBadge: View {
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

/// Exit confirm v2: no pause exists — only STOP, and stopping counts as Not done. Pulses red live.
private struct FDStopMock: View {
    var body: some View {
        FDCard(width: 360, glow: FD.redLED) {
            VStack(spacing: 14) {
                Text("STOP HYPERFOCUS?").font(FD.matrix(26)).foregroundStyle(FD.redLED)
                    .shadow(color: FD.redLED.opacity(0.7), radius: 12)
                Text("(рамка и заголовок пульсируют)")
                    .font(.system(size: 10)).foregroundStyle(FD.label)
                HStack(spacing: 8) {
                    PixelIcon(pattern: PixelIcon.skull, color: FD.redLED)
                    Text("STOPPING COUNTS AS NOT DONE")
                        .font(.system(size: 11, weight: .bold)).tracking(1)
                        .foregroundStyle(FD.amber)
                }
                HStack(spacing: 10) {
                    Text("Stop").font(.system(size: 13, weight: .medium))
                        .foregroundStyle(FD.redLED)
                        .padding(.horizontal, 18).padding(.vertical, 10)
                        .background(Capsule().fill(FD.redLED.opacity(0.12)))
                    Text("KEEP GOING")
                        .font(.system(size: 13, weight: .heavy)).foregroundStyle(.black)
                        .padding(.horizontal, 24).padding(.vertical, 10)
                        .background(Capsule().fill(LinearGradient(colors: [FD.lime, FD.limeDeep],
                                                                  startPoint: .top, endPoint: .bottom)))
                        .shadow(color: FD.lime.opacity(0.8), radius: 12)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct FDStartMock: View {
    var body: some View {
        FDCard(width: 380) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    Text("READY?").font(FD.matrix(30)).foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(FD.label)
                        .padding(7)
                        .background(Circle().fill(Color.black.opacity(0.35)))
                }

                // Mission input with the magic wand inside, right edge: tap → the mission is
                // generated from the local screen context (frontmost window).
                FDInset {
                    HStack {
                        Text("Write the report intro")
                            .font(.system(size: 14)).foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(FD.lime)
                            .shadow(color: FD.lime.opacity(0.7), radius: 6)
                    }.frame(width: 300)
                }

                HStack(spacing: 8) {
                    ForEach(["5", "15", "25", "45", "CUSTOM"], id: \.self) { m in
                        let hot = m == "25"
                        Text(m).font(.system(size: 12, weight: .bold))
                            .foregroundStyle(hot ? .black : FD.label)
                            .padding(.horizontal, m == "CUSTOM" ? 14 : 0)
                            .frame(minWidth: m == "CUSTOM" ? 0 : 46)
                            .frame(height: 32)
                            .background(Capsule().fill(hot ?
                                AnyShapeStyle(LinearGradient(colors: [FD.lime, FD.limeDeep],
                                                             startPoint: .top, endPoint: .bottom)) :
                                AnyShapeStyle(Color.black.opacity(0.30))))
                            .shadow(color: hot ? FD.lime.opacity(0.7) : .clear, radius: 10)
                    }
                }

                Text("ENTER HYPERFOCUS")
                    .font(.system(size: 13, weight: .heavy)).tracking(0.5)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Capsule().fill(LinearGradient(colors: [FD.lime, FD.limeDeep],
                                                              startPoint: .top, endPoint: .bottom)))
                    .shadow(color: FD.lime.opacity(0.8), radius: 14)
                    .shadow(color: FD.lime.opacity(0.4), radius: 34)
            }
        }
    }
}

private struct FDAwayMock: View {
    var body: some View {
        FDCard(width: 340, glow: FD.redLED) {
            VStack(spacing: 12) {
                Text("PAUSED").font(FD.matrix(34)).foregroundStyle(FD.redLED)
                    .shadow(color: FD.redLED.opacity(0.6), radius: 10)
                Text("RETURN TO HYPERFOCUS OR EXIT")
                    .font(.system(size: 11, weight: .bold)).tracking(1.2)
                    .foregroundStyle(FD.amber)
                Text("away 00:12").font(.system(size: 12)).foregroundStyle(FD.label)
                HStack(spacing: 10) {
                    Text("Exit Session").font(.system(size: 13, weight: .medium))
                        .foregroundStyle(FD.redLED)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Capsule().fill(FD.redLED.opacity(0.12)))
                    Text("RETURN")
                        .font(.system(size: 13, weight: .heavy)).foregroundStyle(.black)
                        .padding(.horizontal, 24).padding(.vertical, 10)
                        .background(Capsule().fill(LinearGradient(colors: [FD.lime, FD.limeDeep],
                                                                  startPoint: .top, endPoint: .bottom)))
                        .shadow(color: FD.lime.opacity(0.8), radius: 12)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

/// Completion v2: reaching zero IS Done — no question. Celebration: bonus + achievements row.
private struct FDCompletionMock: View {
    var body: some View {
        FDCard(width: 380) {
            VStack(spacing: 14) {
                Text("HYPERFOCUS COMPLETE")
                    .font(.system(size: 11, weight: .bold)).tracking(2)
                    .foregroundStyle(FD.amber)
                MatrixTimer(mm: "15", ss: "00", size: 44, color: FD.lime)
                    .shadow(color: FD.lime.opacity(0.7), radius: 14)
                Text("FOCUS TIME").font(.system(size: 10, weight: .semibold)).tracking(1.5)
                    .foregroundStyle(FD.label)

                // Freshly unlocked achievement — the reward moment.
                FDInset {
                    HStack(spacing: 10) {
                        PixelIcon(pattern: PixelIcon.bolt, color: FD.lime)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("NEW ACHIEVEMENT").font(.system(size: 8, weight: .bold)).tracking(1.5)
                                .foregroundStyle(FD.label)
                            Text("LASER MIND — zero drifts")
                                .font(.system(size: 12, weight: .bold)).foregroundStyle(FD.lime)
                        }
                    }
                }

                // Earned badges line up in a row.
                HStack(spacing: 6) {
                    FDBadge(icon: PixelIcon.flame, label: "×3", color: FD.amber)
                    FDBadge(icon: PixelIcon.star, label: "TODAY ×2", color: FD.lime)
                    FDBadge(icon: PixelIcon.bolt, label: "FIRST 15M", color: FD.redLED)
                }

                // The timer is done — but did the MISSION get done? We can't know; ask.
                Text("Did you complete the mission?")
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.75))
                HStack(spacing: 8) {
                    Text("DONE")
                        .font(.system(size: 13, weight: .heavy)).foregroundStyle(.black)
                        .padding(.horizontal, 22).padding(.vertical, 10)
                        .background(Capsule().fill(LinearGradient(colors: [FD.lime, FD.limeDeep],
                                                                  startPoint: .top, endPoint: .bottom)))
                        .shadow(color: FD.lime.opacity(0.8), radius: 12)
                    Text("Partial").font(.system(size: 12, weight: .medium)).foregroundStyle(FD.amber)
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(Capsule().fill(FD.amber.opacity(0.12)))
                    Text("Not done").font(.system(size: 12, weight: .medium)).foregroundStyle(FD.redLED)
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(Capsule().fill(FD.redLED.opacity(0.12)))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct DesignPreviewGalleryBView: View {
    var body: some View {
        VStack(spacing: 26) {
            Text("FLIGHT DECK v2 — организация экранов по фидбеку")
                .font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.8))
            HStack(alignment: .top, spacing: 26) {
                FDStartMock()
                VStack(spacing: 22) {
                    FDHUDMock(fraction: 0.32, mm: "09", ss: "58")
                    FDStopMock()
                }
                FDCompletionMock()
            }
            VStack(spacing: 8) {
                Text("Прогресс догорает: зелёный → жёлтый (70%) → красный (85%) → конец")
                    .font(.system(size: 11)).foregroundStyle(.white.opacity(0.6))
                HStack(spacing: 16) {
                    FDProgressV2(fraction: 0.45, width: 250)
                    FDProgressV2(fraction: 0.78, width: 250)
                    FDProgressV2(fraction: 0.94, width: 250)
                }
            }
        }
        .padding(36)
        .background(Color(red: 0.03, green: 0.04, blue: 0.06))
    }
}

// MARK: Gallery

struct DesignPreviewGalleryView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("NEON VOID — редизайн ключевых экранов (specs/07)")
                .font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.8))
            HStack(alignment: .top, spacing: 28) {
                StartCardV2Mock()
                VStack(spacing: 24) {
                    HUDV2Mock()
                    AwayV2Mock()
                }
                CompletionV2Mock()
            }
        }
        .padding(36)
        .background(Color(red: 0.03, green: 0.04, blue: 0.06))
    }
}

@MainActor
enum DesignPreviewRenderer {
    static func render() {
        write(DesignPreviewGalleryView(), name: "design_preview.png")
        write(DesignPreviewGalleryBView(), name: "design_preview_b.png")
    }

    private static func write(_ view: some View, name: String) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
        guard let image = renderer.nsImage, let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            NSLog("Hyperfocus: design preview render failed for \(name)"); return
        }
        try? png.write(to: dir.appendingPathComponent(name))
        NSLog("Hyperfocus: design preview written to \(dir.path)/\(name)")
    }
}
#endif
