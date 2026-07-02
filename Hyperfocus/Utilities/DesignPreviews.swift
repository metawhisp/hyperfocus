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

private struct FDHUDMock: View {
    var body: some View {
        FDCard(width: 400) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("18:42").font(FD.matrix(40)).foregroundStyle(.white)
                        Text("Write the report intro")
                            .font(.system(size: 13)).foregroundStyle(FD.label).lineLimit(1)
                    }
                    Spacer()
                    FDInset {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("ENDS 15:04").font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                            Text("Session time").font(.system(size: 11)).foregroundStyle(FD.label)
                            Text("STREAK 10:15").font(.system(size: 11, weight: .bold))
                                .foregroundStyle(FD.amber)
                        }
                    }
                }
                FDProgress(fraction: 0.62, trailing: "-06:18", width: 352)
            }
        }
    }
}

private struct FDStartMock: View {
    var body: some View {
        FDCard(width: 380) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("PREPARE").font(.system(size: 11, weight: .bold)).tracking(2)
                        .foregroundStyle(FD.amber)
                    Spacer()
                    RingToParticlesOrb(t: 1.4, progress: 0, diameter: 22, brightness: 2.5)
                        .frame(width: 30, height: 30)
                }
                Text("HYPERFOCUS").font(FD.matrix(30)).foregroundStyle(.white)

                FDInset {
                    HStack {
                        Text("Write the report intro")
                            .font(.system(size: 14)).foregroundStyle(.white)
                        Spacer()
                    }.frame(width: 300)
                }
                FDInset {
                    HStack {
                        Text("This session is successful if…")
                            .font(.system(size: 12)).foregroundStyle(FD.label)
                        Spacer()
                    }.frame(width: 300)
                }

                HStack(spacing: 8) {
                    ForEach(["5", "15", "25", "45", "∞"], id: \.self) { m in
                        let hot = m == "25"
                        Text(m).font(.system(size: 13, weight: .bold))
                            .foregroundStyle(hot ? .black : FD.label)
                            .frame(width: 46, height: 32)
                            .background(Capsule().fill(hot ?
                                AnyShapeStyle(LinearGradient(colors: [FD.lime, FD.limeDeep],
                                                             startPoint: .top, endPoint: .bottom)) :
                                AnyShapeStyle(Color.black.opacity(0.30))))
                            .shadow(color: hot ? FD.lime.opacity(0.7) : .clear, radius: 10)
                    }
                }

                HStack(spacing: 12) {
                    Text("Cancel").font(.system(size: 13, weight: .medium)).foregroundStyle(FD.label)
                    Spacer()
                    Text("ENTER HYPERFOCUS")
                        .font(.system(size: 13, weight: .heavy)).tracking(0.5)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 22).padding(.vertical, 12)
                        .background(Capsule().fill(LinearGradient(colors: [FD.lime, FD.limeDeep],
                                                                  startPoint: .top, endPoint: .bottom)))
                        .shadow(color: FD.lime.opacity(0.8), radius: 14)
                        .shadow(color: FD.lime.opacity(0.4), radius: 34)
                }
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

private struct FDCompletionMock: View {
    var body: some View {
        FDCard(width: 380) {
            VStack(spacing: 16) {
                Text("MISSION COMPLETE")
                    .font(.system(size: 11, weight: .bold)).tracking(2)
                    .foregroundStyle(FD.amber)
                Text("25:00").font(FD.matrix(44)).foregroundStyle(FD.lime)
                    .shadow(color: FD.lime.opacity(0.7), radius: 14)
                Text("FOCUS TIME").font(.system(size: 10, weight: .semibold)).tracking(1.5)
                    .foregroundStyle(FD.label)
                HStack(spacing: 8) {
                    statInset("PAUSED", "01:36")
                    statInset("BREAKS", "2")
                    statInset("STREAK", "10:15")
                }
                HStack(spacing: 10) {
                    Text("DONE")
                        .font(.system(size: 13, weight: .heavy)).foregroundStyle(.black)
                        .padding(.horizontal, 24).padding(.vertical, 10)
                        .background(Capsule().fill(LinearGradient(colors: [FD.lime, FD.limeDeep],
                                                                  startPoint: .top, endPoint: .bottom)))
                        .shadow(color: FD.lime.opacity(0.8), radius: 12)
                    Text("Partial").font(.system(size: 13, weight: .medium)).foregroundStyle(FD.amber)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Capsule().fill(FD.amber.opacity(0.12)))
                    Text("Not done").font(.system(size: 13, weight: .medium)).foregroundStyle(FD.redLED)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Capsule().fill(FD.redLED.opacity(0.12)))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func statInset(_ label: String, _ value: String) -> some View {
        FDInset {
            VStack(spacing: 3) {
                Text(label).font(.system(size: 9, weight: .semibold)).tracking(1.2)
                    .foregroundStyle(FD.label)
                Text(value).font(FD.matrix(16)).foregroundStyle(.white)
            }
            .frame(width: 80)
        }
    }
}

struct DesignPreviewGalleryBView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("FLIGHT DECK — вариант B (dot-matrix hardware, specs/07)")
                .font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.8))
            HStack(alignment: .top, spacing: 28) {
                FDStartMock()
                VStack(spacing: 24) {
                    FDHUDMock()
                    FDAwayMock()
                }
                FDCompletionMock()
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
