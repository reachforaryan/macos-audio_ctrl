//
//  WidgetView.swift
//  UtilityToggle
//

import SwiftUI
import AppKit
import CoreAudio

struct WidgetView: View {
    @StateObject private var audioManager = AudioDeviceManager()
    @StateObject private var panelManager = FloatingPanelManager.shared
    
    @State private var selectedTab: DeviceType = .output
    @State private var isCompact: Bool = false
    @State private var hoveredDeviceID: AudioObjectID? = nil
    
    enum DeviceType {
        case output
        case input
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerView
            
            if !isCompact {
                // Active Setup Hero Section (macOS System Control Style Card)
                activeSetupSection
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                
                // macOS System Native Segmented Control
                Picker("", selection: $selectedTab) {
                    Text("Output (\(audioManager.outputDevices.count))").tag(DeviceType.output)
                    Text("Input (\(audioManager.inputDevices.count))").tag(DeviceType.input)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
                
                // Audio Sources List (macOS System Menu Style)
                deviceListView
                    .frame(maxHeight: .infinity)
            } else {
                // Compact Mode View
                compactView
                    .padding(10)
            }
            
            Divider()
                .opacity(0.4)
            
            // Footer Bar
            footerView
        }
        .frame(width: 320, height: isCompact ? 195 : 480)
        .background(
            VisualEffectBlur(material: .popover, blendingMode: .behindWindow)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 5)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isCompact)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedTab)
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            HStack(spacing: 7) {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.accentColor)
                
                Text("Sound")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                // Compact Toggle Button
                Button(action: {
                    withAnimation {
                        isCompact.toggle()
                    }
                }) {
                    Image(systemName: isCompact ? "rectangle.expand.vertical" : "rectangle.compress.vertical")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(5)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .onTapGesture {
                    withAnimation {
                        isCompact.toggle()
                    }
                }
                .help(isCompact ? "Expand" : "Collapse")
                
                // Close/Hide Button
                Button(action: {
                    panelManager.hide()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(5)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .onTapGesture {
                    panelManager.hide()
                }
                .help("Close")
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }
    
    // MARK: - Active Setup Hero Card
    private var activeSetupSection: some View {
        VStack(spacing: 8) {
            // Active Output Row
            let currentOutput = audioManager.outputDevices.first(where: { $0.id == audioManager.currentOutputDeviceID })
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: currentOutput?.iconName ?? "speaker.wave.2.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("OUTPUT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    Text(currentOutput?.name ?? "No Output")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Mute Output Button
                Button(action: {
                    audioManager.toggleOutputMute()
                }) {
                    Image(systemName: audioManager.isOutputMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(audioManager.isOutputMuted ? .red : .primary)
                        .padding(6)
                        .background(audioManager.isOutputMuted ? Color.red.opacity(0.15) : Color.primary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            
            // Output Volume Slider
            HStack(spacing: 8) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Slider(value: Binding(
                    get: { audioManager.outputVolume },
                    set: { audioManager.setOutputVolume($0) }
                ), in: 0...1)
                .accentColor(.accentColor)
                
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Text("\(Int(audioManager.outputVolume * 100))%")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 34, alignment: .trailing)
            }
            
            Divider()
                .opacity(0.3)
            
            // Active Input Row
            let currentInput = audioManager.inputDevices.first(where: { $0.id == audioManager.currentInputDeviceID })
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: currentInput?.iconName ?? "mic.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("INPUT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    Text(currentInput?.name ?? "No Input")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Mute Input Button
                Button(action: {
                    audioManager.toggleInputMute()
                }) {
                    Image(systemName: audioManager.isInputMuted ? "mic.slash.fill" : "mic.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(audioManager.isInputMuted ? .red : .primary)
                        .padding(6)
                        .background(audioManager.isInputMuted ? Color.red.opacity(0.15) : Color.primary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            
            // Input Volume Slider
            HStack(spacing: 8) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Slider(value: Binding(
                    get: { audioManager.inputVolume },
                    set: { audioManager.setInputVolume($0) }
                ), in: 0...1)
                .accentColor(.accentColor)
                
                Image(systemName: "waveform")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Text("\(Int(audioManager.inputVolume * 100))%")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 34, alignment: .trailing)
            }
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
        )
    }
    
    // MARK: - Device List
    private var deviceListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 4) {
                let devices = selectedTab == .output ? audioManager.outputDevices : audioManager.inputDevices
                let activeID = selectedTab == .output ? audioManager.currentOutputDeviceID : audioManager.currentInputDeviceID
                
                if devices.isEmpty {
                    VStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 20))
                            .foregroundColor(.orange)
                        Text("No devices found")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 80)
                } else {
                    ForEach(devices) { device in
                        let isActive = device.id == activeID
                        let isHovered = hoveredDeviceID == device.id
                        
                        Button(action: {
                            if selectedTab == .output {
                                audioManager.setOutputDevice(device)
                            } else {
                                audioManager.setInputDevice(device)
                            }
                        }) {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(isActive ? Color.accentColor : Color.primary.opacity(0.08))
                                        .frame(width: 28, height: 28)
                                    
                                    Image(systemName: device.iconName)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(isActive ? .white : .primary)
                                }
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(device.name)
                                        .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    
                                    Text(isActive ? "Active" : "Available")
                                        .font(.system(size: 9))
                                        .foregroundColor(isActive ? .accentColor : .secondary)
                                }
                                
                                Spacer()
                                
                                if isActive {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                isActive
                                    ? Color(NSColor.selectedControlColor).opacity(0.15)
                                    : (isHovered ? Color.primary.opacity(0.05) : Color.clear)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            hoveredDeviceID = hovering ? device.id : nil
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 2)
        }
    }
    
    // MARK: - Compact Mode View
    private var compactView: some View {
        VStack(spacing: 8) {
            let currentOutput = audioManager.outputDevices.first(where: { $0.id == audioManager.currentOutputDeviceID })
            let currentInput = audioManager.inputDevices.first(where: { $0.id == audioManager.currentInputDeviceID })
            
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: currentOutput?.iconName ?? "speaker.wave.2.fill")
                        .foregroundColor(.accentColor)
                    Text(currentOutput?.name ?? "No Output")
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                }
                Spacer()
                Button(action: {
                    audioManager.toggleOutputMute()
                }) {
                    Image(systemName: audioManager.isOutputMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .foregroundColor(audioManager.isOutputMuted ? .red : .primary)
                        .padding(5)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: currentInput?.iconName ?? "mic.fill")
                        .foregroundColor(.accentColor)
                    Text(currentInput?.name ?? "No Input")
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                }
                Spacer()
                Button(action: {
                    audioManager.toggleInputMute()
                }) {
                    Image(systemName: audioManager.isInputMuted ? "mic.slash.fill" : "mic.fill")
                        .foregroundColor(audioManager.isInputMuted ? .red : .primary)
                        .padding(5)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    
    // MARK: - Footer
    private var footerView: some View {
        HStack {
            Button(action: {
                openSystemAudioPreferences()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 10))
                    Text("Sound Settings...")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button(action: {
                audioManager.refreshDevices()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10, weight: .bold))
                    Text("Refresh")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    private func openSystemAudioPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.sound") {
            NSWorkspace.shared.open(url)
        }
    }
}

// Helper struct for macOS Visual Effect Blur background
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
