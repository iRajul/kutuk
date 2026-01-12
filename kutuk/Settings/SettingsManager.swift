//
//  SettingsManager.swift
//  kutuk
//
//  Manages app settings with UserDefaults persistence
//

import SwiftUI
import Combine
import ServiceManagement

/// Observable settings manager with automatic persistence
class SettingsManager: ObservableObject {
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Keys
    
    private enum Keys {
        static let isEnabled = "isEnabled"
        static let volume = "volume"
        static let selectedSoundPackId = "selectedSoundPackId"
    }
    
    // MARK: - Published Properties
    
    @Published var isEnabled: Bool {
        didSet {
            defaults.set(isEnabled, forKey: Keys.isEnabled)
        }
    }
    
    @Published var volume: Double {
        didSet {
            defaults.set(volume, forKey: Keys.volume)
        }
    }
    
    @Published var selectedSoundPackId: String {
        didSet {
            defaults.set(selectedSoundPackId, forKey: Keys.selectedSoundPackId)
        }
    }
    
    @Published var launchAtLogin: Bool = false {
        didSet {
            updateLaunchAtLogin()
        }
    }
    
    // MARK: - Computed Properties
    
    var selectedSoundPack: SoundPack {
        SoundPack.allPacks.first { $0.id == selectedSoundPackId } ?? .cherryMXBlue
    }
    
    // MARK: - Initialization
    
    init() {
        // Load from UserDefaults with defaults
        self.isEnabled = defaults.object(forKey: Keys.isEnabled) as? Bool ?? true
        self.volume = defaults.object(forKey: Keys.volume) as? Double ?? 0.8
        self.selectedSoundPackId = defaults.string(forKey: Keys.selectedSoundPackId) ?? SoundPack.cherryMXBlue.id
        
        // Check current launch at login status
        if #available(macOS 13.0, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
    
    // MARK: - Methods
    
    func selectSoundPack(_ pack: SoundPack) {
        selectedSoundPackId = pack.id
    }
    
    func toggleEnabled() {
        isEnabled.toggle()
    }
    
    private func updateLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update launch at login: \(error)")
            }
        }
    }
}
