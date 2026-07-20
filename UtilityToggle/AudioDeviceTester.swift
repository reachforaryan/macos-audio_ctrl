//
//  AudioDeviceTester.swift
//  UtilityToggle
//

import Foundation
import CoreAudio
import SwiftUI

public struct TestResult {
    public let name: String
    public let passed: Bool
    public let message: String
}

@MainActor
public final class AudioDeviceTester {
    
    public static func runAllTests() -> [TestResult] {
        var results = [TestResult]()
        
        let manager = AudioDeviceManager()
        
        // Test 1: Device Discovery
        let outCount = manager.outputDevices.count
        let inCount = manager.inputDevices.count
        let discoveryPassed = outCount > 0 && inCount > 0
        results.append(TestResult(
            name: "CoreAudio Device Discovery",
            passed: discoveryPassed,
            message: "Discovered \(outCount) output devices and \(inCount) input devices."
        ))
        
        // Test 2: Default Device IDs
        let outID = manager.currentOutputDeviceID
        let inID = manager.currentInputDeviceID
        let defaultIDsPassed = outID != 0 && inID != 0
        results.append(TestResult(
            name: "Default Device ID Resolution",
            passed: defaultIDsPassed,
            message: "Output Device ID: \(outID), Input Device ID: \(inID)."
        ))
        
        // Test 3: Volume Scalar Bounds
        let outVol = manager.outputVolume
        let inVol = manager.inputVolume
        let volumeBoundsPassed = (0.0...1.0).contains(outVol) && (0.0...1.0).contains(inVol)
        results.append(TestResult(
            name: "Volume Scalar Range (0.0 - 1.0)",
            passed: volumeBoundsPassed,
            message: "Output Volume: \(Int(outVol * 100))%, Input Volume: \(Int(inVol * 100))%."
        ))
        
        // Test 4: Mute Toggle Functionality
        let initialMute = manager.isOutputMuted
        manager.toggleOutputMute()
        let toggledMute = manager.isOutputMuted
        manager.toggleOutputMute()
        let restoredMute = manager.isOutputMuted
        let mutePassed = (toggledMute != initialMute) && (restoredMute == initialMute)
        results.append(TestResult(
            name: "Output Mute Toggle Logic",
            passed: mutePassed,
            message: "Successfully toggled and restored output mute state."
        ))
        
        // Test 5: Floating Panel Manager State
        let panelManager = FloatingPanelManager.shared
        let panelPassed = panelManager.panel != nil
        results.append(TestResult(
            name: "Floating Panel Manager Initializer",
            passed: panelPassed,
            message: "FloatingPanelManager panel instance is active."
        ))
        
        // Print Test Suite Summary to Console
        print("\n======== UTILITY TOGGLE TEST SUITE ========")
        for res in results {
            let status = res.passed ? "[PASS] ✅" : "[FAIL] ❌"
            print("\(status) \(res.name): \(res.message)")
        }
        print("===========================================\n")
        
        return results
    }
}
