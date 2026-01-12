//
//  kutukApp.swift
//  kutuk
//
//  Kutuk - Mechanical Keyboard Sound App
//

import SwiftUI

@main
struct KutukApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var settings = SettingsManager()
    @StateObject private var soundEngine = SoundEngine()
    @StateObject private var keyboardMonitor = KeyboardMonitor()
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(settings)
                .environmentObject(soundEngine)
                .environmentObject(keyboardMonitor)
                .onAppear {
                    // Setup on first menu open
                    setupServices()
                }
        } label: {
            Image(systemName: settings.isEnabled ? "keyboard.fill" : "keyboard")
        }
        .menuBarExtraStyle(.window)
    }
    
    private func setupServices() {
        print("🎹 Menu opened, setting up services...")
        
        // Load sound pack
        soundEngine.volume = Float(settings.volume)
        soundEngine.loadSoundPack(settings.selectedSoundPack)
        
        // Try to start monitoring regardless of permission check
        // (Permission check can be stale after granting)
        print("🎹 Attempting to start keyboard monitoring...")
        keyboardMonitor.startMonitoring()
        print("🎹 Monitoring status: \(keyboardMonitor.isMonitoring)")
        
        // Connect keyboard events to sound engine
        keyboardMonitor.onKeyEvent = { [soundEngine, settings] keyType, keyEvent in
            guard settings.isEnabled else { return }
            print("🎹 Key: \(keyType) - \(keyEvent)")
            soundEngine.playSound(for: keyType, event: keyEvent)
        }
        
        print("🎹 Setup complete")
    }
}
