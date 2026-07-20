//
//  ThemeManager.swift
//  UtilityToggle
//
//  Dynamic theme manager with custom color wheel support and Y2K presets.
//

import SwiftUI
import AppKit
import Combine

public enum ThemePreset: String, CaseIterable, Identifiable, Codable {
    case defaultMono = "DEFAULT Y2K"
    case neonMatrix = "NEON MATRIX"
    case cyberpunk = "CYBERPUNK"
    case solarFlare = "SOLAR FLARE"
    case custom = "CUSTOM WHEEL"
    
    public var id: String { rawValue }
}

@MainActor
public final class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()
    
    @Published public var activePreset: ThemePreset = .defaultMono {
        didSet {
            if activePreset != .custom {
                applyPresetColors(activePreset)
            }
            saveThemeToDisk()
        }
    }
    
    @Published public var primaryColor: Color = Color.white {
        didSet { saveThemeToDisk() }
    }
    
    @Published public var secondaryColor: Color = Color.black {
        didSet { saveThemeToDisk() }
    }
    
    private let primaryKey = "UserThemePrimaryColorHex"
    private let secondaryKey = "UserThemeSecondaryColorHex"
    private let presetKey = "UserThemePresetKey"
    
    init() {
        loadThemeFromDisk()
    }
    
    public func resetToDefault() {
        activePreset = .defaultMono
        primaryColor = Color.white
        secondaryColor = Color.black
    }
    
    private func applyPresetColors(_ preset: ThemePreset) {
        switch preset {
        case .defaultMono:
            primaryColor = Color.white
            secondaryColor = Color.black
        case .neonMatrix:
            primaryColor = Color(red: 0.0, green: 1.0, blue: 0.4) // Neon Green
            secondaryColor = Color(red: 0.05, green: 0.1, blue: 0.05)
        case .cyberpunk:
            primaryColor = Color(red: 1.0, green: 0.1, blue: 0.6) // Hot Pink
            secondaryColor = Color(red: 0.1, green: 0.0, blue: 0.2)
        case .solarFlare:
            primaryColor = Color(red: 1.0, green: 0.7, blue: 0.0) // Gold
            secondaryColor = Color(red: 0.15, green: 0.08, blue: 0.0)
        case .custom:
            break
        }
    }
    
    private func saveThemeToDisk() {
        UserDefaults.standard.set(activePreset.rawValue, forKey: presetKey)
        if let primaryHex = primaryColor.toHex() {
            UserDefaults.standard.set(primaryHex, forKey: primaryKey)
        }
        if let secondaryHex = secondaryColor.toHex() {
            UserDefaults.standard.set(secondaryHex, forKey: secondaryKey)
        }
    }
    
    private func loadThemeFromDisk() {
        if let rawPreset = UserDefaults.standard.string(forKey: presetKey),
           let preset = ThemePreset(rawValue: rawPreset) {
            self.activePreset = preset
        }
        
        if let pStr = UserDefaults.standard.string(forKey: primaryKey),
           let pColor = Color(hex: pStr) {
            self.primaryColor = pColor
        }
        
        if let sStr = UserDefaults.standard.string(forKey: secondaryKey),
           let sColor = Color(hex: sStr) {
            self.secondaryColor = sColor
        }
    }
}

// MARK: - Color Hex Extensions
extension Color {
    init?(hex: String) {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        if cleanHex.count == 6 {
            cleanHex += "FF"
        }
        guard cleanHex.count == 8, let val = UInt64(cleanHex, radix: 16) else { return nil }
        let r = Double((val >> 24) & 0xFF) / 255.0
        let g = Double((val >> 16) & 0xFF) / 255.0
        let b = Double((val >> 8) & 0xFF) / 255.0
        let a = Double(val & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
    
    func toHex() -> String? {
        guard let nsColor = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        let r = Int(round(nsColor.redComponent * 255))
        let g = Int(round(nsColor.greenComponent * 255))
        let b = Int(round(nsColor.blueComponent * 255))
        let a = Int(round(nsColor.alphaComponent * 255))
        return String(format: "#%02X%02X%02X%02X", r, g, b, a)
    }
}
