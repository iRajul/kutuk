//
//  AppDelegate.swift
//  kutuk
//
//  App lifecycle management
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var settings: SettingsManager?
    var soundEngine: SoundEngine?
    var keyboardMonitor: KeyboardMonitor?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🎹 App launched")
        setupOnLaunch()
    }
    
    func setup(settings: SettingsManager, soundEngine: SoundEngine, keyboardMonitor: KeyboardMonitor) {
        self.settings = settings
        self.soundEngine = soundEngine
        self.keyboardMonitor = keyboardMonitor
    }
    
    private func setupOnLaunch() {
        guard let settings = settings,
              let soundEngine = soundEngine,
              let keyboardMonitor = keyboardMonitor else {
            print("🎹 Services not ready, will setup later")
            return
        }
        
        print("🎹 Setting up services...")
        
        // Load sound pack
        soundEngine.volume = Float(settings.volume)
        soundEngine.loadSoundPack(settings.selectedSoundPack)
        
        // Check permission and start monitoring
        if keyboardMonitor.checkPermission() && settings.isEnabled {
            keyboardMonitor.startMonitoring()
            print("🎹 Keyboard monitoring started")
        }
        
        // Connect keyboard events to sound engine
        keyboardMonitor.onKeyEvent = { [weak soundEngine, weak settings] keyType, keyEvent in
            guard let settings = settings, settings.isEnabled else { return }
            print("🎹 Key: \(keyType) - \(keyEvent)")
            soundEngine?.playSound(for: keyType, event: keyEvent)
        }
        
        print("🎹 Setup complete")
    }
}
