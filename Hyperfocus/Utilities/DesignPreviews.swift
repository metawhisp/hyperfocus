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
        let renderer = ImageRenderer(content: DesignPreviewGalleryView())
        renderer.scale = 2
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
        guard let image = renderer.nsImage, let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            NSLog("Hyperfocus: design preview render failed"); return
        }
        try? png.write(to: dir.appendingPathComponent("design_preview.png"))
        NSLog("Hyperfocus: design preview written to \(dir.path)")
    }
}
#endif
