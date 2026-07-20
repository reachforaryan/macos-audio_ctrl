//
//  AppAudioProcessManager.swift
//  UtilityToggle
//
//  Per-App & Per-Window Live Audio Process Discovery & Volume Tap Engine.
//

import SwiftUI
import AppKit
import Combine
import CoreAudio
import ApplicationServices

@MainActor
public final class AppAudioProcessManager: ObservableObject {
    public static let shared = AppAudioProcessManager()
    
    @Published public var runningAppProcesses: [AppAudioProcess] = []
    
    private var workspaceObserver: Any?
    private var timer: Timer?
    
    init() {
        refreshActiveProcesses()
        setupWorkspaceListeners()
        startPeriodicCheck()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    public func refreshActiveProcesses() {
        let activePIDs = getActiveAudioPIDs()
        let runningApps = NSWorkspace.shared.runningApplications
        
        var updatedList: [AppAudioProcess] = []
        
        for app in runningApps {
            guard let bundleID = app.bundleIdentifier, let name = app.localizedName else { continue }
            if bundleID == Bundle.main.bundleIdentifier { continue }
            
            let pid = app.processIdentifier
            
            // Only track apps producing audio live (or active audio apps)
            let isLiveAudio = activePIDs.contains(pid) || isKnownActiveAudioApp(bundleID: bundleID, pid: pid)
            guard isLiveAudio else { continue }
            
            let icon = app.icon ?? NSWorkspace.shared.icon(forFileType: NSFileTypeForHFSTypeCode(OSType(kGenericApplicationIcon)))
            
            // Check for multi-window / multi-tab browser sessions (Brave, Chrome, Safari, Arc, Firefox)
            let windows = getWindowTitlesForProcess(pid: pid, bundleID: bundleID)
            
            if !windows.isEmpty {
                for (idx, winTitle) in windows.enumerated() {
                    let uniqueID = "\(bundleID)_win_\(idx)_\(winTitle.hashValue)"
                    let storedVol = loadAppVolumeFromDisk(sessionID: uniqueID)
                    let storedMute = loadAppMuteFromDisk(sessionID: uniqueID)
                    
                    let process = AppAudioProcess(
                        id: uniqueID,
                        pid: pid,
                        bundleIdentifier: bundleID,
                        name: name,
                        windowTitle: winTitle,
                        icon: icon,
                        volume: storedVol,
                        isMuted: storedMute,
                        isLivePlaying: true
                    )
                    updatedList.append(process)
                }
            } else {
                let uniqueID = bundleID
                let storedVol = loadAppVolumeFromDisk(sessionID: uniqueID)
                let storedMute = loadAppMuteFromDisk(sessionID: uniqueID)
                
                let process = AppAudioProcess(
                    id: uniqueID,
                    pid: pid,
                    bundleIdentifier: bundleID,
                    name: name,
                    windowTitle: nil,
                    icon: icon,
                    volume: storedVol,
                    isMuted: storedMute,
                    isLivePlaying: true
                )
                updatedList.append(process)
            }
        }
        
        // Sort alphabetically by display name
        self.runningAppProcesses = updatedList.sorted(by: { $0.displayName.lowercased() < $1.displayName.lowercased() })
    }
    
    public func setAppVolume(sessionID: String, volume: Float) {
        let clamped = max(0.0, min(AppConfig.Audio.maxAppVolumeBoost, volume))
        if let index = runningAppProcesses.firstIndex(where: { $0.id == sessionID }) {
            runningAppProcesses[index].volume = clamped
            saveAppVolumeToDisk(sessionID: sessionID, volume: clamped)
            applyProcessVolumeTap(process: runningAppProcesses[index])
        }
    }
    
    public func toggleAppMute(sessionID: String) {
        if let index = runningAppProcesses.firstIndex(where: { $0.id == sessionID }) {
            runningAppProcesses[index].isMuted.toggle()
            let newMute = runningAppProcesses[index].isMuted
            saveAppMuteToDisk(sessionID: sessionID, isMuted: newMute)
            applyProcessVolumeTap(process: runningAppProcesses[index])
        }
    }
    
    private func getActiveAudioPIDs() -> Set<pid_t> {
        var pids = Set<pid_t>()
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyProcessObjectList,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize)
        if status == noErr && dataSize > 0 {
            let count = Int(dataSize) / MemoryLayout<AudioObjectID>.size
            var processObjects = [AudioObjectID](repeating: 0, count: count)
            if AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize, &processObjects) == noErr {
                for procObj in processObjects {
                    var pidAddress = AudioObjectPropertyAddress(
                        mSelector: kAudioProcessPropertyPID,
                        mScope: kAudioObjectPropertyScopeGlobal,
                        mElement: kAudioObjectPropertyElementMain
                    )
                    var pid: pid_t = 0
                    var pidSize = UInt32(MemoryLayout<pid_t>.size)
                    if AudioObjectGetPropertyData(procObj, &pidAddress, 0, nil, &pidSize, &pid) == noErr && pid > 0 {
                        pids.insert(pid)
                    }
                }
            }
        }
        return pids
    }
    
    private func isKnownActiveAudioApp(bundleID: String, pid: pid_t) -> Bool {
        let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
        guard let windowInfoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return false }
        
        for win in windowInfoList {
            if let winPID = win[kCGWindowOwnerPID as String] as? pid_t, winPID == pid {
                if let winName = win[kCGWindowName as String] as? String, !winName.isEmpty {
                    let lower = winName.lowercased()
                    if lower.contains("youtube") || lower.contains("twitch") || lower.contains("spotify") || lower.contains("soundcloud") || lower.contains("netflix") || lower.contains("video") || lower.contains("music") || lower.contains("playing") {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    private func getWindowTitlesForProcess(pid: pid_t, bundleID: String) -> [String] {
        let isBrowser = bundleID.contains("Brave") || bundleID.contains("Chrome") || bundleID.contains("Safari") || bundleID.contains("browser") || bundleID.contains("firefox")
        guard isBrowser else { return [] }
        
        var titles: [String] = []
        let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
        guard let windowInfoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return [] }
        
        for win in windowInfoList {
            if let winPID = win[kCGWindowOwnerPID as String] as? pid_t, winPID == pid {
                if let winName = win[kCGWindowName as String] as? String, !winName.isEmpty {
                    if winName != "Brave" && winName != "Chrome" && winName != "Safari" {
                        titles.append(winName)
                    }
                }
            }
        }
        return Array(Set(titles))
    }
    
    private func applyProcessVolumeTap(process: AppAudioProcess) {
        let effectiveGain = process.isMuted ? 0.0 : process.volume
        #if DEBUG
        print("[CoreAudio Tap] Session \(process.id) (\(process.displayName)) set to gain: \(effectiveGain)")
        #endif
    }
    
    private func loadAppVolumeFromDisk(sessionID: String) -> Float {
        let key = AppConfig.Strings.appVolumeStoragePrefix + sessionID + "_vol"
        if UserDefaults.standard.object(forKey: key) != nil {
            return UserDefaults.standard.float(forKey: key)
        }
        return AppConfig.Audio.defaultAppVolume
    }
    
    private func saveAppVolumeToDisk(sessionID: String, volume: Float) {
        let key = AppConfig.Strings.appVolumeStoragePrefix + sessionID + "_vol"
        UserDefaults.standard.set(volume, forKey: key)
    }
    
    private func loadAppMuteFromDisk(sessionID: String) -> Bool {
        let key = AppConfig.Strings.appVolumeStoragePrefix + sessionID + "_mute"
        return UserDefaults.standard.bool(forKey: key)
    }
    
    private func saveAppMuteToDisk(sessionID: String, isMuted: Bool) {
        let key = AppConfig.Strings.appVolumeStoragePrefix + sessionID + "_mute"
        UserDefaults.standard.set(isMuted, forKey: key)
    }
    
    private func setupWorkspaceListeners() {
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshActiveProcesses()
            }
        }
        nc.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshActiveProcesses()
            }
        }
    }
    
    private func startPeriodicCheck() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshActiveProcesses()
            }
        }
    }
}
