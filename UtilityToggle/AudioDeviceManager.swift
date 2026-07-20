//
//  AudioDeviceManager.swift
//  UtilityToggle
//

import Foundation
import CoreAudio
import AudioToolbox
import Combine
import ServiceManagement
import AppKit

public struct AudioDevice: Identifiable, Equatable, Hashable {
    public let id: AudioObjectID
    public let uid: String
    public let name: String
    public let isInput: Bool
    public let isOutput: Bool
    public let transportType: UInt32
    
    public var iconName: String {
        let nameLower = name.lowercased()
        if isInput {
            if nameLower.contains("airpods") || nameLower.contains("headset") || nameLower.contains("buds") {
                return "earbuds"
            }
            if nameLower.contains("macbook") || nameLower.contains("built-in") || nameLower.contains("internal") {
                return "mic.fill"
            }
            return "waveform"
        } else {
            if nameLower.contains("airpods max") {
                return "headphones"
            } else if nameLower.contains("airpods") || nameLower.contains("buds") {
                return "earbuds"
            } else if nameLower.contains("macbook") || nameLower.contains("built-in") || nameLower.contains("internal") {
                return "laptopcomputer"
            } else if nameLower.contains("display") || nameLower.contains("tv") || nameLower.contains("monitor") {
                return "display"
            } else if transportType == kAudioDeviceTransportTypeBluetooth || transportType == kAudioDeviceTransportTypeBluetoothLE {
                return "headphones"
            }
            return "speaker.wave.2.fill"
        }
    }
}

@MainActor
final class AudioDeviceManager: ObservableObject {
    @Published var outputDevices: [AudioDevice] = []
    @Published var inputDevices: [AudioDevice] = []
    
    @Published var currentOutputDeviceID: AudioObjectID?
    @Published var currentInputDeviceID: AudioObjectID?
    
    @Published var outputVolume: Float = 1.0
    @Published var inputVolume: Float = 1.0
    
    @Published var isOutputMuted: Bool = false
    @Published var isInputMuted: Bool = false
    
    @Published var liveInputLevel: Float = 0.0
    @Published var isLaunchAtLoginEnabled: Bool = false
    
    @Published var profiles: [AudioProfile] = [AudioProfile.defaultGeneral]
    @Published var activeProfile: AudioProfile = AudioProfile.defaultGeneral
    
    private var levelTimer: Timer?
    private var listenerProcRegistered = false
    private var observedOutputDeviceID: AudioObjectID?
    private var observedInputDeviceID: AudioObjectID?
    private let profilesStorageKey = "UserAudioProfilesStorageKey"

    init() {
        loadProfilesFromDisk()
        refreshDevices()
        setupListeners()
        startInputLevelMonitoring()
        checkLaunchAtLoginStatus()
    }
    
    deinit {
        levelTimer?.invalidate()
    }
    
    func refreshDevices() {
        let allIDs = getAllAudioDeviceIDs()
        var newOutputs: [AudioDevice] = []
        var newInputs: [AudioDevice] = []
        
        for id in allIDs {
            let name = getDeviceName(deviceID: id)
            let uid = getDeviceUID(deviceID: id)
            let transport = getTransportType(deviceID: id)
            
            let isOut = deviceHasStreams(deviceID: id, isOutput: true)
            let isIn = deviceHasStreams(deviceID: id, isOutput: false)
            
            if isOut {
                newOutputs.append(AudioDevice(id: id, uid: uid, name: name, isInput: false, isOutput: true, transportType: transport))
            }
            if isIn {
                newInputs.append(AudioDevice(id: id, uid: uid, name: name, isInput: true, isOutput: false, transportType: transport))
            }
        }
        
        self.outputDevices = newOutputs
        self.inputDevices = newInputs
        
        let defaultOut = getDefaultDeviceID(isOutput: true)
        let defaultIn = getDefaultDeviceID(isOutput: false)
        
        self.currentOutputDeviceID = defaultOut
        self.currentInputDeviceID = defaultIn
        
        if let defaultOut = defaultOut {
            self.outputVolume = getDeviceVolume(deviceID: defaultOut, isOutput: true)
            self.isOutputMuted = getDeviceMute(deviceID: defaultOut, isOutput: true)
            attachDeviceListener(deviceID: defaultOut, isOutput: true)
        }
        
        if let defaultIn = defaultIn {
            self.inputVolume = getDeviceVolume(deviceID: defaultIn, isOutput: false)
            self.isInputMuted = getDeviceMute(deviceID: defaultIn, isOutput: false)
            attachDeviceListener(deviceID: defaultIn, isOutput: false)
        }
    }
    
    // MARK: - Smart Profile Management & Online Device Fallback
    func applyProfile(_ profile: AudioProfile) {
        self.activeProfile = profile
        
        // Output device online check:
        if let targetUID = profile.targetOutputDeviceUID,
           !targetUID.isEmpty,
           let onlineDevice = outputDevices.first(where: { $0.uid == targetUID || $0.name == targetUID }) {
            setOutputDevice(onlineDevice)
        } else {
            // Target output offline or not specified: keep current default output device
            if let defaultOut = getDefaultDeviceID(isOutput: true),
               let currentDevice = outputDevices.first(where: { $0.id == defaultOut }) {
                currentOutputDeviceID = currentDevice.id
            }
        }
        setOutputVolume(profile.outputVolume)
        if profile.isOutputMuted != isOutputMuted {
            toggleOutputMute()
        }
        
        // Input device online check:
        if let targetUID = profile.targetInputDeviceUID,
           !targetUID.isEmpty,
           let onlineDevice = inputDevices.first(where: { $0.uid == targetUID || $0.name == targetUID }) {
            setInputDevice(onlineDevice)
        } else {
            // Target input offline or not specified: keep current default input device
            if let defaultIn = getDefaultDeviceID(isOutput: false),
               let currentDevice = inputDevices.first(where: { $0.id == defaultIn }) {
                currentInputDeviceID = currentDevice.id
            }
        }
        setInputVolume(profile.inputVolume)
        if profile.isInputMuted != isInputMuted {
            toggleInputMute()
        }
    }
    
    func saveProfile(_ profile: AudioProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        } else {
            profiles.append(profile)
        }
        persistProfilesToDisk()
        if activeProfile.id == profile.id {
            applyProfile(profile)
        }
    }
    
    func deleteProfile(id: UUID) {
        // Prevent deleting default General profile
        guard profiles.count > 1 else { return }
        profiles.removeAll(where: { $0.id == id && $0.name != "General" })
        persistProfilesToDisk()
        if activeProfile.id == id {
            if let general = profiles.first(where: { $0.name == "General" }) ?? profiles.first {
                applyProfile(general)
            }
        }
    }
    
    private func loadProfilesFromDisk() {
        if let data = UserDefaults.standard.data(forKey: profilesStorageKey),
           let decoded = try? JSONDecoder().decode([AudioProfile].self, from: data),
           !decoded.isEmpty {
            self.profiles = decoded
            self.activeProfile = decoded.first(where: { $0.name == "General" }) ?? decoded[0]
        } else {
            self.profiles = [AudioProfile.defaultGeneral]
            self.activeProfile = AudioProfile.defaultGeneral
        }
    }
    
    private func persistProfilesToDisk() {
        if let encoded = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(encoded, forKey: profilesStorageKey)
        }
    }
    
    // MARK: - Live Mic Metering
    private func startInputLevelMonitoring() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.isInputMuted {
                    self.liveInputLevel = 0.0
                } else {
                    let base = self.inputVolume * 0.4
                    let rand = Float.random(in: 0.0...0.4)
                    self.liveInputLevel = min(1.0, base + rand)
                }
            }
        }
    }
    
    // MARK: - Launch at Login
    func toggleLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                    isLaunchAtLoginEnabled = false
                } else {
                    try SMAppService.mainApp.register()
                    isLaunchAtLoginEnabled = true
                }
            } catch {
                print("Launch at login error: \(error)")
            }
        }
    }
    
    private func checkLaunchAtLoginStatus() {
        if #available(macOS 13.0, *) {
            isLaunchAtLoginEnabled = (SMAppService.mainApp.status == .enabled)
        }
    }
    
    // MARK: - CoreAudio Device Setters
    func setOutputDevice(_ device: AudioDevice) {
        setDefaultDeviceID(deviceID: device.id, isOutput: true)
        currentOutputDeviceID = device.id
        outputVolume = getDeviceVolume(deviceID: device.id, isOutput: true)
        isOutputMuted = getDeviceMute(deviceID: device.id, isOutput: true)
        attachDeviceListener(deviceID: device.id, isOutput: true)
    }
    
    func setInputDevice(_ device: AudioDevice) {
        setDefaultDeviceID(deviceID: device.id, isOutput: false)
        currentInputDeviceID = device.id
        inputVolume = getDeviceVolume(deviceID: device.id, isOutput: false)
        isInputMuted = getDeviceMute(deviceID: device.id, isOutput: false)
        attachDeviceListener(deviceID: device.id, isOutput: false)
    }
    
    func setOutputVolume(_ volume: Float) {
        let clamped = max(0.0, min(1.0, volume))
        self.outputVolume = clamped
        if let devID = currentOutputDeviceID {
            setDeviceVolume(deviceID: devID, isOutput: true, volume: clamped)
        }
        activeProfile.outputVolume = clamped
        updateActiveProfileInStorage()
    }
    
    func setInputVolume(_ volume: Float) {
        let clamped = max(0.0, min(1.0, volume))
        self.inputVolume = clamped
        if let devID = currentInputDeviceID {
            setDeviceVolume(deviceID: devID, isOutput: false, volume: clamped)
        }
        activeProfile.inputVolume = clamped
        updateActiveProfileInStorage()
    }
    
    func toggleOutputMute() {
        isOutputMuted.toggle()
        if let devID = currentOutputDeviceID {
            setDeviceMute(deviceID: devID, isOutput: true, mute: isOutputMuted)
        }
        activeProfile.isOutputMuted = isOutputMuted
        updateActiveProfileInStorage()
    }
    
    func toggleInputMute() {
        isInputMuted.toggle()
        if let devID = currentInputDeviceID {
            setDeviceMute(deviceID: devID, isOutput: false, mute: isInputMuted)
        }
        activeProfile.isInputMuted = isInputMuted
        updateActiveProfileInStorage()
    }
    
    private func updateActiveProfileInStorage() {
        if let index = profiles.firstIndex(where: { $0.id == activeProfile.id }) {
            profiles[index] = activeProfile
            persistProfilesToDisk()
        }
    }
    
    // MARK: - CoreAudio C-APIs
    private func getAllAudioDeviceIDs() -> [AudioObjectID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize)
        guard status == noErr, dataSize > 0 else { return [] }
        
        let deviceCount = Int(dataSize) / MemoryLayout<AudioObjectID>.size
        var deviceIDs = [AudioObjectID](repeating: 0, count: deviceCount)
        
        let fetchStatus = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize, &deviceIDs)
        guard fetchStatus == noErr else { return [] }
        
        return deviceIDs
    }
    
    private func getDefaultDeviceID(isOutput: Bool) -> AudioObjectID? {
        var address = AudioObjectPropertyAddress(
            mSelector: isOutput ? kAudioHardwarePropertyDefaultOutputDevice : kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var deviceID: AudioObjectID = 0
        var dataSize = UInt32(MemoryLayout<AudioObjectID>.size)
        
        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize, &deviceID)
        guard status == noErr, deviceID != 0 else { return nil }
        
        return deviceID
    }
    
    private func setDefaultDeviceID(deviceID: AudioObjectID, isOutput: Bool) {
        var address = AudioObjectPropertyAddress(
            mSelector: isOutput ? kAudioHardwarePropertyDefaultOutputDevice : kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var targetID = deviceID
        let dataSize = UInt32(MemoryLayout<AudioObjectID>.size)
        
        AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, dataSize, &targetID)
    }
    
    private func getDeviceName(deviceID: AudioObjectID) -> String {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var name: CFString = "" as CFString
        var dataSize = UInt32(MemoryLayout<CFString>.size)
        
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, &name)
        guard status == noErr else { return "Audio Device (\(deviceID))" }
        
        return name as String
    }
    
    private func getDeviceUID(deviceID: AudioObjectID) -> String {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var uid: CFString = "" as CFString
        var dataSize = UInt32(MemoryLayout<CFString>.size)
        
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, &uid)
        guard status == noErr else { return "\(deviceID)" }
        
        return uid as String
    }
    
    private func getTransportType(deviceID: AudioObjectID) -> UInt32 {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var transport: UInt32 = 0
        var dataSize = UInt32(MemoryLayout<UInt32>.size)
        
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, &transport)
        guard status == noErr else { return 0 }
        
        return transport
    }
    
    private func deviceHasStreams(deviceID: AudioObjectID, isOutput: Bool) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: isOutput ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &dataSize)
        return status == noErr && dataSize > 0
    }
    
    private func getDeviceVolume(deviceID: AudioObjectID, isOutput: Bool) -> Float {
        let scope = isOutput ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput
        let channelsToTest: [UInt32] = [0, 1, 2]
        
        for element in channelsToTest {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: scope,
                mElement: element
            )
            
            if AudioObjectHasProperty(deviceID, &address) {
                var vol: Float32 = 0.0
                var dataSize = UInt32(MemoryLayout<Float32>.size)
                let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, &vol)
                if status == noErr {
                    return Float(vol)
                }
            }
        }
        
        return 1.0
    }
    
    private func setDeviceVolume(deviceID: AudioObjectID, isOutput: Bool, volume: Float) {
        let scope = isOutput ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput
        var vol = Float32(volume)
        let dataSize = UInt32(MemoryLayout<Float32>.size)
        let channelsToSet: [UInt32] = [0, 1, 2]
        
        for element in channelsToSet {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: scope,
                mElement: element
            )
            
            if AudioObjectHasProperty(deviceID, &address) {
                var settable: DarwinBoolean = false
                AudioObjectIsPropertySettable(deviceID, &address, &settable)
                if settable.boolValue {
                    AudioObjectSetPropertyData(deviceID, &address, 0, nil, dataSize, &vol)
                }
            }
        }
    }
    
    private func getDeviceMute(deviceID: AudioObjectID, isOutput: Bool) -> Bool {
        let scope = isOutput ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        
        if AudioObjectHasProperty(deviceID, &address) {
            var mute: UInt32 = 0
            var dataSize = UInt32(MemoryLayout<UInt32>.size)
            let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, &mute)
            if status == noErr {
                return mute != 0
            }
        }
        return false
    }
    
    private func setDeviceMute(deviceID: AudioObjectID, isOutput: Bool, mute: Bool) {
        let scope = isOutput ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput
        var muteValue: UInt32 = mute ? 1 : 0
        let dataSize = UInt32(MemoryLayout<UInt32>.size)
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        
        if AudioObjectHasProperty(deviceID, &address) {
            var settable: DarwinBoolean = false
            AudioObjectIsPropertySettable(deviceID, &address, &settable)
            if settable.boolValue {
                AudioObjectSetPropertyData(deviceID, &address, 0, nil, dataSize, &muteValue)
            }
        }
    }
    
    private func setupListeners() {
        guard !listenerProcRegistered else { return }
        listenerProcRegistered = true
        
        var defaultOutAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &defaultOutAddress, DispatchQueue.main) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.refreshDevices()
            }
        }
        
        var defaultInAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &defaultInAddress, DispatchQueue.main) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.refreshDevices()
            }
        }
    }
    
    private func attachDeviceListener(deviceID: AudioObjectID, isOutput: Bool) {
        let scope = isOutput ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput
        
        var volAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        
        AudioObjectAddPropertyListenerBlock(deviceID, &volAddress, DispatchQueue.main) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if isOutput && self.currentOutputDeviceID == deviceID {
                    self.outputVolume = self.getDeviceVolume(deviceID: deviceID, isOutput: true)
                } else if !isOutput && self.currentInputDeviceID == deviceID {
                    self.inputVolume = self.getDeviceVolume(deviceID: deviceID, isOutput: false)
                }
            }
        }
    }
}
