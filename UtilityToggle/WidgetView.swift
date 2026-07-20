//
//  WidgetView.swift
//  UtilityToggle
//

import SwiftUI
import AppKit
import CoreAudio

// MARK: - Y2K 4-Point Concave Sparkle Star Shape
struct Y2KStar: View {
    var size: CGFloat = 16
    
    var body: some View {
        Path { path in
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = size / 2
            let c: CGFloat = 0.22
            
            path.move(to: CGPoint(x: center.x, y: 0))
            path.addQuadCurve(to: CGPoint(x: size, y: center.y), control: CGPoint(x: center.x + radius * c, y: center.y - radius * c))
            path.addQuadCurve(to: CGPoint(x: center.x, y: size), control: CGPoint(x: center.x + radius * c, y: center.y + radius * c))
            path.addQuadCurve(to: CGPoint(x: 0, y: center.y), control: CGPoint(x: center.x - radius * c, y: center.y + radius * c))
            path.addQuadCurve(to: CGPoint(x: center.x, y: 0), control: CGPoint(x: center.x - radius * c, y: center.y - radius * c))
        }
        .fill(Color.white)
        .frame(width: size, height: size)
    }
}

// MARK: - Y2K Hatched Segmented Volume Bar
struct Y2KHatchedSlider: View {
    @Binding var value: Float
    var onEditingChanged: (Float) -> Void
    
    var body: some View {
        GeometryReader { geo in
            let totalBars = 22
            let width = geo.size.width
            let activeBars = Int(round(Double(value) * Double(totalBars)))
            
            HStack(spacing: 3) {
                ForEach(0..<22) { index in
                    Rectangle()
                        .fill(index < activeBars ? Color.white : Color.white.opacity(0.15))
                        .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.35, d: 1, tx: 0, ty: 0))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let progress = max(0, min(1, gesture.location.x / width))
                        let newVol = Float(progress)
                        value = newVol
                        onEditingChanged(newVol)
                    }
            )
        }
        .frame(height: 14)
    }
}

// MARK: - Y2K Live Mic Peak Meter
struct Y2KMicLevelMeter: View {
    var level: Float
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<14) { index in
                let threshold = Float(index) / 14.0
                let isActive = level > threshold
                Rectangle()
                    .fill(isActive ? (index > 10 ? Color.white : Color.white.opacity(0.85)) : Color.white.opacity(0.12))
                    .frame(width: 4, height: 8)
            }
        }
    }
}

// MARK: - Y2K Animated Equalizer Spectrum (Live 60 FPS Bouncing Bars)
struct Y2KSpectrumVisualizer: View {
    var isMuted: Bool
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSince1970
            HStack(spacing: 2.5) {
                ForEach(0..<8, id: \.self) { i in
                    let seed = Double(i) * 1.4
                    let h = isMuted ? 3.0 : max(3.0, 4.0 + sin(time * 9.0 + seed) * 5.0 + cos(time * 14.0 + seed * 0.4) * 3.0)
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 2.5, height: CGFloat(h))
                }
            }
            .frame(height: 16, alignment: .bottom)
        }
    }
}

struct WidgetView: View {
    @StateObject private var audioManager = AudioDeviceManager()
    @StateObject private var panelManager = FloatingPanelManager.shared
    
    @State private var selectedTab: DeviceType = .output
    @State private var isCompact: Bool = false
    @State private var hoveredDeviceID: AudioObjectID? = nil
    @State private var starRotation: Double = 0
    
    enum DeviceType {
        case output
        case input
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Y2K Header Bar
            headerView
            
            if !isCompact {
                // Y2K Preset Profiles Bar
                presetProfilesBar
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
                    .padding(.bottom, 6)
                
                // Active Setup Hero Section
                activeSetupSection
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
                
                // Y2K Monochromatic Source Switcher
                y2kSourceSwitcher
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                
                // Audio Device Source List
                deviceListView
                    .frame(maxHeight: .infinity)
            } else {
                // Compact Mode View
                compactView
                    .padding(10)
            }
            
            // Y2K Decorative Scale Line
            y2kScaleDivider
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
            
            // Y2K Footer Bar
            footerView
        }
        .frame(width: 340, height: isCompact ? 220 : 530)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                Color.black.opacity(0.88)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.6), radius: 20, x: 0, y: 8)
        .animation(.spring(response: 0.32, dampingFraction: 0.8), value: isCompact)
        .animation(.spring(response: 0.32, dampingFraction: 0.8), value: selectedTab)
        .onAppear {
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                starRotation = 360
            }
        }
    }
    
    // MARK: - Y2K Header
    private var headerView: some View {
        HStack {
            HStack(spacing: 8) {
                // Rotating Y2K Sparkle Star ✦
                Y2KStar(size: 16)
                    .rotationEffect(.degrees(starRotation))
                
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text("AUDIO // SYSTEM 2000")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text("[ ⌥SPACE ]")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                    }
                    
                    Text("COMPACT DISC DIGITAL AUDIO")
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            // Equalizer Spectrum Visualizer
            Y2KSpectrumVisualizer(isMuted: audioManager.isOutputMuted)
                .padding(.trailing, 6)
            
            HStack(spacing: 6) {
                // Compact Toggle Button
                Button(action: {
                    withAnimation {
                        isCompact.toggle()
                    }
                }) {
                    Image(systemName: isCompact ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Rectangle())
                        .overlay(Rectangle().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .focusEffectDisabled()
                .contentShape(Rectangle())
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
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Rectangle())
                        .overlay(Rectangle().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .focusEffectDisabled()
                .contentShape(Rectangle())
                .onTapGesture {
                    panelManager.hide()
                }
                .help("Close")
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }
    
    // MARK: - Y2K Audio Profiles Bar
    private var presetProfilesBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(audioManager.profiles) { profile in
                    let isActive = audioManager.activeProfile.id == profile.id
                    Button(action: {
                        audioManager.applyProfile(profile)
                    }) {
                        HStack(spacing: 4) {
                            Y2KStar(size: 8)
                                .foregroundColor(isActive ? .black : .white)
                            Text(profile.name.uppercased())
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(isActive ? Color.white : Color.white.opacity(0.06))
                        .foregroundColor(isActive ? .black : .white.opacity(0.8))
                        .clipShape(Rectangle())
                        .overlay(Rectangle().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                    .focusEffectDisabled()
                }
            }
        }
    }
    
    // MARK: - Y2K Active Setup Section
    private var activeSetupSection: some View {
        VStack(spacing: 10) {
            // Output Wireframe Card
            let currentOutput = audioManager.outputDevices.first(where: { $0.id == audioManager.currentOutputDeviceID })
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: currentOutput?.iconName ?? "speaker.wave.2.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("// OUTPUT_DEVICE")
                            .font(.system(size: 8, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text(currentOutput?.name.uppercased() ?? "NO_DEVICE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Mute Button
                    Button(action: {
                        audioManager.toggleOutputMute()
                    }) {
                        Text(audioManager.isOutputMuted ? "[ MUTED ]" : "[ MUTE ]")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundColor(audioManager.isOutputMuted ? .black : .white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(audioManager.isOutputMuted ? Color.white : Color.white.opacity(0.12))
                            .clipShape(Rectangle())
                            .overlay(Rectangle().stroke(Color.white.opacity(0.4), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                    .focusEffectDisabled()
                }
                
                // Y2K Hatched Volume Bar
                HStack(spacing: 8) {
                    Y2KHatchedSlider(
                        value: Binding(
                            get: { audioManager.outputVolume },
                            set: { audioManager.setOutputVolume($0) }
                        ),
                        onEditingChanged: { newVol in
                            audioManager.setOutputVolume(newVol)
                        }
                    )
                    
                    Text("\(Int(audioManager.outputVolume * 100))%")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 32, alignment: .trailing)
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            
            // Input Wireframe Card with Live dB Mic Level
            let currentInput = audioManager.inputDevices.first(where: { $0.id == audioManager.currentInputDeviceID })
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: currentInput?.iconName ?? "mic.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 6) {
                            Text("// INPUT_DEVICE")
                                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                            
                            // Live Mic Level Meter
                            Y2KMicLevelMeter(level: audioManager.liveInputLevel)
                        }
                        
                        Text(currentInput?.name.uppercased() ?? "NO_DEVICE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Mute Button
                    Button(action: {
                        audioManager.toggleInputMute()
                    }) {
                        Text(audioManager.isInputMuted ? "[ MUTED ]" : "[ MUTE ]")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundColor(audioManager.isInputMuted ? .black : .white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(audioManager.isInputMuted ? Color.white : Color.white.opacity(0.12))
                            .clipShape(Rectangle())
                            .overlay(Rectangle().stroke(Color.white.opacity(0.4), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                    .focusEffectDisabled()
                }
                
                // Y2K Hatched Volume Bar
                HStack(spacing: 8) {
                    Y2KHatchedSlider(
                        value: Binding(
                            get: { audioManager.inputVolume },
                            set: { audioManager.setInputVolume($0) }
                        ),
                        onEditingChanged: { newVol in
                            audioManager.setInputVolume(newVol)
                        }
                    )
                    
                    Text("\(Int(audioManager.inputVolume * 100))%")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 32, alignment: .trailing)
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
        }
    }
    
    // MARK: - Y2K Monochromatic Source Switcher
    private var y2kSourceSwitcher: some View {
        HStack(spacing: 6) {
            Button(action: {
                selectedTab = .output
            }) {
                HStack(spacing: 6) {
                    Y2KStar(size: 10)
                        .foregroundColor(selectedTab == .output ? .black : .white)
                    Text("OUTPUT [\(audioManager.outputDevices.count)]")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(selectedTab == .output ? Color.white : Color.white.opacity(0.05))
                .foregroundColor(selectedTab == .output ? .black : .white.opacity(0.6))
                .clipShape(Rectangle())
                .overlay(Rectangle().stroke(Color.white.opacity(0.4), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
            
            Button(action: {
                selectedTab = .input
            }) {
                HStack(spacing: 6) {
                    Y2KStar(size: 10)
                        .foregroundColor(selectedTab == .input ? .black : .white)
                    Text("INPUT [\(audioManager.inputDevices.count)]")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(selectedTab == .input ? Color.white : Color.white.opacity(0.05))
                .foregroundColor(selectedTab == .input ? .black : .white.opacity(0.6))
                .clipShape(Rectangle())
                .overlay(Rectangle().stroke(Color.white.opacity(0.4), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
        }
        .padding(3)
        .background(Color.black.opacity(0.4))
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
                            .foregroundColor(.white.opacity(0.5))
                        Text("// NO_AUDIO_SOURCES")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
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
                                    Rectangle()
                                        .fill(isActive ? Color.white : Color.white.opacity(0.1))
                                        .frame(width: 26, height: 26)
                                        .overlay(Rectangle().stroke(Color.white.opacity(0.4), lineWidth: 0.5))
                                    
                                    Image(systemName: device.iconName)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(isActive ? .black : .white)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(device.name.uppercased())
                                        .font(.system(size: 11, weight: isActive ? .black : .bold, design: .monospaced))
                                        .foregroundColor(isActive ? .white : .white.opacity(0.85))
                                        .lineLimit(1)
                                    
                                    Text(isActive ? "✦ ACTIVE_SOURCE" : "AVAILABLE")
                                        .font(.system(size: 8, weight: .heavy, design: .monospaced))
                                        .foregroundColor(isActive ? .white : .white.opacity(0.4))
                                }
                                
                                Spacer()
                                
                                if isActive {
                                    Y2KStar(size: 12)
                                        .rotationEffect(.degrees(starRotation * 1.5))
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                isActive
                                    ? Color.white.opacity(0.15)
                                    : (isHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
                            )
                            .clipShape(Rectangle())
                            .overlay(
                                Rectangle()
                                    .stroke(isActive ? Color.white : Color.white.opacity(0.15), lineWidth: isActive ? 1 : 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .focusEffectDisabled()
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
    
    // MARK: - Y2K Decorative Scale Line
    private var y2kScaleDivider: some View {
        HStack(spacing: 2) {
            ForEach(0..<30) { i in
                Rectangle()
                    .fill(Color.white.opacity(i % 5 == 0 ? 0.5 : 0.2))
                    .frame(width: 1, height: i % 5 == 0 ? 6 : 3)
                if i < 29 { Spacer(minLength: 0) }
            }
        }
        .frame(height: 8)
    }
    
    // MARK: - Compact Mode View
    private var compactView: some View {
        VStack(spacing: 10) {
            // Output Section
            let currentOutput = audioManager.outputDevices.first(where: { $0.id == audioManager.currentOutputDeviceID })
            VStack(spacing: 5) {
                HStack {
                    HStack(spacing: 6) {
                        Y2KStar(size: 10)
                        Text(currentOutput?.name.uppercased() ?? "NO_OUTPUT")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button(action: {
                        audioManager.toggleOutputMute()
                    }) {
                        Text(audioManager.isOutputMuted ? "[ MUTED ]" : "[ MUTE ]")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .foregroundColor(audioManager.isOutputMuted ? .black : .white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(audioManager.isOutputMuted ? Color.white : Color.white.opacity(0.12))
                            .clipShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .focusEffectDisabled()
                }
                
                HStack(spacing: 6) {
                    Y2KHatchedSlider(
                        value: Binding(
                            get: { audioManager.outputVolume },
                            set: { audioManager.setOutputVolume($0) }
                        ),
                        onEditingChanged: { newVol in
                            audioManager.setOutputVolume(newVol)
                        }
                    )
                    
                    Text("\(Int(audioManager.outputVolume * 100))%")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 28, alignment: .trailing)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.15))
            
            // Input Section
            let currentInput = audioManager.inputDevices.first(where: { $0.id == audioManager.currentInputDeviceID })
            VStack(spacing: 5) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: currentInput?.iconName ?? "mic.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                        Text(currentInput?.name.uppercased() ?? "NO_INPUT")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button(action: {
                        audioManager.toggleInputMute()
                    }) {
                        Text(audioManager.isInputMuted ? "[ MUTED ]" : "[ MUTE ]")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .foregroundColor(audioManager.isInputMuted ? .black : .white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(audioManager.isInputMuted ? Color.white : Color.white.opacity(0.12))
                            .clipShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .focusEffectDisabled()
                }
                
                HStack(spacing: 6) {
                    Y2KHatchedSlider(
                        value: Binding(
                            get: { audioManager.inputVolume },
                            set: { audioManager.setInputVolume($0) }
                        ),
                        onEditingChanged: { newVol in
                            audioManager.setInputVolume(newVol)
                        }
                    )
                    
                    Text("\(Int(audioManager.inputVolume * 100))%")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 28, alignment: .trailing)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
    
    // MARK: - Footer
    private var footerView: some View {
        HStack {
            // Cycle Menu Bar Icon Button
            Button(action: {
                panelManager.cycleMenuBarIcon()
            }) {
                HStack(spacing: 4) {
                    Y2KStar(size: 9)
                    Text("[ ICON ]")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.08))
                .clipShape(Rectangle())
                .overlay(Rectangle().stroke(Color.white.opacity(0.25), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
            .help("Cycle Menu Bar Icon")
            
            // Launch at Login Toggle Button
            Button(action: {
                audioManager.toggleLaunchAtLogin()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "power")
                        .font(.system(size: 8))
                    Text(audioManager.isLaunchAtLoginEnabled ? "[ AUTO: ON ]" : "[ AUTO: OFF ]")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                }
                .foregroundColor(audioManager.isLaunchAtLoginEnabled ? .black : .white.opacity(0.8))
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(audioManager.isLaunchAtLoginEnabled ? Color.white : Color.white.opacity(0.08))
                .clipShape(Rectangle())
                .overlay(Rectangle().stroke(Color.white.opacity(0.25), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
            .help("Toggle Launch at Login")
            
            // Settings / Config Button
            Button(action: {
                SettingsWindowController.shared.showWindow(audioManager: audioManager)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 8))
                    Text("[ ⚙ CONFIG ]")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.08))
                .clipShape(Rectangle())
                .overlay(Rectangle().stroke(Color.white.opacity(0.25), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
            .help("Open Settings Window")
            
            Spacer()
            
            // Refresh Button
            Button(action: {
                audioManager.refreshDevices()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 9, weight: .bold))
                    Text("[ REFRESH ]")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.15))
                .clipShape(Rectangle())
                .overlay(Rectangle().stroke(Color.white.opacity(0.4), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
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
