# 07 — Hyperfocus Design System «NEON VOID»

> Visual language for the whole app. Premium dark sci-fi: deep void glass, one neon energy accent,
> display-grade numerals. ADHD principle: high signal contrast, zero visual noise — the interface
> is calm, the ENERGY (accent) marks exactly one thing per screen: the next action or the state.
> Implementation: `Hyperfocus/UI/DesignSystem.swift` (`HF` namespace). Canon #29.

## 1. Design tokens

### 1.1 Colors

| Token | Value | Use |
|---|---|---|
| `HF.void` | `#0B0E14` | window/card base, snapshot backgrounds |
| `HF.glass` | ultraThinMaterial + void 55% | card body (always dark, wallpaper-proof) |
| `HF.green` | `#29EB8C` | THE accent: energy, focus, primary actions |
| `HF.teal` | `#3DE6E0` | gradient partner of green (CTA gradient end) |
| `HF.amber` | `#FFB83B` | warning state only |
| `HF.red` | `#FF5C5C` | away/danger/destructive only |
| `HF.textPrimary` | white 95% | titles, values |
| `HF.textSecondary` | white 60% | body, descriptions |
| `HF.textTertiary` | white 38% | placeholders, captions, caps-labels |
| `HF.hairline` | white 8% | card border (1 pt, barely-there) |
| `HF.fieldBG` | white 5.5% | inputs |
| `HF.ghostBG` | white 7% | secondary buttons, unselected chips |
| `HF.accentGradient` | green → teal, horizontal | primary CTA, selected chips |

Rules: one gradient CTA per screen, never two. Amber/red never decorate — only signal state.

### 1.2 Typography

| Style | Font | Size/Weight | Use |
|---|---|---|---|
| `display28/22/17` | SF Pro **Rounded** Bold | 28/22/17 | screen titles, card titles |
| `body15/13` | SF Pro | 15/13 regular | inputs (15), body text (13) |
| `caption12/11` | SF Pro | 12/11 | secondary meta |
| `caps11` | SF Pro Semibold 11, tracking +1.5, UPPERCASE | section labels: TIME, INTENSITY, MISSION |
| `data` | **DSEG7 Classic Bold** | 14–34 + glow shadow | timers & stats ONLY (never words) |
| `dataXL` | **DSEG14 Classic Bold** | 96–128 | countdown 3·2·1·FOCUS |

Rounded for feelings, straight for reading, segments for numbers — never mixed roles.

### 1.3 Spacing / radius / elevation

- Spacing scale: 4·8·12·16·20·24·32. Card padding **24**; control row gap 8; section gap 20.
- Radius: card **24** continuous; controls/fields **12**; chips = capsule.
- Elevation: card = shadow black 50% r30 y18 **+ ambient accent glow** (accent 10%, r40).
- Signature detail: **top edge-light** — 1.5 pt horizontal gradient line (accent) along each card's top edge. The card looks powered by the session state color.

### 1.4 Motion

| Token | Value | Use |
|---|---|---|
| `fast` | 0.15 easeOut | hover/press feedback |
| `standard` | 0.25 easeOut | state/color changes |
| `springChip` | spring(response 0.3, damping 0.75) | chips, toggles |
| `cardIn` | 0.3: opacity 0→1, scale 0.96→1, y +8→0 | card appearance |
| Press | scale 0.98 | all buttons |
Reduce-motion: no scale/slide, opacity-only.

## 2. Components (`DesignSystem.swift`)

| Component | Spec |
|---|---|
| `HFCard(width:accent:)` | glass body + hairline + top edge-light (accent) + dual shadow |
| `HFPrimaryButton` | capsule, accentGradient fill, BLACK 14-semibold text, green glow r14; disabled = ghostBG + tertiary text, no glow |
| `HFGhostButton` | capsule, ghostBG fill, primary text; destructive variant = red 12% fill + red text |
| `HFChip` | capsule; selected = accentGradient + black text + glow; unselected = ghostBG, NO border |
| `HFCapsLabel` | caps11 tertiary |
| `HFField` | fieldBG, radius 12, body15, focus = 1 pt green 50% ring + soft outer glow |
| `HFStatCell` | mini-card white 4%, radius 12: caps label + DSEG value (accent-tinted) |
| `HFStatusPill` | capsule ghostBG: 8 pt state dot + caption12 |

## 3. Screens (all of them)

| Screen | Layout | Accent |
|---|---|---|
| **Prepare Hyperfocus** | 360 w. Header: mini-orb glyph + display22 + caption. MISSION caps → field15; success field13. TIME caps → chips 5/15/25/45/Custom. INTENSITY caps → 3 icon-chips (water.waves Calm / bolt.fill Strict / sparkles Cinematic). Footer: ghost Cancel ←→ gradient CTA «Enter Hyperfocus» | green |
| **Active HUD** | 260 w compact: mission caption12 → DSEG 30 timer green+glow → HFStatusPill + ghost exit icon | green |
| **Away card** | red edge-light; title display20 red; body13; DSEG paused time red; Return = gradient CTA, Exit Session = ghost destructive | red |
| **Exit confirm** | red edge-light; display17; Stay = gradient CTA, Exit = ghost destructive | red |
| **Completion** | green edge-light; «Mission complete» display22; hero: DSEG 34 focus time centered + glow; 2×2 `HFStatCell` grid (Paused/Breaks/Streak/Planned); question body13; Done = gradient, Partial = amber ghost, Not done = red ghost; Next action field | green |
| **Quick-start chips** | HFChip visuals (hot = gradient+glow) | green |
| **Countdown** | unchanged concept: DSEG14 dataXL + glow; intro line display28 | green |
| **Settings** | grouped Form kept, but section headers = caps11, accent switch/slider tint = HF.green | green |
| **Onboarding** | HFCard-less full-void window; same type scale; CTA = HFPrimaryButton; step dots green | green |
| **History** | rows: mission body13 + DSEG12 duration + HFStatusPill status | green |
| **Permission nudge** | HFCard with amber edge-light | amber |

## 4. Do / Don't

| ✅ | ❌ |
|---|---|
| One gradient CTA per screen | Two competing accents |
| Caps-labels for sections | Full sentences as labels |
| DSEG for numbers only | DSEG for words |
| Edge-light shows session state | Colored borders around whole cards |
| Ghost buttons for secondary | System-gray default buttons (the old Cancel) |
