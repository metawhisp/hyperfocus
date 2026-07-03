// FocusOrbWindowController.swift — KeyablePanel hosting the orb: drag tracking, click detection, edge snapping (canon §3).
//
// The window is `orbWindowSize` (bigger than the coloured dot) so the glow isn't clipped. Persistence
// stores the DOT origin (OrbPositionStore, footprint = orbSize); this controller converts to a window
// origin and clamps the whole window on-screen so the orb is never half off the edge.

import AppKit
import SwiftUI

final class FocusOrbWindowController {
    // weak: AppState (strong) → coordinator → orb controller; a strong back-reference here would
    // close a retain cycle and leak any non-singleton AppState (previews/tests).
    private weak var app: AppState?
    private let positionStore: OrbPositionStore
    private let screen: ScreenManager

    var onClick: (() -> Void)?
    var onSecondaryClick: ((NSEvent) -> Void)?
    var onHoverChanged: ((Bool) -> Void)?
    /// Long-press quick-start (canon §13 #25): began returns whether quick-start was actually shown
    /// (false → the press falls through to a normal click on release); moved/ended carry the
    /// pointer's SCREEN coordinates while the button is still held.
    var onLongPressBegan: (() -> Bool)?
    var onLongPressMoved: ((NSPoint) -> Void)?
    var onLongPressEnded: ((NSPoint) -> Void)?

    private var panel: KeyablePanel?

    init(app: AppState, positionStore: OrbPositionStore, screen: ScreenManager) {
        self.app = app
        self.positionStore = positionStore
        self.screen = screen
    }

    var currentFrame: CGRect { panel?.frame ?? .zero }
    var isVisible: Bool { panel?.isVisible ?? false }
    var contentViewForMenu: NSView? { panel?.contentView }
    var windowNumber: Int? { panel?.windowNumber }
    #if DEBUG
    var debugPanel: NSPanel? { panel }
    #endif

    /// Visible bounds of the screen the orb actually lives on — NOT NSScreen.main, which follows
    /// the key window and can be a different display in multi-monitor setups.
    var currentVisibleBounds: CGRect {
        (panel?.screen ?? NSScreen.main)?.visibleFrame ?? screen.visibleBounds()
    }

    /// Inset of the dot inside the window (so the glow has room and the dot stays centred).
    private var inset: CGFloat {
        max(0, (orbWindowSize - CGFloat(app?.settings.orbSize ?? Constants.Defaults.orbSize)) / 2)
    }

    func show() {
        if panel == nil { build() }
        panel?.orderFrontRegardless()
        #if DEBUG
        NSLog("HFDIAG orb.show frame=%@ visible=%d vb=%@",
              NSStringFromRect(panel?.frame ?? .zero),
              (panel?.isVisible ?? false) ? 1 : 0,
              NSStringFromRect(screen.visibleBounds()))
        #endif
    }

    func hide() { panel?.orderOut(nil) }

    func resetToDefault() {
        positionStore.reset()
        guard let panel else { return }
        let vb = currentVisibleBounds
        panel.setFrameOrigin(windowOrigin(forDot: positionStore.load(visibleBounds: vb), in: vb))
    }

    /// Re-clamp the whole window into the visible bounds after a screen-layout change (canon §3.6).
    func clampIntoVisibleBounds() {
        guard let panel else { return }
        let vb = currentVisibleBounds
        let origin = clampWindow(panel.frame.origin, in: vb)
        panel.setFrameOrigin(origin)
        positionStore.save(dotOrigin(fromWindow: origin))
    }

    // MARK: Build

    private func build() {
        guard let app else { return }
        let vb = currentVisibleBounds
        let origin = windowOrigin(forDot: positionStore.load(visibleBounds: vb), in: vb)
        let p = KeyablePanel(
            contentRect: CGRect(origin: origin, size: CGSize(width: orbWindowSize, height: orbWindowSize)),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false
        )
        p.isOpaque = false
        // Clear window; clickability is provided by a circular 2% hit disc drawn inside
        // FocusOrbView (per-pixel hit testing) — a window-background tint would render as a
        // faint SQUARE box around the orb.
        p.backgroundColor = .clear
        p.hasShadow = false
        p.level = .statusBar
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.isReleasedWhenClosed = false

        let container = OrbContainerView(frame: CGRect(x: 0, y: 0, width: orbWindowSize, height: orbWindowSize))
        // The window-server computes the click shape from the WINDOW'S OWN surface. SwiftUI content
        // (NSHostingView) composites via a separate layer tree, so a .clear window is click-dead
        // everywhere — even over visually opaque pixels (verified by HF_SELFTEST window-server
        // probes). A near-invisible backing on the container's layer (part of the window surface)
        // makes the orb clickable. It is a RADIAL GRADIENT fading to 0% — a flat disc reads as a
        // hard-edged gray circle on light backgrounds.
        container.wantsLayer = true
        let backing = CAGradientLayer()
        backing.type = .radial
        backing.frame = container.bounds
        backing.colors = [NSColor.black.withAlphaComponent(0.035).cgColor,
                          NSColor.black.withAlphaComponent(0.030).cgColor,
                          NSColor.black.withAlphaComponent(0.0).cgColor]
        backing.locations = [0, 0.55, 1]
        backing.startPoint = CGPoint(x: 0.5, y: 0.5)
        backing.endPoint = CGPoint(x: 1.0, y: 0.5)   // radius = half width (inscribed circle)
        container.layer?.insertSublayer(backing, at: 0)
        container.onClick = { [weak self] in self?.onClick?() }
        container.onSecondaryClick = { [weak self] e in self?.onSecondaryClick?(e) }
        container.onHoverChanged = { [weak self] h in self?.onHoverChanged?(h) }
        container.onLongPressBegan = { [weak self] in self?.onLongPressBegan?() ?? false }
        container.onLongPressMoved = { [weak self] p in self?.onLongPressMoved?(p) }
        container.onLongPressEnded = { [weak self] p in self?.onLongPressEnded?(p) }
        container.onDragEnded = { [weak self] in self?.snapAndSave() }

        let host = NSHostingView(rootView: FocusOrbView().environmentObject(app))
        host.frame = container.bounds
        host.autoresizingMask = [.width, .height]
        container.addSubview(host)
        backingLayer = backing

        p.contentView = container
        panel = p
    }

    // MARK: Rage emphasis (canon #40) — the away orb grows toward ×2, so its window must grow
    // too or the glow clips at the 76 pt edge. Resized around the dot's center; the SwiftUI
    // content is centered and autoresizes, the click backing follows.

    private var backingLayer: CAGradientLayer?
    private var emphasisScale: CGFloat = 1

    func setEmphasis(for state: SessionState) {
        let scale: CGFloat
        switch state {
        case .away, .recovering: scale = 2.4       // dot ×2 + jitter + halo headroom
        case .warning:           scale = 1.5
        default:                 scale = 1
        }
        guard scale != emphasisScale, let panel else { return }
        emphasisScale = scale
        let newSide = orbWindowSize * scale
        let old = panel.frame
        let center = CGPoint(x: old.midX, y: old.midY)
        let newFrame = CGRect(x: center.x - newSide / 2, y: center.y - newSide / 2,
                              width: newSide, height: newSide)
        panel.setFrame(newFrame, display: true)
        panel.contentView?.frame = CGRect(origin: .zero, size: newFrame.size)
        backingLayer?.frame = panel.contentView?.bounds ?? .zero
    }

    // MARK: Geometry (dot origin <-> window origin)

    private func windowOrigin(forDot dot: CGPoint, in vb: CGRect) -> CGPoint {
        clampWindow(CGPoint(x: dot.x - inset, y: dot.y - inset), in: vb)
    }

    private func dotOrigin(fromWindow origin: CGPoint) -> CGPoint {
        CGPoint(x: origin.x + inset, y: origin.y + inset)
    }

    private func clampWindow(_ origin: CGPoint, in vb: CGRect) -> CGPoint {
        CGPoint(x: min(max(origin.x, vb.minX), vb.maxX - orbWindowSize),
                y: min(max(origin.y, vb.minY), vb.maxY - orbWindowSize))
    }

    // MARK: Edge snapping (canon §3.5)

    private func snapAndSave() {
        guard let panel else { return }
        let vb = currentVisibleBounds
        let snap = Constants.Orb.edgeSnapDistance
        let margin = Constants.Orb.edgeMargin
        var frame = panel.frame

        if frame.minX - vb.minX < snap { frame.origin.x = vb.minX + margin }
        if vb.maxX - frame.maxX < snap { frame.origin.x = vb.maxX - frame.width - margin }
        if frame.minY - vb.minY < snap { frame.origin.y = vb.minY + margin }
        if vb.maxY - frame.maxY < snap { frame.origin.y = vb.maxY - frame.height - margin }

        frame.origin = clampWindow(frame.origin, in: vb)
        panel.animator().setFrame(frame, display: true)
        positionStore.save(dotOrigin(fromWindow: frame.origin))
    }
}

/// Content view that owns mouse handling for the orb (SwiftUI orb is a passive subview). Click vs drag
/// is disambiguated by movement (< 4 pt) and duration (< 0.3 s) per canon §3.4.
private final class OrbContainerView: NSView {
    var onClick: (() -> Void)?
    var onSecondaryClick: ((NSEvent) -> Void)?
    var onHoverChanged: ((Bool) -> Void)?
    var onLongPressBegan: (() -> Bool)?
    var onLongPressMoved: ((NSPoint) -> Void)?
    var onLongPressEnded: ((NSPoint) -> Void)?
    var onDragEnded: (() -> Void)?

    private var mouseDownLocation: NSPoint = .zero
    private var windowOriginAtDown: CGPoint = .zero
    private var maxMovement: CGFloat = 0
    private var longPressWork: DispatchWorkItem?
    private var longPressed = false

    override func hitTest(_ point: NSPoint) -> NSView? { self }

    // The orb lives in a nonactivating panel of an LSUIElement app — the app is effectively never
    // active, so EVERY click is a "first mouse". Without this override AppKit swallows them all.
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    // Hover: subtle "alive" reaction (canon §13 #25).
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: .zero,
                                       options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                       owner: self, userInfo: nil))
    }

    override func mouseEntered(with event: NSEvent) { onHoverChanged?(true) }
    override func mouseExited(with event: NSEvent) { onHoverChanged?(false) }

    override func mouseDown(with event: NSEvent) {
        #if DEBUG
        NSLog("HFTEST container.mouseDown")
        #endif
        mouseDownLocation = NSEvent.mouseLocation
        windowOriginAtDown = window?.frame.origin ?? .zero
        maxMovement = 0
        longPressed = false
        // Hold in place ≥ longPressSeconds → quick-start chips appear while the button is held.
        // If the coordinator declines (e.g. a session is running), the press stays a normal click.
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.maxMovement < Constants.Orb.clickMaxMovement else { return }
            if self.onLongPressBegan?() == true { self.longPressed = true }
        }
        longPressWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.Orb.longPressSeconds, execute: work)
    }

    override func mouseDragged(with event: NSEvent) {
        // While quick-start is up, the drag selects a chip — the orb window must not move.
        if longPressed {
            onLongPressMoved?(NSEvent.mouseLocation)
            return
        }
        let current = NSEvent.mouseLocation
        let dx = current.x - mouseDownLocation.x
        let dy = current.y - mouseDownLocation.y
        maxMovement = max(maxMovement, hypot(dx, dy))
        // Only move the window once the gesture is committed as a drag — sub-threshold jitter that
        // resolves as a click/long-press must not drift the orb.
        guard maxMovement >= Constants.Orb.clickMaxMovement else { return }
        longPressWork?.cancel()
        window?.setFrameOrigin(CGPoint(x: windowOriginAtDown.x + dx, y: windowOriginAtDown.y + dy))
    }

    override func mouseUp(with event: NSEvent) {
        longPressWork?.cancel()
        if longPressed {
            longPressed = false
            onLongPressEnded?(NSEvent.mouseLocation)   // release over a chip starts the session
            return
        }
        // Stationary release before the long-press fires = click — no duration dead zone.
        if maxMovement < Constants.Orb.clickMaxMovement {
            #if DEBUG
            NSLog("HFTEST container.mouseUp -> click")
            #endif
            onClick?()
        } else {
            onDragEnded?()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        onSecondaryClick?(event)
    }
}
