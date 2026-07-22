//
//  AppAudioProcess.swift
//  UtilityToggle
//
//  Data model representing an active audio-producing application.
//

import SwiftUI
import AppKit
import CoreAudio

public struct AppAudioProcess: Identifiable, Equatable {
    public let id: String // bundleID
    public let pid: pid_t
    public let audioObjectID: AudioObjectID  // CoreAudio process object ID
    public let bundleIdentifier: String
    public let name: String
    public let icon: NSImage
    public var volume: Float
    public var isMuted: Bool
    public var isPlayingAudio: Bool  // kAudioProcessPropertyIsRunningOutput
    
    public init(
        id: String,
        pid: pid_t,
        audioObjectID: AudioObjectID,
        bundleIdentifier: String,
        name: String,
        icon: NSImage,
        volume: Float = AppConfig.Audio.defaultAppVolume,
        isMuted: Bool = false,
        isPlayingAudio: Bool = false
    ) {
        self.id = id
        self.pid = pid
        self.audioObjectID = audioObjectID
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.icon = icon
        self.volume = volume
        self.isMuted = isMuted
        self.isPlayingAudio = isPlayingAudio
    }
    
    public var displayName: String {
        return name.uppercased()
    }
    
    public static func == (lhs: AppAudioProcess, rhs: AppAudioProcess) -> Bool {
        return lhs.id == rhs.id && lhs.volume == rhs.volume && lhs.isMuted == rhs.isMuted && lhs.isPlayingAudio == rhs.isPlayingAudio
    }
}
