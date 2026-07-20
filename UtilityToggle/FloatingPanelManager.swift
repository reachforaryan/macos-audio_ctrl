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
    private var globalHotkeyMonitor: Any?
    private var localHotkeyMonitor: Any?
    
    @Published var isVisible: Bool = true
    @Published var menuIconIndex: Int = 0
    @Published var currentHotKey: CustomHotKey = CustomHotKey.defaultHotkey
    
    private let hotkeyStorageKey = "UserCustomHotKeyStorageKey"
    let iconNames = ["waveform", "star.fill", "disc.fill"]
    let iconLabels = ["WAVEFORM 🌊", "STAR ✦", "DISC 💿"]

    override init() {
        super.init()
        loadHotkeyFromDisk()
    }
    
    func setupPanel(contentView: AnyView) {
        let p = CustomFloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 500),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.isMovableByWindowBackground = false
        p.isMovable = false
        p.ignoresMouseEvents = false
        p.level = .popUpMenu
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.wantsLayer = true
        hostingView.layer?.cornerRadius = 20
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
        setupGlobalHotkey()
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
        SettingsWindowController.shared.close()
    }
    
    func setIcon(index: Int) {
        menuIconIndex = index % iconNames.count
        updateStatusItemImage()
    }
    
    func cycleMenuBarIcon() {
        menuIconIndex = (menuIconIndex + 1) % iconNames.count
        updateStatusItemImage()
    }
    
    func updateStatusItemImage() {
        guard let button = statusItem?.button else { return }
        let symbolName = iconNames[menuIconIndex]
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Audio Switcher") {
            let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .bold)
            let configured = image.withSymbolConfiguration(config) ?? image
            configured.isTemplate = true
            button.image = nil
            button.image = configured
        }
    }
    
    func updateHotkey(_ newHotKey: CustomHotKey) {
        self.currentHotKey = newHotKey
        persistHotkeyToDisk(newHotKey)
        setupGlobalHotkey()
    }
    
    private func loadHotkeyFromDisk() {
        if let data = UserDefaults.standard.data(forKey: hotkeyStorageKey),
           let decoded = try? JSONDecoder().decode(CustomHotKey.self, from: data) {
            self.currentHotKey = decoded
        } else {
            self.currentHotKey = CustomHotKey.defaultHotkey
        }
    }
    
    private func persistHotkeyToDisk(_ hotkey: CustomHotKey) {
        if let encoded = try? JSONEncoder().encode(hotkey) {
            UserDefaults.standard.set(encoded, forKey: hotkeyStorageKey)
        }
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
        
        let topY = buttonFrame.minY > 0 ? buttonFrame.minY : (NSScreen.main?.frame.maxY ?? 1000) - 24
        var originY = topY - panelSize.height - 4.0
        
        if let screen = buttonWindow.screen ?? NSScreen.main {
            let screenFrame = screen.frame
            let minX = screenFrame.minX + 8.0
            let maxX = screenFrame.maxX - panelSize.width - 8.0
            originX = min(max(originX, minX), maxX)
            originY = max(originY, screenFrame.minY + 8.0)
        }
        
        panel.setFrameOrigin(NSPoint(x: originX, y: originY))
    }
    
    private func setupGlobalHotkey() {
        if let monitor = globalHotkeyMonitor {
            NSEvent.removeMonitor(monitor)
            globalHotkeyMonitor = nil
        }
        if let monitor = localHotkeyMonitor {
            NSEvent.removeMonitor(monitor)
            localHotkeyMonitor = nil
        }
        
        // Global Monitor (when app is in background)
        globalHotkeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            let requiredFlags = self.currentHotKey.flags
            let eventFlags = event.modifierFlags.intersection([.control, .option, .shift, .command])
            
            if event.keyCode == self.currentHotKey.keyCode && (requiredFlags.isEmpty || eventFlags == requiredFlags) {
                Task { @MainActor [weak self] in
                    self?.toggleVisibility()
                }
            }
        }
        
        // Local Monitor (when app is active)
        localHotkeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            let requiredFlags = self.currentHotKey.flags
            let eventFlags = event.modifierFlags.intersection([.control, .option, .shift, .command])
            
            if event.keyCode == self.currentHotKey.keyCode && (requiredFlags.isEmpty || eventFlags == requiredFlags) {
                Task { @MainActor [weak self] in
                    self?.toggleVisibility()
                }
                return nil // consume event
            }
            return event
        }
    }
    
    private func startClickOutsideMonitor() {
        stopClickOutsideMonitor()
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isVisible, let panel = self.panel else { return }
                let mouseLocation = NSEvent.mouseLocation
                
                if NSPointInRect(mouseLocation, panel.frame) {
                    return
                }
                
                if let button = self.statusItem?.button,
                   let buttonWindow = button.window {
                    let boundsInWindow = button.convert(button.bounds, to: nil)
                    let buttonFrame = buttonWindow.convertToScreen(boundsInWindow)
                    if NSPointInRect(mouseLocation, buttonFrame) {
                        return
                    }
                }
                
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
        let mouseLocation = NSEvent.mouseLocation
        if let panel = panel, NSPointInRect(mouseLocation, panel.frame) {
            panel.makeKeyAndOrderFront(nil)
            return
        }
    }
    
    private func setupMenuExtra() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusItemImage()
        if let button = statusItem?.button {
            button.action = #selector(menuBarButtonClicked)
            button.target = self
        }
    }
    
    @objc private func menuBarButtonClicked() {
        toggleVisibility()
    }
}
