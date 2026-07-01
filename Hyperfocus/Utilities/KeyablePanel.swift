// KeyablePanel.swift — NSPanel subclass that can take keyboard focus; borderless panels can't otherwise (canon §3 gotcha 1).

import AppKit

final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}
