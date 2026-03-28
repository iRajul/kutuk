//
//  kutukTests.swift
//  kutukTests
//
//  Created by Rajul Jain on 11/01/26.
//

import Testing
import Carbon.HIToolbox
@testable import kutuk

private struct MockLaunchAtLoginController: LaunchAtLoginControlling {
    var isEnabled: Bool = false
    
    func setEnabled(_ isEnabled: Bool) throws {}
}

struct kutukTests {
    @Test func openSourceBuildExposesOnlyBluePack() {
        #expect(SoundPack.allPacks == [.cherryMXBlue])
        #expect(SoundPack.visiblePacks == [.cherryMXBlue])
    }
    
    @Test func unsupportedSavedPackFallsBackToBlue() {
        let defaults = UserDefaults(suiteName: "kutuk-tests-\(UUID().uuidString)")!
        defaults.set("buckling-spring", forKey: "selectedSoundPackId")
        
        let settings = SettingsManager(
            defaults: defaults,
            launchAtLoginController: MockLaunchAtLoginController()
        )
        
        #expect(settings.selectedSoundPack == .cherryMXBlue)
    }
    
    @Test func hotKeyShortcutPersistsAcrossReloads() {
        let defaults = UserDefaults(suiteName: "kutuk-tests-\(UUID().uuidString)")!
        let launchController = MockLaunchAtLoginController()
        
        let settings = SettingsManager(
            defaults: defaults,
            launchAtLoginController: launchController
        )
        settings.hotKeyKeyCode = Int(UInt32(kVK_ANSI_P))
        settings.hotKeyModifierPresetRawValue = HotKeyShortcut.ModifierPreset.controlOptionCommand.rawValue
        
        let reloaded = SettingsManager(
            defaults: defaults,
            launchAtLoginController: launchController
        )
        
        #expect(reloaded.hotKeyShortcut.keyCode == UInt32(kVK_ANSI_P))
        #expect(reloaded.hotKeyShortcut.modifierPreset == .controlOptionCommand)
        #expect(reloaded.hotKeyShortcut.displayString == "⌃⌥⌘P")
    }
}
