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
            // Y2K Header Bar
            headerView
            
            if !isCompact {
                // Active Setup Hero Section (Frosted Y2K Capsules)
                activeSetupSection
                    .padding(.horizontal, 14)
                    .padding(.top, 6)
                    .padding(.bottom, 8)
                
                // Y2K Minimalist Tab Switcher
                y2kTabPicker
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                
                // Device Source List
                deviceListView
                    .frame(maxHeight: .infinity)
            } else {
                // Compact Mode View
                compactView
                    .padding(12)
            }
            
            Divider()
                .background(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.5), Color.pink.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .opacity(0.4)
            
            // Y2K Footer Bar
            footerView
        }
        .frame(width: 330, height: isCompact ? 195 : 490)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                
                // Y2K Translucent Ice Backdrop
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.06, blue: 0.12).opacity(0.92),
                        Color(red: 0.08, green: 0.05, blue: 0.14).opacity(0.94)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Soft Cyber Neon Glow Orbs
                Circle()
                    .fill(Color.cyan.opacity(0.12))
                    .frame(width: 140, height: 140)
                    .blur(radius: 40)
                    .offset(x: -90, y: -120)
                
                Circle()
                    .fill(Color.pink.opacity(0.12))
                    .frame(width: 140, height: 140)
                    .blur(radius: 40)
                    .offset(x: 90, y: 120)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.cyan.opacity(0.45),
                            Color.white.opacity(0.2),
                            Color.pink.opacity(0.45)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.cyan.opacity(0.2), radius: 16, x: 0, y: 4)
        .animation(.spring(response: 0.32, dampingFraction: 0.8), value: isCompact)
        .animation(.spring(response: 0.32, dampingFraction: 0.8), value: selectedTab)
    }
    
    // MARK: - Y2K Header
    private var headerView: some View {
        HStack {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan, Color.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 26, height: 26)
                        .shadow(color: Color.cyan.opacity(0.6), radius: 6, x: 0, y: 0)
                    
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.black)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("AUDIO // CTRL")
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 5, height: 5)
                            .shadow(color: Color.cyan, radius: 4)
                        
                        Text("Y2K // LIVE")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan.opacity(0.85))
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                // Compact Mode Toggle
                Button(action: {
                    withAnimation {
                        isCompact.toggle()
                    }
                }) {
                    Image(systemName: isCompact ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(6)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .onTapGesture {
                    withAnimation {
                        isCompact.toggle()
                    }
                }
                .help(isCompact ? "Expand" : "Collapse")
                
                // Close Button
                Button(action: {
                    panelManager.hide()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(6)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .onTapGesture {
                    panelManager.hide()
                }
                .help("Close")
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }
    
    // MARK: - Y2K Active Setup Card
    private var activeSetupSection: some View {
        VStack(spacing: 10) {
            // Active Output Row
            let currentOutput = audioManager.outputDevices.first(where: { $0.id == audioManager.currentOutputDeviceID })
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.cyan.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.cyan.opacity(0.4), lineWidth: 0.5))
                    
                    Image(systemName: currentOutput?.iconName ?? "speaker.wave.2.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.cyan)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("// OUTPUT_SOURCE")
                        .font(.system(size: 8, weight: .heavy, design: .monospaced))
                        .foregroundColor(.cyan.opacity(0.8))
                    
                    Text(currentOutput?.name ?? "NO_DEVICE")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Mute Output Toggle
                Button(action: {
                    audioManager.toggleOutputMute()
                }) {
                    Image(systemName: audioManager.isOutputMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(audioManager.isOutputMuted ? .pink : .cyan)
                        .padding(6)
                        .background(audioManager.isOutputMuted ? Color.pink.opacity(0.2) : Color.cyan.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(audioManager.isOutputMuted ? Color.pink.opacity(0.5) : Color.cyan.opacity(0.3), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
            }
            
            // Output Volume Slider
            HStack(spacing: 8) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.cyan.opacity(0.7))
                
                Slider(value: Binding(
                    get: { audioManager.outputVolume },
                    set: { audioManager.setOutputVolume($0) }
                ), in: 0...1)
                .accentColor(.cyan)
                
                Text("\(Int(audioManager.outputVolume * 100))%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                    .frame(width: 32, alignment: .trailing)
            }
            
            Divider()
                .background(Color.white.opacity(0.12))
            
            // Active Input Row
            let currentInput = audioManager.inputDevices.first(where: { $0.id == audioManager.currentInputDeviceID })
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.pink.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.pink.opacity(0.4), lineWidth: 0.5))
                    
                    Image(systemName: currentInput?.iconName ?? "mic.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.pink)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("// INPUT_SOURCE")
                        .font(.system(size: 8, weight: .heavy, design: .monospaced))
                        .foregroundColor(.pink.opacity(0.8))
                    
                    Text(currentInput?.name ?? "NO_DEVICE")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Mute Input Toggle
                Button(action: {
                    audioManager.toggleInputMute()
                }) {
                    Image(systemName: audioManager.isInputMuted ? "mic.slash.fill" : "mic.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(audioManager.isInputMuted ? .pink : .purple)
                        .padding(6)
                        .background(audioManager.isInputMuted ? Color.pink.opacity(0.2) : Color.purple.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(audioManager.isInputMuted ? Color.pink.opacity(0.5) : Color.purple.opacity(0.3), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
            }
            
            // Input Volume Slider
            HStack(spacing: 8) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.pink.opacity(0.7))
                
                Slider(value: Binding(
                    get: { audioManager.inputVolume },
                    set: { audioManager.setInputVolume($0) }
                ), in: 0...1)
                .accentColor(.pink)
                
                Text("\(Int(audioManager.inputVolume * 100))%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.pink)
                    .frame(width: 32, alignment: .trailing)
            }
        }
        .padding(11)
        .background(Color.black.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.3), Color.pink.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
    }
    
    // MARK: - Y2K Minimalist Tab Switcher
    private var y2kTabPicker: some View {
        HStack(spacing: 6) {
            Button(action: {
                selectedTab = .output
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 10))
                    Text("// OUTPUT (\(audioManager.outputDevices.count))")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(selectedTab == .output ? Color.cyan.opacity(0.25) : Color.white.opacity(0.04))
                .foregroundColor(selectedTab == .output ? .cyan : .white.opacity(0.5))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(selectedTab == .output ? Color.cyan.opacity(0.6) : Color.clear, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            
            Button(action: {
                selectedTab = .input
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 10))
                    Text("// INPUT (\(audioManager.inputDevices.count))")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(selectedTab == .input ? Color.pink.opacity(0.25) : Color.white.opacity(0.04))
                .foregroundColor(selectedTab == .input ? .pink : .white.opacity(0.5))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(selectedTab == .input ? Color.pink.opacity(0.6) : Color.clear, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(3)
        .background(Color.black.opacity(0.3))
        .clipShape(Capsule())
    }
    
    // MARK: - Device List
    private var deviceListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 5) {
                let devices = selectedTab == .output ? audioManager.outputDevices : audioManager.inputDevices
                let activeID = selectedTab == .output ? audioManager.currentOutputDeviceID : audioManager.currentInputDeviceID
                
                if devices.isEmpty {
                    VStack(spacing: 6) {
                        Image(systemName: "slash.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.cyan.opacity(0.6))
                        Text("// NO_DEVICES_FOUND")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity, minHeight: 80)
                } else {
                    ForEach(devices) { device in
                        let isActive = device.id == activeID
                        let isHovered = hoveredDeviceID == device.id
                        let accentColor: Color = selectedTab == .output ? .cyan : .pink
                        
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
                                        .fill(isActive ? accentColor.opacity(0.25) : Color.white.opacity(0.08))
                                        .frame(width: 28, height: 28)
                                        .overlay(Circle().stroke(isActive ? accentColor.opacity(0.6) : Color.clear, lineWidth: 0.5))
                                    
                                    Image(systemName: device.iconName)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(isActive ? accentColor : .white.opacity(0.75))
                                }
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(device.name)
                                        .font(.system(size: 11, weight: isActive ? .bold : .medium, design: .monospaced))
                                        .foregroundColor(isActive ? .white : .white.opacity(0.85))
                                        .lineLimit(1)
                                    
                                    Text(isActive ? "// ACTIVE_SOURCE" : "// AVAILABLE")
                                        .font(.system(size: 8, weight: .heavy, design: .monospaced))
                                        .foregroundColor(isActive ? accentColor : .white.opacity(0.35))
                                }
                                
                                Spacer()
                                
                                if isActive {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(accentColor)
                                        .shadow(color: accentColor.opacity(0.8), radius: 4)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                isActive
                                    ? accentColor.opacity(0.12)
                                    : (isHovered ? Color.white.opacity(0.06) : Color.white.opacity(0.025))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(isActive ? accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            hoveredDeviceID = hovering ? device.id : nil
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
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
                        .foregroundColor(.cyan)
                    Text(currentOutput?.name ?? "NO_OUTPUT")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                Spacer()
                Button(action: {
                    audioManager.toggleOutputMute()
                }) {
                    Image(systemName: audioManager.isOutputMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .foregroundColor(audioManager.isOutputMuted ? .pink : .cyan)
                        .padding(5)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: currentInput?.iconName ?? "mic.fill")
                        .foregroundColor(.pink)
                    Text(currentInput?.name ?? "NO_INPUT")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                Spacer()
                Button(action: {
                    audioManager.toggleInputMute()
                }) {
                    Image(systemName: audioManager.isInputMuted ? "mic.slash.fill" : "mic.fill")
                        .foregroundColor(audioManager.isInputMuted ? .pink : .purple)
                        .padding(5)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.3))
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
                        .font(.system(size: 9))
                    Text("// SOUND_SETTINGS")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button(action: {
                audioManager.refreshDevices()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 9, weight: .bold))
                    Text("// REFRESH")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.cyan)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.cyan.opacity(0.15))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.cyan.opacity(0.4), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
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
