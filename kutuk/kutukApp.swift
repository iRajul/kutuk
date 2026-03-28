//
//  kutukApp.swift
//  kutuk
//
//  Kutuk - Mechanical Keyboard Sound App
//

import SwiftUI

@main
struct KutukApp: App {
    @StateObject private var settings: SettingsManager
    @StateObject private var soundEngine: SoundEngine
    @StateObject private var keyboardMonitor: KeyboardMonitor
    private let appCoordinator: AppCoordinator
    
    init() {
        let settings = SettingsManager()
        let soundEngine = SoundEngine()
        let keyboardMonitor = KeyboardMonitor()
        
        _settings = StateObject(wrappedValue: settings)
        _soundEngine = StateObject(wrappedValue: soundEngine)
        _keyboardMonitor = StateObject(wrappedValue: keyboardMonitor)
        appCoordinator = AppCoordinator(
            settings: settings,
            soundEngine: soundEngine,
            keyboardMonitor: keyboardMonitor
        )
    }
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(settings)
                .environmentObject(soundEngine)
                .environmentObject(keyboardMonitor)
        } label: {
            Image(systemName: "command")
                .symbolRenderingMode(.monochrome)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
                .opacity(settings.isEnabled ? 1 : 0.65)
        }
        .menuBarExtraStyle(.window)
    }
}
