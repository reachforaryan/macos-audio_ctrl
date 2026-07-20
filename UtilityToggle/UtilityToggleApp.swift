//
//  UtilityToggleApp.swift
//  UtilityToggle
//

import SwiftUI
import AppKit

@main
struct AudioWidgetApp: App {
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
        FloatingPanelManager.shared.setupPanel(contentView: AnyView(WidgetView()))
    }
}
