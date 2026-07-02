// FocusOrbWindowController.swift — KeyablePanel hosting the orb: drag tracking, click detection, edge snapping (canon §3).
//
// The window is `orbWindowSize` (bigger than the coloured dot) so the glow isn't clipped. Persistence
// stores the DOT origin (OrbPositionStore, footprint = orbSize); this controller converts to a window
// origin and clamps the whole window on-screen so the orb is never half off the edge.

import AppKit
import SwiftUI

final class FocusOrbWindowController {
    private let app: AppState
    private let positionStore: OrbPositionStore
    private let screen: ScreenManager

    var onClick: (() -> Void)?
    var onSecondaryClick: ((NSEvent) -> Void)?
    var onLongPress: (() -> Void)?

    private var panel: KeyablePanel?

    init(app: AppState, positionStore: OrbPositionStore, screen: ScreenManager) {
        self.app = app
        self.positionStore = positionStore
        self.screen = screen
    }

    var currentFrame: CGRect { panel?.frame ?? .zero }
    var isVisible: Bool { panel?.isVisible ?? false }
    var contentViewForMenu: NSView? { panel?.contentView }

    /// Inset of the dot inside the window (so the glow has room and the dot stays centred).
    private var inset: CGFloat { max(0, (orbWindowSize - CGFloat(app.settings.orbSize)) / 2) }

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
        let vb = screen.visibleBounds()
        panel.setFrameOrigin(windowOrigin(forDot: positionStore.load(visibleBounds: vb), in: vb))
    }

    /// Re-clamp the whole window into the visible bounds after a screen-layout change (canon §3.6).
    func clampIntoVisibleBounds() {
        guard let panel else { return }
        let vb = screen.visibleBounds()
        let origin = clampWindow(panel.frame.origin, in: vb)
        panel.setFrameOrigin(origin)
        positionStore.save(dotOrigin(fromWindow: origin))
    }

    // MARK: Build

    private func build() {
        let vb = screen.visibleBounds()
        let origin = windowOrigin(forDot: positionStore.load(visibleBounds: vb), in: vb)
        let p = KeyablePanel(
            contentRect: CGRect(origin: origin, size: CGSize(width: orbWindowSize, height: orbWindowSize)),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false
        )
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = false
        p.level = .statusBar
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.isReleasedWhenClosed = false

        let container = OrbContainerView(frame: CGRect(x: 0, y: 0, width: orbWindowSize, height: orbWindowSize))
        container.onClick = { [weak self] in self?.onClick?() }
        container.onSecondaryClick = { [weak self] e in self?.onSecondaryClick?(e) }
        container.onLongPress = { [weak self] in self?.onLongPress?() }
        container.onDragEnded = { [weak self] in self?.snapAndSave() }

        let host = NSHostingView(rootView: FocusOrbView().environmentObject(app))
        host.frame = container.bounds
        host.autoresizingMask = [.width, .height]
        container.addSubview(host)

        p.contentView = container
        panel = p
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
        let vb = screen.visibleBounds()
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
    var onLongPress: (() -> Void)?
    var onDragEnded: (() -> Void)?

    private var mouseDownLocation: NSPoint = .zero
    private var windowOriginAtDown: CGPoint = .zero
    private var downTimestamp: TimeInterval = 0
    private var maxMovement: CGFloat = 0
    private var longPressWork: DispatchWorkItem?
    private var longPressed = false

    // Simple UX for ADHD (canon §13 #18): short click → start; hold ≥ 0.5 s in place → Settings.
    private let longPressDuration: TimeInterval = 0.5

    override func hitTest(_ point: NSPoint) -> NSView? { self }

    override func mouseDown(with event: NSEvent) {
        mouseDownLocation = NSEvent.mouseLocation
        windowOriginAtDown = window?.frame.origin ?? .zero
        downTimestamp = event.timestamp
        maxMovement = 0
        longPressed = false
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.maxMovement < Constants.Orb.clickMaxMovement else { return }
            self.longPressed = true
            self.onLongPress?()
        }
        longPressWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + longPressDuration, execute: work)
    }

    override func mouseDragged(with event: NSEvent) {
        let current = NSEvent.mouseLocation
        let dx = current.x - mouseDownLocation.x
        let dy = current.y - mouseDownLocation.y
        maxMovement = max(maxMovement, hypot(dx, dy))
        if maxMovement >= Constants.Orb.clickMaxMovement { longPressWork?.cancel() }
        window?.setFrameOrigin(CGPoint(x: windowOriginAtDown.x + dx, y: windowOriginAtDown.y + dy))
    }

    override func mouseUp(with event: NSEvent) {
        longPressWork?.cancel()
        if longPressed { longPressed = false; return }   // Settings already opened on hold
        let duration = event.timestamp - downTimestamp
        if maxMovement < Constants.Orb.clickMaxMovement && duration < Constants.Orb.clickMaxDuration {
            onClick?()
        } else {
            onDragEnded?()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        onSecondaryClick?(event)
    }
}
