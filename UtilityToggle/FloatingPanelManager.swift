//
//  FloatingPanelManager.swift
//  UtilityToggle
//

import AppKit
import SwiftUI
import Combine

public enum WindowMode: String, CaseIterable, Identifiable {
    case desktop = "Desktop Widget"
    case floating = "Always on Top"
    case normal = "Normal Window"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .desktop: return "desktopcomputer"
        case .floating: return "pin.fill"
        case .normal: return "rectangle.on.rectangle"
        }
    }
}

@MainActor
final class FloatingPanelManager: NSObject, ObservableObject {
    static let shared = FloatingPanelManager()
    
    var panel: NSPanel!
    private var statusItem: NSStatusItem?
    
    @Published var windowMode: WindowMode = .desktop {
        didSet {
            updateWindowLevel()
        }
    }
    
    @Published var isVisible: Bool = true

    override init() {
        super.init()
    }
    
    func setupPanel(contentView: AnyView) {
        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 500),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.isMovableByWindowBackground = true
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.wantsLayer = true
        hostingView.layer?.cornerRadius = 24
        hostingView.layer?.masksToBounds = true
        
        p.contentView = hostingView
        p.invalidateShadow()
        
        self.panel = p
        
        setupMenuExtra()
        updateWindowLevel()
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
        isVisible = true
    }
    
    func hide() {
        panel?.orderOut(nil)
        isVisible = false
    }
    
    func cycleWindowMode() {
        switch windowMode {
        case .desktop:
            windowMode = .floating
        case .floating:
            windowMode = .normal
        case .normal:
            windowMode = .desktop
        }
    }
    
    func positionBelowStatusItem() {
        guard let panel = panel,
              let button = statusItem?.button,
              let buttonWindow = button.window else { return }
        
        let boundsInWindow = button.convert(button.bounds, to: nil)
        let buttonFrame = buttonWindow.convertToScreen(boundsInWindow)
        let panelSize = panel.frame.size
        
        // Horizontal centering directly under status item icon
        let midX = buttonFrame.midX
        var originX = midX - (panelSize.width / 2.0)
        
        // Vertical placement directly below status item icon
        var originY = buttonFrame.minY - panelSize.height - 6.0
        
        // Clamp to screen boundaries so widget never goes off-screen
        if let screen = buttonWindow.screen ?? NSScreen.main {
            let screenFrame = screen.visibleFrame
            let minX = screenFrame.minX + 8.0
            let maxX = screenFrame.maxX - panelSize.width - 8.0
            originX = min(max(originX, minX), maxX)
            originY = max(originY, screenFrame.minY + 8.0)
        }
        
        panel.setFrameOrigin(NSPoint(x: originX, y: originY))
    }
    
    private func updateWindowLevel() {
        guard let panel = panel else { return }
        switch windowMode {
        case .desktop:
            panel.level = .normal
            panel.collectionBehavior = [.canJoinAllSpaces]
            panel.ignoresMouseEvents = false
        case .floating:
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.ignoresMouseEvents = false
        case .normal:
            panel.level = .normal
            panel.collectionBehavior = [.canJoinAllSpaces]
            panel.ignoresMouseEvents = false
        }
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
