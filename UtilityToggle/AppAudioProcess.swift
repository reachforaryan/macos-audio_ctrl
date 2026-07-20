//
//  AppAudioProcess.swift
//  UtilityToggle
//
//  Data model representing an active audio-producing application or browser window session.
//

import SwiftUI
import AppKit

public struct AppAudioProcess: Identifiable, Equatable {
    public let id: String // Unique ID: bundleID or bundleID_windowTitle
    public let pid: pid_t
    public let bundleIdentifier: String
    public let name: String
    public let windowTitle: String?
    public let icon: NSImage
    public var volume: Float
    public var isMuted: Bool
    public var isLivePlaying: Bool
    
    public init(
        id: String,
        pid: pid_t,
        bundleIdentifier: String,
        name: String,
        windowTitle: String? = nil,
        icon: NSImage,
        volume: Float = AppConfig.Audio.defaultAppVolume,
        isMuted: Bool = false,
        isLivePlaying: Bool = true
    ) {
        self.id = id
        self.pid = pid
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.windowTitle = windowTitle
        self.icon = icon
        self.volume = volume
        self.isMuted = isMuted
        self.isLivePlaying = isLivePlaying
    }
    
    public var displayName: String {
        if let windowTitle = windowTitle, !windowTitle.isEmpty {
            return "\(name.uppercased()): \(windowTitle.uppercased())"
        }
        return name.uppercased()
    }
    
    public static func == (lhs: AppAudioProcess, rhs: AppAudioProcess) -> Bool {
        return lhs.id == rhs.id && lhs.volume == rhs.volume && lhs.isMuted == rhs.isMuted && lhs.isLivePlaying == rhs.isLivePlaying
    }
}
