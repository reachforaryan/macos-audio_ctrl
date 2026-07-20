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
    
    @State private var newProfileName: String = ""
    @State private var selectedOutputUID: String = ""
    @State private var selectedInputUID: String = ""
    @State private var isCreatingProfile: Bool = false
    @State private var diagnosticResults: [TestResult]? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            headerBar
            
            Divider()
                .background(Color.white.opacity(0.25))
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    profileManagementSection
                    shortcutsSection
                    behaviorSection
                    diagnosticsSection
                }
                .padding(16)
            }
            
            Divider()
                .background(Color.white.opacity(0.25))
            
            footerActionBar
        }
        .frame(width: 440, height: 560)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                Color.black.opacity(0.94)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.7), radius: 24, x: 0, y: 10)
    }
    
    // MARK: - Header Bar with Y2K Monochromatic Close Button
    private var headerBar: some View {
        HStack {
            HStack(spacing: 8) {
                Y2KStar(size: 14)
                Text("UTILITY_TOGGLE // CONFIGURATION")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Text("[ v2.0.0 ]")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                
                // Solid Y2K Monochromatic Close Button
                Button(action: {
                    SettingsWindowController.shared.close()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .black))
                        Text("CLOSE")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white)
                    .clipShape(Rectangle())
                }
                .buttonStyle(.plain)
                .focusEffectDisabled()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }
    
    // MARK: - Profile Management Section
    private var profileManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "// AUDIO_PROFILES_&_DEVICES")
            
            VStack(alignment: .leading, spacing: 8) {
                Text("CONFIGURED PROFILES:")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                
                ForEach(audioManager.profiles) { profile in
                    profileRow(profile)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.15))
            
            if isCreatingProfile {
                addProfileForm
            } else {
                Button(action: {
                    isCreatingProfile = true
                }) {
                    HStack(spacing: 6) {
                        Y2KStar(size: 10)
                        Text("[ + ADD NEW PROFILE ]")
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
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
    }
    
    private func profileRow(_ profile: AudioProfile) -> some View {
        HStack {
            Y2KStar(size: 10)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(profile.name.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    if profile.name == "General" {
                        Text("[ DEFAULT ]")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.white)
                            .clipShape(Rectangle())
                    }
                }
                
                Text("Out: \(profile.targetOutputDeviceUID ?? "Default") | In: \(profile.targetInputDeviceUID ?? "Default")")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
            }
            
            Spacer()
            
            if profile.name != "General" {
                Button(action: {
                    audioManager.deleteProfile(id: profile.id)
                }) {
                    Text("[ DELETE ]")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.red.opacity(0.15))
                        .clipShape(Rectangle())
                }
                .buttonStyle(.plain)
                .focusEffectDisabled()
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
    }
    
    private var addProfileForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ADD NEW CUSTOM PROFILE:")
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundColor(.white)
            
            TextField("Profile Name (e.g. Gaming, Studio)", text: $newProfileName)
                .textFieldStyle(.plain)
                .padding(6)
                .background(Color.black.opacity(0.4))
                .foregroundColor(.white)
                .clipShape(Rectangle())
                .overlay(Rectangle().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
            
            HStack {
                Text("Output Device:")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                Picker("", selection: $selectedOutputUID) {
                    Text("System Default Output").tag("")
                    ForEach(audioManager.outputDevices) { dev in
                        Text(dev.name).tag(dev.uid)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 170)
            }
            
            HStack {
                Text("Input Device:")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                Picker("", selection: $selectedInputUID) {
                    Text("System Default Input").tag("")
                    ForEach(audioManager.inputDevices) { dev in
                        Text(dev.name).tag(dev.uid)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 170)
            }
            
            HStack(spacing: 8) {
                Button(action: {
                    let name = newProfileName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    let newProf = AudioProfile(
                        name: name,
                        targetOutputDeviceUID: selectedOutputUID.isEmpty ? nil : selectedOutputUID,
                        targetInputDeviceUID: selectedInputUID.isEmpty ? nil : selectedInputUID,
                        outputVolume: 0.8,
                        inputVolume: 0.8
                    )
                    audioManager.saveProfile(newProf)
                    newProfileName = ""
                    isCreatingProfile = false
                }) {
                    Text("[ SAVE PROFILE ]")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white)
                        .clipShape(Rectangle())
                }
                .buttonStyle(.plain)
                .focusEffectDisabled()
                
                Button(action: {
                    isCreatingProfile = false
                }) {
                    Text("[ CANCEL ]")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Rectangle())
                }
                .buttonStyle(.plain)
                .focusEffectDisabled()
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
    }
    
    // MARK: - Shortcuts Section
    private var shortcutsSection: some View {
        VStack(spacing: 10) {
            sectionHeader(title: "// MENU_BAR_&_SHORTCUTS")
            
            settingRow(title: "Global Hotkey", subtitle: "Toggle widget popover from anywhere") {
                Text("[ ⌥ SPACE ]")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white)
                    .clipShape(Rectangle())
            }
            
            settingRow(title: "Menu Bar Icon Style", subtitle: "Cycle menu bar status item symbol") {
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
    }
    
    // MARK: - Behavior Section
    private var behaviorSection: some View {
        VStack(spacing: 10) {
            sectionHeader(title: "// APP_BEHAVIOR")
            
            settingRow(title: "Launch at Login", subtitle: "Automatically start widget when macOS boots up") {
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
    }
    
    // MARK: - Diagnostics Section
    private var diagnosticsSection: some View {
        VStack(spacing: 10) {
            sectionHeader(title: "// SYSTEM_DIAGNOSTICS")
            
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
    
    // MARK: - Footer Action Bar
    private var footerActionBar: some View {
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

// MARK: - Window Controller for Settings Window (Spawns LEFT of Widget & Above Popover)
@MainActor
final class SettingsWindowController: NSObject {
    static let shared = SettingsWindowController()
    
    private var window: NSWindow?
    
    func showWindow(audioManager: AudioDeviceManager) {
        let win: NSWindow
        if let existing = window {
            win = existing
        } else {
            let settingsView = SettingsView(audioManager: audioManager)
            let hostingView = NSHostingView(rootView: settingsView)
            
            win = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 440, height: 560),
                styleMask: [.borderless, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            
            win.isOpaque = false
            win.backgroundColor = .clear
            win.hasShadow = true
            win.isMovableByWindowBackground = true
            win.contentView = hostingView
            win.isReleasedWhenClosed = false
            win.level = .floating // Appears ON TOP / IN FRONT of the widget
            
            self.window = win
        }
        
        // Position directly to the LEFT of the FloatingPanelManager widget:
        if let panel = FloatingPanelManager.shared.panel {
            let pFrame = panel.frame
            let winWidth: CGFloat = 440
            let winHeight: CGFloat = 560
            
            var posX = pFrame.minX - winWidth - 12.0
            if posX < 10 { // If screen left edge is reached, place to the right
                posX = pFrame.maxX + 12.0
            }
            
            var posY = pFrame.maxY - winHeight
            if let screen = panel.screen ?? NSScreen.main {
                posY = min(posY, screen.visibleFrame.maxY - winHeight - 10)
            }
            
            win.setFrameOrigin(NSPoint(x: posX, y: posY))
        } else {
            win.center()
        }
        
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func close() {
        window?.orderOut(nil)
    }
}
