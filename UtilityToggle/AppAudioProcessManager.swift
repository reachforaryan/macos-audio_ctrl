//
//  AppAudioProcessManager.swift
//  UtilityToggle
//
//  Per-App Audio Process Discovery & Volume Control via CoreAudio Process Taps.
//  Uses CATapDescription + AudioHardwareCreateProcessTap for real per-app volume.
//

import SwiftUI
import AppKit
import Combine
import CoreAudio
import AudioToolbox

// MARK: - Per-Process Tap Session
// Holds the CoreAudio tap + aggregate device for one process's audio control.
// Runs entirely off-main-actor; only the gain/mute values need synchronization.
final class ProcessTapSession {
    let pid: pid_t
    let audioObjectID: AudioObjectID
    private(set) var tapID: AudioObjectID = AudioObjectID(kAudioObjectUnknown)
    private(set) var aggregateDeviceID: AudioObjectID = AudioObjectID(kAudioObjectUnknown)
    private(set) var ioProcID: AudioDeviceIOProcID?
    private(set) var isActive: Bool = false
    
    // Thread-safe gain (read from IO proc on real-time thread)
    var gain: Float32 = 1.0
    
    init(pid: pid_t, audioObjectID: AudioObjectID) {
        self.pid = pid
        self.audioObjectID = audioObjectID
    }
    
    // Start the tap pipeline: CATapDescription -> Tap -> Aggregate -> IOProc
    func start() -> Bool {
        guard !isActive else { return true }
        
        // 1. Create the process tap
        let tapDesc = CATapDescription(stereoMixdownOfProcesses: [audioObjectID])
        tapDesc.name = "AudioCtrl_\(pid)"
        
        var newTapID: AudioObjectID = AudioObjectID(kAudioObjectUnknown)
        guard AudioHardwareCreateProcessTap(tapDesc, &newTapID) == noErr else {
            return false
        }
        self.tapID = newTapID
        
        // 2. Get tap UID
        guard let tapUID = getTapUID() else {
            AudioHardwareDestroyProcessTap(tapID)
            return false
        }
        
        // 3. Get default output device UID
        guard let outputUID = Self.getDefaultOutputUID() else {
            AudioHardwareDestroyProcessTap(tapID)
            return false
        }
        
        // 4. Create aggregate device with the tap
        let aggDesc: [String: Any] = [
            kAudioAggregateDeviceUIDKey as String: "com.audioctrl.\(pid)",
            kAudioAggregateDeviceNameKey as String: "AudioCtrl_\(pid)",
            kAudioAggregateDeviceIsPrivateKey as String: 1,
            kAudioAggregateDeviceSubDeviceListKey as String: [
                [kAudioSubDeviceUIDKey as String: outputUID]
            ],
            kAudioAggregateDeviceTapListKey as String: [
                [
                    kAudioSubTapUIDKey as String: tapUID,
                    kAudioSubTapDriftCompensationKey as String: 0
                ]
            ],
            kAudioAggregateDeviceTapAutoStartKey as String: 1
        ]
        
        var newAggID: AudioObjectID = AudioObjectID(kAudioObjectUnknown)
        guard AudioHardwareCreateAggregateDevice(aggDesc as CFDictionary, &newAggID) == noErr else {
            AudioHardwareDestroyProcessTap(tapID)
            return false
        }
        self.aggregateDeviceID = newAggID
        
        // 5. Create and start IO proc for gain scaling
        let sessionPtr = Unmanaged.passUnretained(self).toOpaque()
        var newIOProcID: AudioDeviceIOProcID?
        guard AudioDeviceCreateIOProcID(aggregateDeviceID, Self.ioProc, sessionPtr, &newIOProcID) == noErr,
              newIOProcID != nil else {
            cleanup()
            return false
        }
        self.ioProcID = newIOProcID
        
        guard AudioDeviceStart(aggregateDeviceID, ioProcID) == noErr else {
            cleanup()
            return false
        }
        
        isActive = true
        return true
    }
    
    // IO proc: reads tapped audio input -> applies gain -> writes to output
    private static let ioProc: AudioDeviceIOProc = { (device, now, inputData, inputTime, outputData, outputTime, clientData) -> OSStatus in
        guard let clientData = clientData else { return noErr }
        let session = Unmanaged<ProcessTapSession>.fromOpaque(clientData).takeUnretainedValue()
        let gain = session.gain
        
        let inBufList = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: inputData))
        let outBufList = UnsafeMutableAudioBufferListPointer(outputData)
        
        for i in 0..<min(inBufList.count, outBufList.count) {
            let inBuf = inBufList[i]
            let outBuf = outBufList[i]
            
            guard let inData = inBuf.mData?.assumingMemoryBound(to: Float32.self),
                  let outData = outBuf.mData?.assumingMemoryBound(to: Float32.self) else { continue }
            
            let frameCount = Int(min(inBuf.mDataByteSize, outBuf.mDataByteSize)) / MemoryLayout<Float32>.size
            for j in 0..<frameCount {
                outData[j] = inData[j] * gain
            }
        }
        
        return noErr
    }
    
    func cleanup() {
        if let ioProcID = ioProcID {
            AudioDeviceStop(aggregateDeviceID, ioProcID)
            AudioDeviceDestroyIOProcID(aggregateDeviceID, ioProcID)
            self.ioProcID = nil
        }
        if aggregateDeviceID != AudioObjectID(kAudioObjectUnknown) {
            AudioHardwareDestroyAggregateDevice(aggregateDeviceID)
            aggregateDeviceID = AudioObjectID(kAudioObjectUnknown)
        }
        if tapID != AudioObjectID(kAudioObjectUnknown) {
            AudioHardwareDestroyProcessTap(tapID)
            tapID = AudioObjectID(kAudioObjectUnknown)
        }
        isActive = false
    }
    
    // MARK: - Helpers
    private func getTapUID() -> String? {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioTapPropertyUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var uid: Unmanaged<CFString>?
        var sz = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        if AudioObjectGetPropertyData(tapID, &addr, 0, nil, &sz, &uid) == noErr {
            return uid?.takeUnretainedValue() as String?
        }
        return nil
    }
    
    static func getDefaultOutputUID() -> String? {
        var defaultOutputID: AudioObjectID = 0
        var propAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var propSize = UInt32(MemoryLayout<AudioObjectID>.size)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propAddr, 0, nil, &propSize, &defaultOutputID)
        
        var uidAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var uid: Unmanaged<CFString>?
        var uidSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        if AudioObjectGetPropertyData(defaultOutputID, &uidAddr, 0, nil, &uidSize, &uid) == noErr {
            return uid?.takeUnretainedValue() as String?
        }
        return nil
    }
    
    deinit {
        cleanup()
    }
}

// MARK: - App Audio Process Manager
@MainActor
public final class AppAudioProcessManager: ObservableObject {
    public static let shared = AppAudioProcessManager()
    
    @Published public var runningAppProcesses: [AppAudioProcess] = []
    
    private var timer: Timer?
    private var tapSessions: [String: ProcessTapSession] = [:]  // keyed by bundleID
    
    init() {
        refreshActiveProcesses()
        setupWorkspaceListeners()
        startPeriodicCheck()
    }
    
    deinit {
        timer?.invalidate()
        for (_, session) in tapSessions {
            session.cleanup()
        }
    }
    
    // MARK: - Core Discovery
    public func refreshActiveProcesses() {
        let audioObjects = getCoreAudioProcessObjects()
        let runningApps = NSWorkspace.shared.runningApplications
        
        // PID -> NSRunningApplication (only user-facing .regular apps)
        var pidToApp: [pid_t: NSRunningApplication] = [:]
        for app in runningApps {
            guard app.activationPolicy == .regular else { continue }
            guard app.bundleIdentifier != Bundle.main.bundleIdentifier else { continue }
            pidToApp[app.processIdentifier] = app
        }
        
        // Intersect: CoreAudio process objects that map to user-facing apps
        var seen = Set<String>()
        var updatedList: [AppAudioProcess] = []
        
        for (objID, pid) in audioObjects {
            guard let app = pidToApp[pid] else { continue }
            guard let bundleID = app.bundleIdentifier, let name = app.localizedName else { continue }
            guard !seen.contains(bundleID) else { continue }
            seen.insert(bundleID)
            
            let isPlayingOutput = checkIsRunningOutput(audioObjectID: objID)
            let icon = app.icon ?? NSImage(named: NSImage.applicationIconName) ?? NSImage()
            let storedVol = loadVolume(sessionID: bundleID)
            let storedMute = loadMute(sessionID: bundleID)
            
            let process = AppAudioProcess(
                id: bundleID,
                pid: pid,
                audioObjectID: objID,
                bundleIdentifier: bundleID,
                name: name,
                icon: icon,
                volume: storedVol,
                isMuted: storedMute,
                isPlayingAudio: isPlayingOutput
            )
            updatedList.append(process)
            
            // Ensure tap session exists and gain is synced
            ensureTapSession(for: process)
        }
        
        // Remove tap sessions for apps that are no longer present
        let currentBundleIDs = Set(updatedList.map { $0.id })
        for key in tapSessions.keys {
            if !currentBundleIDs.contains(key) {
                tapSessions[key]?.cleanup()
                tapSessions.removeValue(forKey: key)
            }
        }
        
        self.runningAppProcesses = updatedList.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    // MARK: - Volume & Mute Actions
    public func setAppVolume(sessionID: String, volume: Float) {
        let clamped = max(0.0, min(AppConfig.Audio.maxAppVolumeBoost, volume))
        guard let index = runningAppProcesses.firstIndex(where: { $0.id == sessionID }) else { return }
        runningAppProcesses[index].volume = clamped
        saveVolume(sessionID: sessionID, volume: clamped)
        updateTapGain(sessionID: sessionID)
    }
    
    public func toggleAppMute(sessionID: String) {
        guard let index = runningAppProcesses.firstIndex(where: { $0.id == sessionID }) else { return }
        runningAppProcesses[index].isMuted.toggle()
        saveMute(sessionID: sessionID, isMuted: runningAppProcesses[index].isMuted)
        updateTapGain(sessionID: sessionID)
    }
    
    // MARK: - Tap Session Management
    private func ensureTapSession(for process: AppAudioProcess) {
        if tapSessions[process.id] == nil {
            let session = ProcessTapSession(pid: process.pid, audioObjectID: process.audioObjectID)
            let started = session.start()
            if started {
                tapSessions[process.id] = session
                #if DEBUG
                print("[TapMgr] Tap started for \(process.name) (PID \(process.pid))")
                #endif
            } else {
                #if DEBUG
                print("[TapMgr] Tap FAILED for \(process.name) (PID \(process.pid))")
                #endif
            }
        }
        updateTapGain(sessionID: process.id)
    }
    
    private func updateTapGain(sessionID: String) {
        guard let process = runningAppProcesses.first(where: { $0.id == sessionID }),
              let session = tapSessions[sessionID] else { return }
        session.gain = process.isMuted ? 0.0 : process.volume
    }
    
    // MARK: - CoreAudio Queries
    private func getCoreAudioProcessObjects() -> [(audioObjectID: AudioObjectID, pid: pid_t)] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyProcessObjectList,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize) == noErr,
              dataSize > 0 else { return [] }
        
        let count = Int(dataSize) / MemoryLayout<AudioObjectID>.size
        var processObjects = [AudioObjectID](repeating: 0, count: count)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize, &processObjects) == noErr else { return [] }
        
        var results: [(AudioObjectID, pid_t)] = []
        for procObj in processObjects {
            var pidAddr = AudioObjectPropertyAddress(
                mSelector: kAudioProcessPropertyPID,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            var pid: pid_t = 0
            var pidSize = UInt32(MemoryLayout<pid_t>.size)
            if AudioObjectGetPropertyData(procObj, &pidAddr, 0, nil, &pidSize, &pid) == noErr, pid > 0 {
                results.append((procObj, pid))
            }
        }
        return results
    }
    
    private func checkIsRunningOutput(audioObjectID: AudioObjectID) -> Bool {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioProcessPropertyIsRunningOutput,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var isRunning: UInt32 = 0
        var sz = UInt32(MemoryLayout<UInt32>.size)
        if AudioObjectGetPropertyData(audioObjectID, &addr, 0, nil, &sz, &isRunning) == noErr {
            return isRunning != 0
        }
        return false
    }
    
    // MARK: - Persistence
    private func loadVolume(sessionID: String) -> Float {
        let key = AppConfig.Strings.appVolumeStoragePrefix + sessionID + "_vol"
        return UserDefaults.standard.object(forKey: key) != nil
            ? UserDefaults.standard.float(forKey: key)
            : AppConfig.Audio.defaultAppVolume
    }
    
    private func saveVolume(sessionID: String, volume: Float) {
        UserDefaults.standard.set(volume, forKey: AppConfig.Strings.appVolumeStoragePrefix + sessionID + "_vol")
    }
    
    private func loadMute(sessionID: String) -> Bool {
        UserDefaults.standard.bool(forKey: AppConfig.Strings.appVolumeStoragePrefix + sessionID + "_mute")
    }
    
    private func saveMute(sessionID: String, isMuted: Bool) {
        UserDefaults.standard.set(isMuted, forKey: AppConfig.Strings.appVolumeStoragePrefix + sessionID + "_mute")
    }
    
    // MARK: - Listeners
    private func setupWorkspaceListeners() {
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refreshActiveProcesses() }
        }
        nc.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refreshActiveProcesses() }
        }
    }
    
    private func startPeriodicCheck() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refreshActiveProcesses() }
        }
    }
}
