//
//  FloatingPanelManager.swift
//  UtilityToggle
//

import AppKit
import SwiftUI
import Combine

class CustomFloatingPanel: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}

@MainActor
final class FloatingPanelManager: NSObject, ObservableObject {
    static let shared = FloatingPanelManager()
    
    var panel: NSPanel!
    private var statusItem: NSStatusItem?
    private var globalEventMonitor: Any?
    
    @Published var isVisible: Bool = true

    override init() {
        super.init()
    }
    
    func setupPanel(contentView: AnyView) {
        let p = CustomFloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 480),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.isMovableByWindowBackground = true
        p.ignoresMouseEvents = false
        p.level = .popUpMenu
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.wantsLayer = true
        hostingView.layer?.cornerRadius = 16
        hostingView.layer?.masksToBounds = true
        
        p.contentView = hostingView
        p.invalidateShadow()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResignKey),
            name: NSWindow.didResignKeyNotification,
            object: p
        )
        
        self.panel = p
        
        setupMenuExtra()
        positionBelowStatusItem()
        show()
    }
    
    func toggleVisibility() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }
    
    func show() {
        positionBelowStatusItem()
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        isVisible = true
        startClickOutsideMonitor()
    }
    
    func hide() {
        stopClickOutsideMonitor()
        panel?.orderOut(nil)
        isVisible = false
    }
    
    func positionBelowStatusItem() {
        guard let panel = panel,
              let button = statusItem?.button,
              let buttonWindow = button.window else { return }
        
        let boundsInWindow = button.convert(button.bounds, to: nil)
        let buttonFrame = buttonWindow.convertToScreen(boundsInWindow)
        let panelSize = panel.frame.size
        
        let midX = buttonFrame.midX
        var originX = midX - (panelSize.width / 2.0)
        var originY = buttonFrame.minY - panelSize.height - 6.0
        
        if let screen = buttonWindow.screen ?? NSScreen.main {
            let screenFrame = screen.visibleFrame
            let minX = screenFrame.minX + 8.0
            let maxX = screenFrame.maxX - panelSize.width - 8.0
            originX = min(max(originX, minX), maxX)
            originY = max(originY, screenFrame.minY + 8.0)
        }
        
        panel.setFrameOrigin(NSPoint(x: originX, y: originY))
    }
    
    private func startClickOutsideMonitor() {
        stopClickOutsideMonitor()
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isVisible else { return }
                self.hide()
            }
        }
    }
    
    private func stopClickOutsideMonitor() {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
    }
    
    @objc private func windowDidResignKey(_ notification: Notification) {
        hide()
    }
    
    private func setupMenuExtra() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "waveform.circle.fill", accessibilityDescription: "Audio Switcher")
            button.action = #selector(menuBarButtonClicked)
            button.target = self
        }
    }
    
    @objc private func menuBarButtonClicked() {
        toggleVisibility()
    }
}
