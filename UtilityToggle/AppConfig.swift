//
//  AppConfig.swift
//  UtilityToggle
//
//  Centralized design system tokens, layout dimensions, fonts, colors, and string constants.
//

import SwiftUI
import AppKit

public enum AppConfig {
    
    // MARK: - Layout Dimensions & Spacing
    public enum Dimensions {
        public static let panelWidth: CGFloat = 340.0
        public static let panelHeight: CGFloat = 500.0
        public static let settingsWidth: CGFloat = 450.0
        public static let settingsHeight: CGFloat = 530.0
        
        public static let panelCornerRadius: CGFloat = 20.0
        public static let settingsCornerRadius: CGFloat = 16.0
        public static let cardCornerRadius: CGFloat = 10.0
        public static let innerCardRadius: CGFloat = 6.0
        
        public static let sectionPadding: CGFloat = 14.0
        public static let cardPadding: CGFloat = 10.0
        public static let itemPadding: CGFloat = 8.0
        
        public static let hatchedSliderBarCount: Int = 22
        public static let hatchedSliderHeight: CGFloat = 14.0
        public static let micMeterSegmentCount: Int = 14
        public static let micMeterSegmentWidth: CGFloat = 4.0
        public static let micMeterSegmentHeight: CGFloat = 8.0
        public static let spectrumBarCount: Int = 8
        public static let spectrumBarWidth: CGFloat = 3.0
    }
    
    // MARK: - Color Palette
    public enum Colors {
        public static let hudBackground = Color.black.opacity(0.94)
        public static let cardBackground = Color.white.opacity(0.04)
        public static let cardBorder = Color.white.opacity(0.15)
        public static let darkCardBackground = Color.black.opacity(0.3)
        public static let darkCardBorder = Color.white.opacity(0.2)
        
        public static let accentWhite = Color.white
        public static let textPrimary = Color.white
        public static let textSecondary = Color.white.opacity(0.6)
        public static let textMuted = Color.white.opacity(0.4)
        public static let textFaint = Color.white.opacity(0.25)
        
        public static let buttonBackground = Color.white.opacity(0.12)
        public static let buttonBorder = Color.white.opacity(0.3)
        public static let alertRed = Color.red
        public static let alertRedBackground = Color.red.opacity(0.15)
    }
    
    // MARK: - Monospaced Typography System
    public enum Fonts {
        public static let header = Font.system(size: 12, weight: .black, design: .monospaced)
        public static let sectionHeader = Font.system(size: 10, weight: .heavy, design: .monospaced)
        public static let title = Font.system(size: 11, weight: .bold, design: .monospaced)
        public static let body = Font.system(size: 10, weight: .regular, design: .monospaced)
        public static let badge = Font.system(size: 9, weight: .black, design: .monospaced)
        public static let badgeBold = Font.system(size: 9, weight: .bold, design: .monospaced)
        public static let subcaption = Font.system(size: 8, weight: .regular, design: .monospaced)
        public static let subcaptionBold = Font.system(size: 8, weight: .bold, design: .monospaced)
    }
    
    // MARK: - String Literals & Labels
    public enum Strings {
        public static let appName = "AUDIO_CTRL"
        public static let versionText = "[ v2.0.0 ]"
        public static let headerTitle = "AUDIO_CTRL // SYSTEM_AUDIO_ROUTER"
        public static let configHeaderTitle = "AUDIO_CTRL // CONFIGURATION"
        public static let defaultProfileName = "General"
        
        // Section Headers
        public static let sectionAudioProfiles = "// AUDIO_PROFILES_&_DEVICES"
        public static let sectionGlobalHotkey = "// DYNAMIC_GLOBAL_HOTKEY"
        public static let sectionAppBehavior = "// APP_BEHAVIOR"
        public static let sectionSystemDiagnostics = "// SYSTEM_DIAGNOSTICS"
        public static let sectionPresets = "// AUDIO_PRESETS"
        public static let sectionOutputDevice = "// SYSTEM_OUTPUT_DEVICE"
        public static let sectionInputDevice = "// INPUT_DEVICE_&_MIC"
        public static let sectionPerAppMixer = "// PER_APP_AUDIO_MIXER"
        public static let tabApps = "APPS"
        public static let noActiveAppsText = "// NO_ACTIVE_AUDIO_APPS_FOUND"
        public static let scanAppsBtn = "[ SCAN ACTIVE APPS ]"
        
        // Labels & Actions
        public static let closeBtn = "CLOSE"
        public static let saveCloseBtn = "[ SAVE_&_CLOSE ]"
        public static let addProfileBtn = "[ + ADD NEW PROFILE ]"
        public static let saveProfileBtn = "[ SAVE PROFILE ]"
        public static let cancelBtn = "[ CANCEL ]"
        public static let deleteBtn = "[ DELETE ]"
        public static let defaultBadge = "[ DEFAULT ]"
        public static let activeBadge = "[ ACTIVE ]"
        public static let runDiagnosticsBtn = "[ RUN_SYSTEM_DIAGNOSTICS ]"
        public static let defaultHotkeyDisplay = "⌥ SPACE"
        
        // Storage Keys
        public static let userHotKeyStorageKey = "UserCustomHotKeyStorageKey"
        public static let autoCloseOnClickOutsideKey = "autoCloseOnClickOutside"
        public static let showVolumeInMenuBarKey = "showVolumeInMenuBar"
        public static let appVolumeStoragePrefix = "UserAppVolumeStorage_"
    }
    
    // MARK: - Audio Engine Parameters
    public enum Audio {
        public static let meteringIntervalSeconds: Double = 0.05 // 50ms update interval (20Hz)
        public static let defaultScalarVolume: Float = 0.8
        public static let defaultAppVolume: Float = 1.0
        public static let maxAppVolumeBoost: Float = 2.0
        public static let minVisualizerHeight: Double = 3.0
        public static let micPeakMeterSegmentCount: Int = 14
        public static let spectrumBarCount: Int = 8
    }
}
