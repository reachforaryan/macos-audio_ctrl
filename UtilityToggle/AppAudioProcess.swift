//
//  AppAudioProcess.swift
//  UtilityToggle
//
//  Data model representing an audio-producing application process.
//

import SwiftUI
import AppKit

public struct AppAudioProcess: Identifiable, Equatable {
    public let id: pid_t
    public let bundleIdentifier: String
    public let name: String
    public let icon: NSImage
    public var volume: Float
    public var isMuted: Bool
    
    public init(id: pid_t, bundleIdentifier: String, name: String, icon: NSImage, volume: Float = AppConfig.Audio.defaultAppVolume, isMuted: Bool = false) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.icon = icon
        self.volume = volume
        self.isMuted = isMuted
    }
    
    public static func == (lhs: AppAudioProcess, rhs: AppAudioProcess) -> Bool {
        return lhs.id == rhs.id && lhs.bundleIdentifier == rhs.bundleIdentifier && lhs.volume == rhs.volume && lhs.isMuted == rhs.isMuted
    }
}
