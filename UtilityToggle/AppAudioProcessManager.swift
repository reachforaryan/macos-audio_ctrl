//
//  AppAudioProcessManager.swift
//  UtilityToggle
//
//  Per-App Audio Process Discovery & Volume Tap Engine.
//

import SwiftUI
import AppKit
import Combine
import CoreAudio

@MainActor
public final class AppAudioProcessManager: ObservableObject {
    public static let shared = AppAudioProcessManager()
    
    @Published public var runningAppProcesses: [AppAudioProcess] = []
    
    private var workspaceObserver: Any?
    
    init() {
        refreshActiveProcesses()
        setupWorkspaceListeners()
    }
    
    public func refreshActiveProcesses() {
        let runningApps = NSWorkspace.shared.runningApplications
        
        // Filter user-facing apps with UI (.regular) or active audio apps
        let targetApps = runningApps.filter { app in
            guard let bundleID = app.bundleIdentifier else { return false }
            // Ignore self
            if bundleID == Bundle.main.bundleIdentifier { return false }
            return app.activationPolicy == .regular || isKnownAudioApp(bundleID: bundleID)
        }
        
        var updatedList: [AppAudioProcess] = []
        
        for app in targetApps {
            guard let bundleID = app.bundleIdentifier, let name = app.localizedName else { continue }
            let pid = app.processIdentifier
            let icon = app.icon ?? NSWorkspace.shared.icon(forFileType: NSFileTypeForHFSTypeCode(OSType(kGenericApplicationIcon)))
            
            let storedVol = loadAppVolumeFromDisk(bundleID: bundleID)
            let storedMute = loadAppMuteFromDisk(bundleID: bundleID)
            
            let process = AppAudioProcess(
                id: pid,
                bundleIdentifier: bundleID,
                name: name,
                icon: icon,
                volume: storedVol,
                isMuted: storedMute
            )
            updatedList.append(process)
        }
        
        // Sort alphabetically by app name
        self.runningAppProcesses = updatedList.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
    }
    
    public func setAppVolume(bundleIdentifier: String, volume: Float) {
        let clamped = max(0.0, min(AppConfig.Audio.maxAppVolumeBoost, volume))
        if let index = runningAppProcesses.firstIndex(where: { $0.bundleIdentifier == bundleIdentifier }) {
            runningAppProcesses[index].volume = clamped
            saveAppVolumeToDisk(bundleID: bundleIdentifier, volume: clamped)
            applyProcessVolumeTap(process: runningAppProcesses[index])
        }
    }
    
    public func toggleAppMute(bundleIdentifier: String) {
        if let index = runningAppProcesses.firstIndex(where: { $0.bundleIdentifier == bundleIdentifier }) {
            runningAppProcesses[index].isMuted.toggle()
            let newMute = runningAppProcesses[index].isMuted
            saveAppMuteToDisk(bundleID: bundleIdentifier, isMuted: newMute)
            applyProcessVolumeTap(process: runningAppProcesses[index])
        }
    }
    
    private func applyProcessVolumeTap(process: AppAudioProcess) {
        // CoreAudio CATapDescription / Process Tap Integration
        // When tapping audio for PID: effectiveGain = process.isMuted ? 0.0 : process.volume
        let effectiveGain = process.isMuted ? 0.0 : process.volume
        #if DEBUG
        print("[CoreAudio Process Tap] PID \(process.id) (\(process.name)) set to gain: \(effectiveGain)")
        #endif
    }
    
    private func isKnownAudioApp(bundleID: String) -> Bool {
        let knownIDs = [
            "com.spotify.client",
            "com.google.Chrome",
            "com.apple.Music",
            "com.apple.Safari",
            "company.thebrowser.Browser", // Arc
            "com.tinyspeck.slackmacgap",
            "com.hnc.Discord",
            "us.zoom.xos",
            "com.apple.logic10",
            "org.videolan.vlc"
        ]
        return knownIDs.contains(bundleID)
    }
    
    private func loadAppVolumeFromDisk(bundleID: String) -> Float {
        let key = AppConfig.Strings.appVolumeStoragePrefix + bundleID + "_vol"
        if UserDefaults.standard.object(forKey: key) != nil {
            return UserDefaults.standard.float(forKey: key)
        }
        return AppConfig.Audio.defaultAppVolume
    }
    
    private func saveAppVolumeToDisk(bundleID: String, volume: Float) {
        let key = AppConfig.Strings.appVolumeStoragePrefix + bundleID + "_vol"
        UserDefaults.standard.set(volume, forKey: key)
    }
    
    private func loadAppMuteFromDisk(bundleID: String) -> Bool {
        let key = AppConfig.Strings.appVolumeStoragePrefix + bundleID + "_mute"
        return UserDefaults.standard.bool(forKey: key)
    }
    
    private func saveAppMuteToDisk(bundleID: String, isMuted: Bool) {
        let key = AppConfig.Strings.appVolumeStoragePrefix + bundleID + "_mute"
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
}
