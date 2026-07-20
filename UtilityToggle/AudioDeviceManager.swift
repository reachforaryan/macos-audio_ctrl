//
//  AudioDeviceManager.swift
//  UtilityToggle
//

import Foundation
import CoreAudio
import AudioToolbox
import Combine

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
    
    private var listenerProcRegistered = false
    private var observedOutputDeviceID: AudioObjectID?
    private var observedInputDeviceID: AudioObjectID?

    init() {
        refreshDevices()
        setupListeners()
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
        }
        if let defaultIn = defaultIn {
            self.inputVolume = getDeviceVolume(deviceID: defaultIn, isOutput: false)
            self.isInputMuted = getDeviceMute(deviceID: defaultIn, isOutput: false)
        }
        
        attachDeviceLevelListeners(outputID: defaultOut, inputID: defaultIn)
    }
    
    func setOutputDevice(_ device: AudioDevice) {
        setDefaultDeviceID(deviceID: device.id, isOutput: true)
        refreshDevices()
    }
    
    func setInputDevice(_ device: AudioDevice) {
        setDefaultDeviceID(deviceID: device.id, isOutput: false)
        refreshDevices()
    }
    
    func setOutputVolume(_ volume: Float) {
        self.outputVolume = volume
        if let devID = currentOutputDeviceID {
            setDeviceVolume(deviceID: devID, volume: volume, isOutput: true)
        }
    }
    
    func setInputVolume(_ volume: Float) {
        self.inputVolume = volume
        if let devID = currentInputDeviceID {
            setDeviceVolume(deviceID: devID, volume: volume, isOutput: false)
        }
    }
    
    func toggleOutputMute() {
        let newMute = !isOutputMuted
        self.isOutputMuted = newMute
        if let devID = currentOutputDeviceID {
            setDeviceMute(deviceID: devID, isMuted: newMute, isOutput: true)
        }
    }
    
    func toggleInputMute() {
        let newMute = !isInputMuted
        self.isInputMuted = newMute
        if let devID = currentInputDeviceID {
            setDeviceMute(deviceID: devID, isMuted: newMute, isOutput: false)
        }
    }
    
    // MARK: - CoreAudio Low Level Helpers
    
    private func getAllAudioDeviceIDs() -> [AudioObjectID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize)
        guard status == noErr, dataSize > 0 else { return [] }
        
        let count = Int(dataSize) / MemoryLayout<AudioObjectID>.size
        var deviceIDs = [AudioObjectID](repeating: 0, count: count)
        let getStatus = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize, &deviceIDs)
        guard getStatus == noErr else { return [] }
        return deviceIDs
    }
    
    private func getDefaultDeviceID(isOutput: Bool) -> AudioObjectID? {
        var address = AudioObjectPropertyAddress(
            mSelector: isOutput ? kAudioHardwarePropertyDefaultOutputDevice : kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID: AudioObjectID = 0
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID)
        return (status == noErr && deviceID != 0) ? deviceID : nil
    }
    
    private func setDefaultDeviceID(deviceID: AudioObjectID, isOutput: Bool) {
        var address = AudioObjectPropertyAddress(
            mSelector: isOutput ? kAudioHardwarePropertyDefaultOutputDevice : kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var devID = deviceID
        let size = UInt32(MemoryLayout<AudioObjectID>.size)
        AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, size, &devID)
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
    
    private func getDeviceName(deviceID: AudioObjectID) -> String {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var name: CFString = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &name)
        if status == noErr {
            return name as String
        }
        return "Audio Device \(deviceID)"
    }
    
    private func getDeviceUID(deviceID: AudioObjectID) -> String {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var uid: CFString = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &uid)
        if status == noErr {
            return uid as String
        }
        return "\(deviceID)"
    }
    
    private func getTransportType(deviceID: AudioObjectID) -> UInt32 {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var transportType: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &transportType)
        return status == noErr ? transportType : 0
    }
    
    private func getDeviceVolume(deviceID: AudioObjectID, isOutput: Bool) -> Float {
        let scope = isOutput ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput
        
        // Try channels: 0 (Main/Master), 1 (Left), 2 (Right)
        for element in [AudioObjectPropertyElement(kAudioObjectPropertyElementMain), 1, 2] {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: scope,
                mElement: element
            )
            if AudioObjectHasProperty(deviceID, &address) {
                var volume: Float32 = 0.0
                var size = UInt32(MemoryLayout<Float32>.size)
                let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &volume)
                if status == noErr {
                    return volume
                }
            }
        }
        return 1.0
    }
    
    private func setDeviceVolume(deviceID: AudioObjectID, volume: Float, isOutput: Bool) {
        let scope = isOutput ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput
        var vol = volume
        let size = UInt32(MemoryLayout<Float32>.size)
        
        var masterAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        if AudioObjectHasProperty(deviceID, &masterAddr) {
            AudioObjectSetPropertyData(deviceID, &masterAddr, 0, nil, size, &vol)
        } else {
            for ch in 1...2 {
                var chAddr = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyVolumeScalar,
                    mScope: scope,
                    mElement: UInt32(ch)
                )
                if AudioObjectHasProperty(deviceID, &chAddr) {
                    AudioObjectSetPropertyData(deviceID, &chAddr, 0, nil, size, &vol)
                }
            }
        }
    }
    
    private func getDeviceMute(deviceID: AudioObjectID, isOutput: Bool) -> Bool {
        let scope = isOutput ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput
        
        for element in [AudioObjectPropertyElement(kAudioObjectPropertyElementMain), 1, 2] {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyMute,
                mScope: scope,
                mElement: element
            )
            if AudioObjectHasProperty(deviceID, &address) {
                var muted: UInt32 = 0
                var size = UInt32(MemoryLayout<UInt32>.size)
                let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &muted)
                if status == noErr {
                    return muted != 0
                }
            }
        }
        return false
    }
    
    private func setDeviceMute(deviceID: AudioObjectID, isMuted: Bool, isOutput: Bool) {
        let scope = isOutput ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput
        var muteVal: UInt32 = isMuted ? 1 : 0
        let size = UInt32(MemoryLayout<UInt32>.size)
        
        for element in [AudioObjectPropertyElement(kAudioObjectPropertyElementMain), 1, 2] {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyMute,
                mScope: scope,
                mElement: element
            )
            if AudioObjectHasProperty(deviceID, &address) {
                AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &muteVal)
            }
        }
    }
    
    private func setupListeners() {
        guard !listenerProcRegistered else { return }
        listenerProcRegistered = true
        
        var defaultOutAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &defaultOutAddr, DispatchQueue.main) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.refreshDevices()
            }
        }
        
        var defaultInAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &defaultInAddr, DispatchQueue.main) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.refreshDevices()
            }
        }
        
        var devicesAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &devicesAddr, DispatchQueue.main) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.refreshDevices()
            }
        }
    }
    
    private func attachDeviceLevelListeners(outputID: AudioObjectID?, inputID: AudioObjectID?) {
        if observedOutputDeviceID != outputID, let outputID = outputID {
            observedOutputDeviceID = outputID
            
            for element in [AudioObjectPropertyElement(kAudioObjectPropertyElementMain), 1, 2] {
                var volAddr = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyVolumeScalar,
                    mScope: kAudioDevicePropertyScopeOutput,
                    mElement: element
                )
                AudioObjectAddPropertyListenerBlock(outputID, &volAddr, DispatchQueue.main) { [weak self] _, _ in
                    Task { @MainActor [weak self] in
                        if let devID = self?.currentOutputDeviceID {
                            self?.outputVolume = self?.getDeviceVolume(deviceID: devID, isOutput: true) ?? 1.0
                        }
                    }
                }
                
                var muteAddr = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyMute,
                    mScope: kAudioDevicePropertyScopeOutput,
                    mElement: element
                )
                AudioObjectAddPropertyListenerBlock(outputID, &muteAddr, DispatchQueue.main) { [weak self] _, _ in
                    Task { @MainActor [weak self] in
                        if let devID = self?.currentOutputDeviceID {
                            self?.isOutputMuted = self?.getDeviceMute(deviceID: devID, isOutput: true) ?? false
                        }
                    }
                }
            }
        }
        
        if observedInputDeviceID != inputID, let inputID = inputID {
            observedInputDeviceID = inputID
            
            for element in [AudioObjectPropertyElement(kAudioObjectPropertyElementMain), 1, 2] {
                var volAddr = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyVolumeScalar,
                    mScope: kAudioDevicePropertyScopeInput,
                    mElement: element
                )
                AudioObjectAddPropertyListenerBlock(inputID, &volAddr, DispatchQueue.main) { [weak self] _, _ in
                    Task { @MainActor [weak self] in
                        if let devID = self?.currentInputDeviceID {
                            self?.inputVolume = self?.getDeviceVolume(deviceID: devID, isOutput: false) ?? 1.0
                        }
                    }
                }
                
                var muteAddr = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyMute,
                    mScope: kAudioDevicePropertyScopeInput,
                    mElement: element
                )
                AudioObjectAddPropertyListenerBlock(inputID, &muteAddr, DispatchQueue.main) { [weak self] _, _ in
                    Task { @MainActor [weak self] in
                        if let devID = self?.currentInputDeviceID {
                            self?.isInputMuted = self?.getDeviceMute(deviceID: devID, isOutput: false) ?? false
                        }
                    }
                }
            }
        }
    }
}
