//
//  AppCoordinator.swift
//  kutuk
//
//  Wires app services together at launch
//

import Foundation
import Combine

final class AppCoordinator {
    private let settings: SettingsManager
    private let soundEngine: SoundEngine
    private let keyboardMonitor: KeyboardMonitor
    private let hotKeyManager: HotKeyManager
    private var cancellables = Set<AnyCancellable>()
    
    init(
        settings: SettingsManager,
        soundEngine: SoundEngine,
        keyboardMonitor: KeyboardMonitor,
        hotKeyManager: HotKeyManager? = nil
    ) {
        self.settings = settings
        self.soundEngine = soundEngine
        self.keyboardMonitor = keyboardMonitor
        self.hotKeyManager = hotKeyManager ?? HotKeyManager(shortcut: settings.hotKeyShortcut)
        
        configure()
    }
    
    private func configure() {
        soundEngine.volume = Float(settings.volume)
        soundEngine.loadSoundPack(settings.selectedSoundPack)
        
        keyboardMonitor.onKeyEvent = { [weak self] keyType, keyEvent in
            guard let self, self.settings.isEnabled else { return }
            self.soundEngine.playSound(for: keyType, event: keyEvent)
        }

        hotKeyManager.onHotKeyPressed = { [weak self] in
            self?.settings.toggleEnabled()
        }

        // Note: monitoring start/stop is managed by MenuBarView's permission logic
        
        settings.$volume
            .dropFirst()
            .sink { [weak self] volume in
                self?.soundEngine.volume = Float(volume)
            }
            .store(in: &cancellables)
        
        settings.$selectedSoundPackId
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                self.soundEngine.loadSoundPack(self.settings.selectedSoundPack)
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest(settings.$hotKeyKeyCode, settings.$hotKeyModifierPresetRawValue)
            .dropFirst()
            .sink { [weak self] _, _ in
                guard let self else { return }
                self.hotKeyManager.updateHotKey(self.settings.hotKeyShortcut)
            }
            .store(in: &cancellables)
    }
}
