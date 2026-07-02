// FocusOrbWindowController.swift — KeyablePanel hosting the orb: drag tracking, click detection, edge snapping (canon §3).

import AppKit
import SwiftUI

final class FocusOrbWindowController {
    private let app: AppState
    private let positionStore: OrbPositionStore
    private let screen: ScreenManager

    var onClick: (() -> Void)?
    var onSecondaryClick: ((NSEvent) -> Void)?

    private var panel: KeyablePanel?
    private let windowSize: CGFloat = 56

    init(app: AppState, positionStore: OrbPositionStore, screen: ScreenManager) {
        self.app = app
        self.positionStore = positionStore
        self.screen = screen
    }

    var currentFrame: CGRect { panel?.frame ?? .zero }
    var isVisible: Bool { panel?.isVisible ?? false }
    var contentViewForMenu: NSView? { panel?.contentView }

    func resetToDefault() {
        positionStore.reset()
        guard let panel else { return }
        panel.setFrameOrigin(positionStore.load(visibleBounds: screen.visibleBounds()))
    }

    func show() {
        if panel == nil { build() }
        panel?.orderFrontRegardless()
    }

    func hide() { panel?.orderOut(nil) }

    /// Re-clamp the orb into the visible bounds after a screen-layout change (canon §3.6).
    func clampIntoVisibleBounds() {
        guard let panel else { return }
        let vb = screen.visibleBounds()
        var origin = panel.frame.origin
        origin.x = min(max(origin.x, vb.minX), vb.maxX - windowSize)
        origin.y = min(max(origin.y, vb.minY), vb.maxY - windowSize)
        panel.setFrameOrigin(origin)
        positionStore.save(origin)
    }

    // MARK: Build

    private func build() {
        let origin = positionStore.load(visibleBounds: screen.visibleBounds())
        let p = KeyablePanel(
            contentRect: CGRect(origin: origin, size: CGSize(width: windowSize, height: windowSize)),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false
        )
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = false
        p.level = .statusBar
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.isReleasedWhenClosed = false

        let container = OrbContainerView(frame: CGRect(x: 0, y: 0, width: windowSize, height: windowSize))
        container.onClick = { [weak self] in self?.onClick?() }
        container.onSecondaryClick = { [weak self] e in self?.onSecondaryClick?(e) }
        container.onDragEnded = { [weak self] in self?.snapAndSave() }

        let host = NSHostingView(rootView: FocusOrbView().environmentObject(app))
        host.frame = container.bounds
        host.autoresizingMask = [.width, .height]
        container.addSubview(host)

        p.contentView = container
        panel = p
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

        frame.origin.x = min(max(frame.origin.x, vb.minX), vb.maxX - frame.width)
        frame.origin.y = min(max(frame.origin.y, vb.minY), vb.maxY - frame.height)

        panel.animator().setFrame(frame, display: true)
        positionStore.save(frame.origin)
    }
}

/// Content view that owns mouse handling for the orb (SwiftUI orb is a passive subview). Click vs drag
/// is disambiguated by movement (< 4 pt) and duration (< 0.3 s) per canon §3.4.
private final class OrbContainerView: NSView {
    var onClick: (() -> Void)?
    var onSecondaryClick: ((NSEvent) -> Void)?
    var onDragEnded: (() -> Void)?

    private var mouseDownLocation: NSPoint = .zero
    private var windowOriginAtDown: CGPoint = .zero
    private var downTimestamp: TimeInterval = 0
    private var maxMovement: CGFloat = 0

    // The whole content area is the click/drag target; the SwiftUI subview never receives mouse events.
    override func hitTest(_ point: NSPoint) -> NSView? { self }

    override func mouseDown(with event: NSEvent) {
        mouseDownLocation = NSEvent.mouseLocation
        windowOriginAtDown = window?.frame.origin ?? .zero
        downTimestamp = event.timestamp
        maxMovement = 0
    }

    override func mouseDragged(with event: NSEvent) {
        let current = NSEvent.mouseLocation
        let dx = current.x - mouseDownLocation.x
        let dy = current.y - mouseDownLocation.y
        maxMovement = max(maxMovement, hypot(dx, dy))
        window?.setFrameOrigin(CGPoint(x: windowOriginAtDown.x + dx, y: windowOriginAtDown.y + dy))
    }

    override func mouseUp(with event: NSEvent) {
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
