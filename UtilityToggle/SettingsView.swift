//
//  SettingsView.swift
//  UtilityToggle
//

import SwiftUI
import AppKit
import ServiceManagement

class ClickableTextField: NSTextField {
    override func mouseDown(with event: NSEvent) {
        if let win = window {
            win.makeKeyAndOrderFront(nil)
            win.makeFirstResponder(self)
        }
        super.mouseDown(with: event)
    }
}

// MARK: - Native NSTextField Wrapper for 100% Reliable Typing
struct CustomY2KTextField: NSViewRepresentable {
    let placeholder: String
    @Binding var text: String
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: CustomY2KTextField
        
        init(_ parent: CustomY2KTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                self.parent.text = textField.stringValue
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = ClickableTextField()
        textField.placeholderString = placeholder
        textField.stringValue = text
        textField.delegate = context.coordinator
        textField.isBordered = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.textColor = .white
        textField.font = .monospacedSystemFont(ofSize: 11, weight: .bold)
        textField.cell?.wraps = false
        textField.cell?.isScrollable = true
        textField.isEditable = true
        textField.isSelectable = true
        textField.isEnabled = true
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }
}

struct SettingsView: View {
    @ObservedObject var audioManager: AudioDeviceManager
    @ObservedObject var panelManager = FloatingPanelManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @AppStorage("autoCloseOnClickOutside") private var autoCloseOnClickOutside: Bool = true
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
                    themeSection
                    behaviorSection
                    diagnosticsSection
                }
                .padding(16)
            }
            
            Divider()
                .background(Color.white.opacity(0.25))
            
            footerActionBar
        }
        .frame(width: AppConfig.Dimensions.settingsWidth, height: AppConfig.Dimensions.settingsHeight)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                AppConfig.Colors.hudBackground
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: AppConfig.Dimensions.settingsCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppConfig.Dimensions.settingsCornerRadius, style: .continuous)
                .stroke(AppConfig.Colors.buttonBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.7), radius: 24, x: 0, y: 10)
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack {
            HStack(spacing: 8) {
                Y2KStar(size: 14)
                Text(AppConfig.Strings.configHeaderTitle)
                    .font(AppConfig.Fonts.header)
                    .foregroundColor(AppConfig.Colors.textPrimary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(AppConfig.Strings.versionText)
                    .font(AppConfig.Fonts.badgeBold)
                    .foregroundColor(AppConfig.Colors.textSecondary)
                
                // Solid Y2K Monochromatic Close Button
                Button(action: {
                    SettingsWindowController.shared.close()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .black))
                        Text(AppConfig.Strings.closeBtn)
                            .font(AppConfig.Fonts.badge)
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppConfig.Colors.accentWhite)
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
    
    // MARK: - Section 1: Profile Management
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
        .padding(14)
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
            
            CustomY2KTextField(placeholder: "Profile Name (e.g. Gaming, Studio)", text: $newProfileName)
                .frame(height: 22)
                .padding(6)
                .background(Color.black.opacity(0.6))
                .clipShape(Rectangle())
                .overlay(Rectangle().stroke(Color.white.opacity(0.4), lineWidth: 0.5))
            
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
                .frame(width: 180)
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
                .frame(width: 180)
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
    
    // MARK: - Section 2: App Behavior
    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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
            .onChange(of: showVolumeInMenuBar) { newValue in
                FloatingPanelManager.shared.updateStatusItem(volume: audioManager.outputVolume, isMuted: audioManager.isOutputMuted)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
    }
    
    // MARK: - Section 3: Theme & Appearance
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "// THEME_&_APPEARANCE")
            
            Text("THEME PRESETS:")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(ThemePreset.allCases) { preset in
                        Button(action: {
                            themeManager.activePreset = preset
                        }) {
                            Text("[ \(preset.rawValue) ]")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundColor(themeManager.activePreset == preset ? .black : .white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(themeManager.activePreset == preset ? Color.white : Color.white.opacity(0.12))
                                .clipShape(Rectangle())
                                .overlay(Rectangle().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                        .focusEffectDisabled()
                    }
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.15))
            
            HStack {
                Text("Primary Accent Color:")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                ColorPicker("", selection: $themeManager.primaryColor)
                    .labelsHidden()
                    .onChange(of: themeManager.primaryColor) { _ in
                        themeManager.activePreset = .custom
                    }
            }
            
            HStack {
                Text("Secondary Background Color:")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                ColorPicker("", selection: $themeManager.secondaryColor)
                    .labelsHidden()
                    .onChange(of: themeManager.secondaryColor) { _ in
                        themeManager.activePreset = .custom
                    }
            }
            
            Button(action: {
                themeManager.resetToDefault()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 9))
                    Text("[ RESET TO DEFAULT Y2K ]")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.1))
                .foregroundColor(.white)
                .clipShape(Rectangle())
                .overlay(Rectangle().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
    }
    
    // MARK: - Section 4: System Diagnostics
    private var diagnosticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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
        .padding(14)
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

class CustomSettingsWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    override var canBecomeMain: Bool {
        return true
    }
}

// MARK: - Window Controller for Settings Window
@MainActor
final class SettingsWindowController: NSObject {
    static let shared = SettingsWindowController()
    
    var window: NSWindow?
    
    func showWindow(audioManager: AudioDeviceManager) {
        let win: NSWindow
        if let existing = window {
            win = existing
        } else {
            let settingsView = SettingsView(audioManager: audioManager)
            let hostingView = NSHostingView(rootView: settingsView)
            
            win = CustomSettingsWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 530),
                styleMask: [.borderless, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            
            hostingView.wantsLayer = true
            hostingView.layer?.cornerRadius = 16
            hostingView.layer?.masksToBounds = true
            
            win.isOpaque = false
            win.backgroundColor = .clear
            win.hasShadow = false
            win.isMovableByWindowBackground = true
            win.contentView = hostingView
            win.isReleasedWhenClosed = false
            win.level = .floating
            
            self.window = win
        }
        
        if let panel = FloatingPanelManager.shared.panel {
            let pFrame = panel.frame
            let winWidth: CGFloat = 450
            let winHeight: CGFloat = 550
            
            var posX = pFrame.minX - winWidth - 12.0
            if posX < 10 {
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
