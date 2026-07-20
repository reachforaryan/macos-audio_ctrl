//
//  WidgetView.swift
//  UtilityToggle
//

import SwiftUI
import CoreAudio

struct WidgetView: View {
    @StateObject private var audioManager = AudioDeviceManager()
    @StateObject private var panelManager = FloatingPanelManager.shared
    
    @State private var selectedTab: DeviceType = .output
    @State private var isCompact: Bool = false
    
    enum DeviceType {
        case output
        case input
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerView
            
            if !isCompact {
                // Current Setup Summary Hero Section
                currentSetupCard
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                    .padding(.bottom, 6)
                
                // Device Type Selector (Output / Input)
                tabPickerView
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                
                // Audio Device List
                deviceListView
                    .frame(maxHeight: .infinity)
            } else {
                // Mini Compact Mode Setup Card
                compactView
                    .padding(12)
            }
            
            Divider()
                .background(Color.white.opacity(0.12))
            
            // Footer Action Bar
            footerView
        }
        .frame(width: 330, height: isCompact ? 220 : 500)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.85),
                        Color(red: 0.08, green: 0.10, blue: 0.16).opacity(0.92)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.5), radius: 25, x: 0, y: 10)
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: isCompact)
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: selectedTab)
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "waveform")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Audio Control")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        
                        Text("Live Sync")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
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
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(6)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(isCompact ? "Expand Widget" : "Compact Widget")
                
                // Window Level Mode Button (Desktop Widget / Always on Top / Normal Window)
                Button(action: {
                    panelManager.cycleWindowMode()
                }) {
                    Image(systemName: panelManager.windowMode.iconName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(panelManager.windowMode == .desktop ? .cyan : (panelManager.windowMode == .floating ? .purple : .white.opacity(0.5)))
                        .padding(6)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Mode: \(panelManager.windowMode.rawValue) (Click to switch)")
                
                // Close / Hide Button
                Button(action: {
                    panelManager.hide()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(6)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Hide Widget")
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }
    
    // MARK: - Current Setup Summary Hero Card
    private var currentSetupCard: some View {
        VStack(spacing: 10) {
            // Output Device Hero Row
            let currentOutput = audioManager.outputDevices.first(where: { $0.id == audioManager.currentOutputDeviceID })
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.25))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: currentOutput?.iconName ?? "speaker.wave.2.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.cyan)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("OUTPUT (SPEAKER)")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(currentOutput?.name ?? "No Output Selected")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Mute Output Toggle Button
                Button(action: {
                    audioManager.toggleOutputMute()
                }) {
                    Image(systemName: audioManager.isOutputMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(audioManager.isOutputMuted ? .red : .white)
                        .padding(8)
                        .background(audioManager.isOutputMuted ? Color.red.opacity(0.25) : Color.white.opacity(0.12))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            // Output Volume Slider
            HStack(spacing: 8) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
                
                Slider(value: Binding(
                    get: { audioManager.outputVolume },
                    set: { audioManager.setOutputVolume($0) }
                ), in: 0...1)
                .accentColor(.cyan)
                
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
                
                Text("\(Int(audioManager.outputVolume * 100))%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 32, alignment: .trailing)
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Input Device Hero Row
            let currentInput = audioManager.inputDevices.first(where: { $0.id == audioManager.currentInputDeviceID })
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.purple.opacity(0.25))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: currentInput?.iconName ?? "mic.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.pink)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("INPUT (MICROPHONE)")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(currentInput?.name ?? "No Input Selected")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Mute Input Toggle Button
                Button(action: {
                    audioManager.toggleInputMute()
                }) {
                    Image(systemName: audioManager.isInputMuted ? "mic.slash.fill" : "mic.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(audioManager.isInputMuted ? .red : .white)
                        .padding(8)
                        .background(audioManager.isInputMuted ? Color.red.opacity(0.25) : Color.white.opacity(0.12))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            // Input Volume Slider
            HStack(spacing: 8) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
                
                Slider(value: Binding(
                    get: { audioManager.inputVolume },
                    set: { audioManager.setInputVolume($0) }
                ), in: 0...1)
                .accentColor(.pink)
                
                Image(systemName: "waveform")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
                
                Text("\(Int(audioManager.inputVolume * 100))%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 32, alignment: .trailing)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Tab Picker
    private var tabPickerView: some View {
        HStack(spacing: 4) {
            Button(action: {
                selectedTab = .output
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 12))
                    Text("Output Sources (\(audioManager.outputDevices.count))")
                        .font(.system(size: 11, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(selectedTab == .output ? Color.blue.opacity(0.8) : Color.clear)
                .foregroundColor(selectedTab == .output ? .white : .white.opacity(0.6))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            
            Button(action: {
                selectedTab = .input
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 12))
                    Text("Input Sources (\(audioManager.inputDevices.count))")
                        .font(.system(size: 11, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(selectedTab == .input ? Color.purple.opacity(0.8) : Color.clear)
                .foregroundColor(selectedTab == .input ? .white : .white.opacity(0.6))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding(3)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    // MARK: - Device List
    private var deviceListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 6) {
                let devices = selectedTab == .output ? audioManager.outputDevices : audioManager.inputDevices
                let activeID = selectedTab == .output ? audioManager.currentOutputDeviceID : audioManager.currentInputDeviceID
                
                if devices.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                        Text("No devices found")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, minHeight: 100)
                } else {
                    ForEach(devices) { device in
                        let isActive = device.id == activeID
                        
                        Button(action: {
                            if selectedTab == .output {
                                audioManager.setOutputDevice(device)
                            } else {
                                audioManager.setInputDevice(device)
                            }
                        }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(isActive ? (selectedTab == .output ? Color.blue : Color.purple) : Color.white.opacity(0.1))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: device.iconName)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(isActive ? .white : .white.opacity(0.7))
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(device.name)
                                        .font(.system(size: 12, weight: isActive ? .bold : .medium))
                                        .foregroundColor(isActive ? .white : .white.opacity(0.9))
                                        .lineLimit(1)
                                    
                                    Text(isActive ? "Active Default Device" : "Available Source")
                                        .font(.system(size: 9))
                                        .foregroundColor(isActive ? (selectedTab == .output ? .cyan : .pink) : .white.opacity(0.4))
                                }
                                
                                Spacer()
                                
                                if isActive {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(selectedTab == .output ? .cyan : .pink)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isActive ? Color.white.opacity(0.12) : Color.white.opacity(0.04))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isActive ? (selectedTab == .output ? Color.cyan.opacity(0.5) : Color.pink.opacity(0.5)) : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Compact Mode View
    private var compactView: some View {
        VStack(spacing: 10) {
            let currentOutput = audioManager.outputDevices.first(where: { $0.id == audioManager.currentOutputDeviceID })
            let currentInput = audioManager.inputDevices.first(where: { $0.id == audioManager.currentInputDeviceID })
            
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: currentOutput?.iconName ?? "speaker.wave.2.fill")
                        .foregroundColor(.cyan)
                    Text(currentOutput?.name ?? "No Output")
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                }
                Spacer()
                Button(action: {
                    audioManager.toggleOutputMute()
                }) {
                    Image(systemName: audioManager.isOutputMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .foregroundColor(audioManager.isOutputMuted ? .red : .white)
                        .padding(6)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: currentInput?.iconName ?? "mic.fill")
                        .foregroundColor(.pink)
                    Text(currentInput?.name ?? "No Input")
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                }
                Spacer()
                Button(action: {
                    audioManager.toggleInputMute()
                }) {
                    Image(systemName: audioManager.isInputMuted ? "mic.slash.fill" : "mic.fill")
                        .foregroundColor(audioManager.isInputMuted ? .red : .white)
                        .padding(6)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
    }
    
    // MARK: - Footer
    private var footerView: some View {
        HStack {
            Button(action: {
                openSystemAudioPreferences()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 10))
                    Text("Sound Settings")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.08))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button(action: {
                audioManager.refreshDevices()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10, weight: .bold))
                    Text("Refresh")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(.cyan)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.cyan.opacity(0.15))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
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
