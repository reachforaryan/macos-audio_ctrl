//
//  SettingsView.swift
//  UtilityToggle
//

import SwiftUI
import AppKit
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var audioManager: AudioDeviceManager
    @ObservedObject var panelManager = FloatingPanelManager.shared
    
    @AppStorage("autoCloseOnClickOutside") private var autoCloseOnClickOutside: Bool = true
    @AppStorage("startInCompactMode") private var startInCompactMode: Bool = false
    @AppStorage("showVolumeInMenuBar") private var showVolumeInMenuBar: Bool = false
    @AppStorage("enableSoundEffects") private var enableSoundEffects: Bool = true
    @AppStorage("defaultPresetOnLaunch") private var defaultPresetOnLaunch: String = "None"
    
    @State private var diagnosticResults: [TestResult]? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Y2K Header
            HStack {
                Y2KStar(size: 14)
                Text("UTILITY_TOGGLE // CONFIGURATION")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                Text("[ v2.0.0 ]")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    
                    // SECTION 1: GLOBAL SHORTCUTS & MENU BAR
                    sectionHeader(title: "// MENU_BAR_&_SHORTCUTS")
                    
                    VStack(spacing: 10) {
                        settingRow(
                            title: "Global Hotkey",
                            subtitle: "Toggle widget popover from anywhere"
                        ) {
                            Text("[ ⌥ SPACE ]")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.white)
                                .clipShape(Rectangle())
                        }
                        
                        settingRow(
                            title: "Menu Bar Icon Style",
                            subtitle: "Cycle menu bar status item symbol"
                        ) {
                            Button(action: {
                                panelManager.cycleMenuBarIcon()
                            }) {
                                Text("[ CYCLE_ICON ]")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.12))
                                    .clipShape(Rectangle())
                                    .overlay(Rectangle().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                            }
                            .buttonStyle(.plain)
                            .focusEffectDisabled()
                        }
                        
                        Toggle(isOn: $showVolumeInMenuBar) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Show Volume % in Menu Bar")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                Text("Display active output scalar percentage next to icon")
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .toggleStyle(.checkbox)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                    
                    // SECTION 2: SYSTEM BEHAVIOR & LAUNCH
                    sectionHeader(title: "// APP_BEHAVIOR")
                    
                    VStack(spacing: 10) {
                        settingRow(
                            title: "Launch at Login",
                            subtitle: "Automatically start widget when macOS boots up"
                        ) {
                            Button(action: {
                                audioManager.toggleLaunchAtLogin()
                            }) {
                                Text(audioManager.isLaunchAtLoginEnabled ? "[ ENABLED ]" : "[ DISABLED ]")
                                    .font(.system(size: 9, weight: .black, design: .monospaced))
                                    .foregroundColor(audioManager.isLaunchAtLoginEnabled ? .black : .white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(audioManager.isLaunchAtLoginEnabled ? Color.white : Color.white.opacity(0.12))
                                    .clipShape(Rectangle())
                                    .overlay(Rectangle().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                            }
                            .buttonStyle(.plain)
                            .focusEffectDisabled()
                        }
                        
                        Toggle(isOn: $autoCloseOnClickOutside) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Auto-Close on Click Outside")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                Text("Dismiss popover automatically when focus is lost")
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .toggleStyle(.checkbox)
                        
                        Toggle(isOn: $startInCompactMode) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Start in Compact Mode")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                Text("Launch widget directly in collapsed mini view")
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .toggleStyle(.checkbox)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                    
                    // SECTION 3: AUDIO PRESETS & DIAGNOSTICS
                    sectionHeader(title: "// AUDIO_PRESETS_&_DIAGNOSTICS")
                    
                    VStack(spacing: 10) {
                        settingRow(
                            title: "Default Launch Preset",
                            subtitle: "Automatically apply profile when widget opens"
                        ) {
                            Picker("", selection: $defaultPresetOnLaunch) {
                                Text("None").tag("None")
                                Text("Headset").tag("Headset")
                                Text("Meeting").tag("Meeting")
                                Text("Speaker").tag("Speaker")
                            }
                            .pickerStyle(.menu)
                            .frame(width: 110)
                        }
                        
                        Button(action: {
                            Task { @MainActor in
                                self.diagnosticResults = AudioDeviceTester.runAllTests()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 10))
                                Text("[ RUN_SYSTEM_DIAGNOSTICS ]")
                                    .font(.system(size: 9, weight: .black, design: .monospaced))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.12))
                            .foregroundColor(.white)
                            .clipShape(Rectangle())
                            .overlay(Rectangle().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                        .focusEffectDisabled()
                        
                        if let results = diagnosticResults {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(results, id: \.name) { res in
                                    HStack {
                                        Text(res.passed ? "✅" : "❌")
                                            .font(.system(size: 9))
                                        Text(res.name.uppercased())
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text(res.message)
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.6))
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .padding(8)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Rectangle())
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                    
                }
                .padding(16)
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Footer Action
            HStack {
                Spacer()
                Button(action: {
                    SettingsWindowController.shared.close()
                }) {
                    Text("[ SAVE_&_CLOSE ]")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .clipShape(Rectangle())
                }
                .buttonStyle(.plain)
                .focusEffectDisabled()
            }
            .padding(12)
        }
        .frame(width: 420, height: 520)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                Color.black.opacity(0.92)
            }
        )
    }
    
    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
            Spacer()
        }
    }
    
    private func settingRow<Content: View>(title: String, subtitle: String, @ViewBuilder trailing: () -> Content) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
            trailing()
        }
    }
}

// Window Controller for Settings Window
@MainActor
final class SettingsWindowController: NSObject {
    static let shared = SettingsWindowController()
    
    private var window: NSWindow?
    
    func showWindow(audioManager: AudioDeviceManager) {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsView(audioManager: audioManager)
        let hostingView = NSHostingView(rootView: settingsView)
        
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 520),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        win.center()
        win.title = "UtilityToggle Settings"
        win.titlebarAppearsTransparent = true
        win.titleVisibility = .hidden
        win.isMovableByWindowBackground = true
        win.contentView = hostingView
        win.isReleasedWhenClosed = false
        win.backgroundColor = .clear
        
        self.window = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func close() {
        window?.orderOut(nil)
    }
}
