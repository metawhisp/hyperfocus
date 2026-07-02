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

private struct FDHUDMock: View {
    var fraction: CGFloat = 0.32
    var mm = "09"
    var ss = "58"

    var body: some View {
        FDCard(width: 400) {
            VStack(spacing: 16) {
                // Countdown + mission — centered; the close button stays pinned to the corner.
                VStack(spacing: 6) {
                    MatrixTimer(mm: mm, ss: ss, size: 40)
                    Text("Write the report intro")
                        .font(.system(size: 13)).foregroundStyle(FD.label).lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                FDProgress(fraction: fraction, width: 352)
            }
            .overlay(alignment: .topTrailing) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(FD.label)
                    .padding(8)
                    .background(Circle().fill(Color.black.opacity(0.35)))
                    .offset(x: 8, y: -8)
            }
        }
    }
}

/// Pixel-art badge icon (dot-matrix world: achievements are pixels too).

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
                    FDProgress(fraction: 0.45, width: 250)
                    FDProgress(fraction: 0.78, width: 250)
                    FDProgress(fraction: 0.94, width: 250)
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

// MARK: — FLIGHT DECK onboarding storyboard (all 5 steps)

private struct FDOnbCard<Content: View>: View {
    let step: Int
    @ViewBuilder var content: Content
    var body: some View {
        FDCard(width: 340) {
            VStack(spacing: 14) {
                content
                HStack(spacing: 6) {
                    ForEach(0..<5, id: \.self) { i in
                        Circle().fill(i == step ? FD.lime : Color.white.opacity(0.15))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, minHeight: 300)
        }
    }
}

private struct FDOnbStep1: View {
    var body: some View {
        FDOnbCard(step: 0) {
            Text("FOCUS ORB").font(FD.matrix(24)).foregroundStyle(.white)
            Text("It lives in the corner of your screen.\nOne click starts a session.")
                .font(.system(size: 12)).foregroundStyle(FD.label)
                .multilineTextAlignment(.center)
            RingToParticlesOrb(t: 1.4, progress: 0, diameter: 56, brightness: 3.0)
                .frame(width: 120, height: 110)
            Text("CLICK THE ORB TO CONTINUE")
                .font(.system(size: 11, weight: .bold)).tracking(1.2)
                .foregroundStyle(FD.lime)
        }
    }
}

private struct FDOnbStep2: View {
    var body: some View {
        FDOnbCard(step: 1) {
            Text("ONE TASK").font(FD.matrix(24)).foregroundStyle(.white)
            Text("What will you focus on first?")
                .font(.system(size: 12)).foregroundStyle(FD.label)
            FDInset {
                HStack {
                    Text("Write the report intro").font(.system(size: 13)).foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(FD.lime)
                        .shadow(color: FD.lime.opacity(0.7), radius: 6)
                }.frame(width: 240)
            }
            HStack(spacing: 8) {
                FDChip(label: "5", selected: false) {}
                FDChip(label: "15", selected: true) {}
                FDChip(label: "25", selected: false) {}
            }
            Text("Small first session — an easy win.")
                .font(.system(size: 10)).foregroundStyle(FD.label)
            FDPrimaryButton(title: "NEXT") {}
        }
    }
}

private struct FDOnbStep3: View {
    var body: some View {
        FDOnbCard(step: 2) {
            PixelIcon(pattern: PixelIcon.target, color: FD.lime, pixel: 3.4)
            Text("IT SEES YOU DRIFT").font(FD.matrix(20)).foregroundStyle(.white)
            Text("Leave your Mac and the timer pauses —\na gentle sound calls you back.")
                .font(.system(size: 12)).foregroundStyle(FD.label)
                .multilineTextAlignment(.center)
            Text("CAMERA REQUIRED FOR THE FULL EXPERIENCE")
                .font(.system(size: 9, weight: .bold)).tracking(1.2)
                .foregroundStyle(FD.amber)
            Text("Frames never leave your Mac. No recording, no upload.")
                .font(.system(size: 10)).foregroundStyle(FD.label)
            HStack(spacing: 8) {
                FDGhostButton(title: "Not now") {}
                FDPrimaryButton(title: "ENABLE CAMERA") {}
            }
        }
    }
}

private struct FDOnbStep4: View {
    var body: some View {
        FDOnbCard(step: 3) {
            PixelIcon(pattern: PixelIcon.bolt, color: FD.amber, pixel: 3.4)
            Text("DISTRACTION RADAR").font(FD.matrix(20)).foregroundStyle(.white)
            Text("Spots YouTube or a feed on your screen\nand nudges you back to the task.")
                .font(.system(size: 12)).foregroundStyle(FD.label)
                .multilineTextAlignment(.center)
            Text("Analyzed locally. Never stored, never sent.")
                .font(.system(size: 10)).foregroundStyle(FD.label)
            HStack(spacing: 8) {
                FDGhostButton(title: "Not now") {}
                FDPrimaryButton(title: "ENABLE SCREEN ACCESS") {}
            }
        }
    }
}

private struct FDOnbStep5: View {
    var body: some View {
        FDOnbCard(step: 4) {
            Text("YOU'RE SET").font(FD.matrix(24)).foregroundStyle(.white)
            FDInset {
                VStack(alignment: .leading, spacing: 9) {
                    gesture("cursorarrow.click", "CLICK", "start a session")
                    gesture("hand.tap.fill", "HOLD", "quick start — recent durations")
                    gesture("filemenu.and.cursorarrow", "RIGHT-CLICK", "stop, settings")
                }.frame(width: 240)
            }
            FDPrimaryButton(title: "START FIRST SESSION — 15 MIN", fullWidth: true) {}
            Text("I'll start later").font(.system(size: 10)).foregroundStyle(FD.label)
        }
    }

    private func gesture(_ icon: String, _ name: String, _ detail: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon).font(.system(size: 12)).foregroundStyle(FD.lime).frame(width: 18)
            Text(name).font(.system(size: 11, weight: .bold)).tracking(0.8).foregroundStyle(.white)
            Text(detail).font(.system(size: 11)).foregroundStyle(FD.label)
        }
    }
}

struct FDOnboardingStoryboardView: View {
    var body: some View {
        VStack(spacing: 18) {
            Text("FLIGHT DECK — раскадровка онбординга (5 шагов)")
                .font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.8))
            HStack(alignment: .top, spacing: 18) {
                FDOnbStep1(); FDOnbStep2(); FDOnbStep3()
            }
            HStack(alignment: .top, spacing: 18) {
                FDOnbStep4(); FDOnbStep5()
            }
        }
        .padding(32)
        .background(Color(red: 0.03, green: 0.04, blue: 0.06))
    }
}

@MainActor
enum DesignPreviewRenderer {
    static func render() {
        write(DesignPreviewGalleryView(), name: "design_preview.png")
        write(DesignPreviewGalleryBView(), name: "design_preview_b.png")
        write(FDOnboardingStoryboardView(), name: "design_preview_onboarding.png")
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
