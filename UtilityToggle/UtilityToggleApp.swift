//
//  UtilityToggleApp.swift
//  UtilityToggle
//

import SwiftUI
import AppKit

@main
struct UtilityToggleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        let contentView = AnyView(WidgetView())
        FloatingPanelManager.shared.setupPanel(contentView: contentView)
        
        // Execute automated unit test suite
        Task { @MainActor in
            _ = AudioDeviceTester.runAllTests()
        }
    }
}
