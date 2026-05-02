//
//  kutukTests.swift
//  kutukTests
//
//  Created by Rajul Jain on 11/01/26.
//

import Testing
import Carbon.HIToolbox
import CryptoKit
@testable import kutuk

private struct MockLaunchAtLoginController: LaunchAtLoginControlling {
    var isEnabled: Bool = false
    
    func setEnabled(_ isEnabled: Bool) throws {}
}

struct kutukTests {
    @Test func openSourceBuildExposesBrownAndBluePacks() {
        #expect(SoundPack.allPacks.map(\.id) == ["cherry-mx-brown", "cherry-mx-blue"])
        #expect(SoundPack.visiblePacks.map(\.id) == ["cherry-mx-brown", "cherry-mx-blue"])
        #expect(SoundPack.defaultPack.id == SoundPack.cherryMXBrown.id)
    }

    @Test func bundledCherrySoundsComeFromMechvibesTravelPacks() throws {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let soundsDirectory = repoRoot
            .appendingPathComponent("kutuk")
            .appendingPathComponent("Resources")
            .appendingPathComponent("Sounds")
        
        let expectedHashes = [
            "cherry-mx-brown_regular_press_1.mp3": "3ac7a03472bb63ae34f077b7f50d85adf5f1d4f93565c6c6608b23be7eca10ca",
            "cherry-mx-brown_regular_press_2.mp3": "9fb249de0ef96cb08602f47b53161338bc90a9d094a9c9b2ca33c513d5ca10a8",
            "cherry-mx-brown_regular_press_3.mp3": "227363367cf62d93b73994cde9124956aecd8bf44c63167909c1079ceae37688",
            "cherry-mx-brown_regular_press_4.mp3": "4eebb28d97138a226223532321f0351f993f1d21d804bd0f26af1d7e7f8309ec",
            "cherry-mx-brown_regular_press_5.mp3": "e4f7f0413ceff5892b130808efee2d50734a72f3babdcb2e238761a749fa99c6",
            "cherry-mx-brown_regular_release.mp3": "5aaedc220e66eeda90adf64e519aa11d4ba0e3df9d8579ffb05af47dc0adbaf8",
            "cherry-mx-brown_space_press.mp3": "c29e11248a5cbfb845628174803ea240701a63d17770ea006defad2d48263017",
            "cherry-mx-brown_space_release.mp3": "eaf160ffea29918f08cc267033accdcfa6fe99992149dcf3de6f599ba66c63f7",
            "cherry-mx-brown_enter_press.mp3": "870ac91262bf77ae898dad217bf033941634b8b162a2fa4a190416abd7aabfb7",
            "cherry-mx-brown_enter_release.mp3": "c3e4a000ef5540f485d760a5c4c06adf8d38d9814989302b8d5b42eab472dc4b",
            "cherry-mx-brown_backspace_press.mp3": "8607e53ec586692caee08e61d6fa241fce7c7ef9dac219de92b632b90678a972",
            "cherry-mx-brown_backspace_release.mp3": "6a1cda06206811bd4ec3e17d49dfbb4f5128068d0994e7e6c001e2e13c90a4ae",
            "cherry-mx-blue_regular_press_1.mp3": "329a2cb041186579180cfd6c367b4680e82677689788210a96461ee43dc47115",
            "cherry-mx-blue_regular_press_2.mp3": "01baccca3a0b9a913063241c0eaade18d8fd6263d507fbfc4fdfa3a5a526389a",
            "cherry-mx-blue_regular_press_3.mp3": "9460f5ccd67aa5c01a125c26533fdbbcf1ce064bb049534bd7e306695fa845b4",
            "cherry-mx-blue_regular_press_4.mp3": "4193733efad92e044c6234811219c63075a7c547b6219fdc1f9c915965ba8269",
            "cherry-mx-blue_regular_press_5.mp3": "7a98c842c9f2eb650e4d8878cb9ba08428450b190c257d61d5a7dcfaa052d1b3",
            "cherry-mx-blue_regular_release.mp3": "243e8300cbe131678b8b4d1fd44e8aaa884636c6799af67b379408a96a9e5697"
        ]
        let expectedFiles = expectedHashes.keys.sorted()
        let actualFiles = try FileManager.default
            .contentsOfDirectory(at: soundsDirectory, includingPropertiesForKeys: nil)
            .map(\.lastPathComponent)
            .filter { $0.hasPrefix("cherry-mx-") }
            .sorted()
        
        #expect(actualFiles == expectedFiles)
        
        for (fileName, expectedHash) in expectedHashes {
            let data = try Data(contentsOf: soundsDirectory.appendingPathComponent(fileName))
            let actualHash = SHA256.hash(data: data)
                .map { String(format: "%02x", $0) }
                .joined()
            
            #expect(actualHash == expectedHash)
        }
    }
    
    @Test func brownSpecialKeysUseDedicatedSoundFiles() {
        let specialCases: [(KeyType, KeyEvent, String)] = [
            (.space, .press, "cherry-mx-brown_space_press.mp3"),
            (.space, .release, "cherry-mx-brown_space_release.mp3"),
            (.enter, .press, "cherry-mx-brown_enter_press.mp3"),
            (.enter, .release, "cherry-mx-brown_enter_release.mp3"),
            (.backspace, .press, "cherry-mx-brown_backspace_press.mp3"),
            (.backspace, .release, "cherry-mx-brown_backspace_release.mp3")
        ]
        
        for (keyType, event, expectedFileName) in specialCases {
            let urls = SoundPack.cherryMXBrown.soundURLs(for: keyType, event: event)
            
            #expect(urls.map(\.lastPathComponent) == [expectedFileName])
        }
    }
    
    @Test func blueSpecialKeysUseRegularFallbackSounds() {
        let regularPressFiles = [
            "cherry-mx-blue_regular_press_1.mp3",
            "cherry-mx-blue_regular_press_2.mp3",
            "cherry-mx-blue_regular_press_3.mp3",
            "cherry-mx-blue_regular_press_4.mp3",
            "cherry-mx-blue_regular_press_5.mp3"
        ]
        
        #expect(SoundPack.cherryMXBlue.soundURLs(for: .space, event: .press).map(\.lastPathComponent) == regularPressFiles)
        #expect(SoundPack.cherryMXBlue.soundURLs(for: .enter, event: .press).map(\.lastPathComponent) == regularPressFiles)
        #expect(SoundPack.cherryMXBlue.soundURLs(for: .backspace, event: .press).map(\.lastPathComponent) == regularPressFiles)
        #expect(SoundPack.cherryMXBlue.soundURLs(for: .space, event: .release).map(\.lastPathComponent) == ["cherry-mx-blue_regular_release.mp3"])
        #expect(SoundPack.cherryMXBlue.soundURLs(for: .enter, event: .release).map(\.lastPathComponent) == ["cherry-mx-blue_regular_release.mp3"])
        #expect(SoundPack.cherryMXBlue.soundURLs(for: .backspace, event: .release).map(\.lastPathComponent) == ["cherry-mx-blue_regular_release.mp3"])
    }
    
    @Test func bundledMP3SoundsCanBeScheduledBySoundEngine() {
        for pack in SoundPack.visiblePacks {
            #expect(!pack.soundURLs(for: .regular, event: .press).isEmpty)
            #expect(!pack.soundURLs(for: .regular, event: .release).isEmpty)
            
            let soundEngine = SoundEngine()
            soundEngine.volume = 0
            soundEngine.loadSoundPack(pack)
            
            soundEngine.playSound(for: .regular, event: .press)
            soundEngine.playSound(for: .regular, event: .release)
            soundEngine.playSound(for: .space, event: .press)
            soundEngine.playSound(for: .space, event: .release)
            soundEngine.playSound(for: .enter, event: .press)
            soundEngine.playSound(for: .enter, event: .release)
            soundEngine.playSound(for: .backspace, event: .press)
            soundEngine.playSound(for: .backspace, event: .release)
            soundEngine.pause()
        }
    }
    
    @Test func selectedBlueSoundPackPersists() {
        let defaults = UserDefaults(suiteName: "kutuk-tests-\(UUID().uuidString)")!
        defaults.set("cherry-mx-blue", forKey: "selectedSoundPackId")
        
        let settings = SettingsManager(
            defaults: defaults,
            launchAtLoginController: MockLaunchAtLoginController()
        )
        
        #expect(settings.selectedSoundPack.id == SoundPack.cherryMXBlue.id)
        #expect(settings.selectedSoundPackId == SoundPack.cherryMXBlue.id)
        #expect(defaults.string(forKey: "selectedSoundPackId") == SoundPack.cherryMXBlue.id)
    }
    
    @Test func unsupportedSavedPackFallsBackToBrown() {
        let defaults = UserDefaults(suiteName: "kutuk-tests-\(UUID().uuidString)")!
        defaults.set("buckling-spring", forKey: "selectedSoundPackId")
        
        let settings = SettingsManager(
            defaults: defaults,
            launchAtLoginController: MockLaunchAtLoginController()
        )
        
        #expect(settings.selectedSoundPack.id == SoundPack.cherryMXBrown.id)
        #expect(settings.selectedSoundPackId == SoundPack.cherryMXBrown.id)
        #expect(defaults.string(forKey: "selectedSoundPackId") == SoundPack.cherryMXBrown.id)
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
