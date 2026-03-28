//
//  SettingsManager.swift
//  kutuk
//
//  Manages app settings with UserDefaults persistence
//

import SwiftUI
import Combine
import ServiceManagement

protocol LaunchAtLoginControlling {
    var isEnabled: Bool { get }
    func setEnabled(_ isEnabled: Bool) throws
}

struct SystemLaunchAtLoginController: LaunchAtLoginControlling {
    var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }
    
    func setEnabled(_ isEnabled: Bool) throws {
        guard #available(macOS 13.0, *) else { return }
        
        if isEnabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}

/// Observable settings manager with automatic persistence
class SettingsManager: ObservableObject {
    
    private let defaults: UserDefaults
    private let launchAtLoginController: LaunchAtLoginControlling
    
    // MARK: - Keys
    
    private enum Keys {
        static let isEnabled = "isEnabled"
        static let volume = "volume"
        static let selectedSoundPackId = "selectedSoundPackId"
        static let hotKeyKeyCode = "hotKeyKeyCode"
        static let hotKeyModifierPreset = "hotKeyModifierPreset"
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
    
    @Published var hotKeyKeyCode: Int {
        didSet {
            defaults.set(hotKeyKeyCode, forKey: Keys.hotKeyKeyCode)
        }
    }
    
    @Published var hotKeyModifierPresetRawValue: String {
        didSet {
            defaults.set(hotKeyModifierPresetRawValue, forKey: Keys.hotKeyModifierPreset)
        }
    }
    
    @Published var launchAtLogin: Bool = false {
        didSet {
            updateLaunchAtLogin()
        }
    }
    
    // MARK: - Computed Properties
    
    var selectedSoundPack: SoundPack {
        SoundPack.visiblePacks.first { $0.id == selectedSoundPackId } ?? .defaultPack
    }
    
    var hotKeyShortcut: HotKeyShortcut {
        HotKeyShortcut(
            keyCode: UInt32(hotKeyKeyCode),
            modifierPreset: HotKeyShortcut.ModifierPreset(rawValue: hotKeyModifierPresetRawValue) ?? HotKeyShortcut.defaultShortcut.modifierPreset
        )
    }
    
    // MARK: - Initialization
    
    init(
        defaults: UserDefaults = .standard,
        launchAtLoginController: LaunchAtLoginControlling = SystemLaunchAtLoginController()
    ) {
        self.defaults = defaults
        self.launchAtLoginController = launchAtLoginController
        
        // Load from UserDefaults with defaults
        self.isEnabled = defaults.object(forKey: Keys.isEnabled) as? Bool ?? true
        self.volume = defaults.object(forKey: Keys.volume) as? Double ?? 0.8
        self.selectedSoundPackId = defaults.string(forKey: Keys.selectedSoundPackId) ?? SoundPack.defaultPack.id
        self.hotKeyKeyCode = defaults.object(forKey: Keys.hotKeyKeyCode) as? Int ?? Int(HotKeyShortcut.defaultShortcut.keyCode)
        self.hotKeyModifierPresetRawValue = defaults.string(forKey: Keys.hotKeyModifierPreset) ?? HotKeyShortcut.defaultShortcut.modifierPreset.rawValue
        
        // Check current launch at login status
        launchAtLogin = launchAtLoginController.isEnabled
    }
    
    // MARK: - Methods
    
    func selectSoundPack(_ pack: SoundPack) {
        selectedSoundPackId = pack.id
    }
    
    func toggleEnabled() {
        isEnabled.toggle()
    }
    
    private func updateLaunchAtLogin() {
        do {
            try launchAtLoginController.setEnabled(launchAtLogin)
        } catch {
            print("Failed to update launch at login: \(error)")
        }
    }
}
