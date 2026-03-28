//
//  SoundPack.swift
//  kutuk
//
//  Models for sound pack data
//

import Foundation

/// Represents the type of key being pressed
enum KeyType: String, CaseIterable {
    case regular    // Standard alphanumeric keys
    case space      // Spacebar
    case enter      // Enter/Return
    case backspace  // Backspace/Delete
    case modifier   // Shift, Cmd, Option, Control
}

/// Represents the keyboard event type
enum KeyEvent {
    case press
    case release
}

/// Represents a complete sound pack with all key sounds
struct SoundPack: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    
    /// Base directory for sound files
    var bundlePath: String {
        "Sounds/\(id)"
    }
    
    /// Get sound file URLs for a specific key type and event
    /// Files are expected to be named: {packId}_{keyType}_{event}_{variation}.{ext}
    /// e.g., cherry-mx-blue_regular_press_1.wav
    func soundURLs(for keyType: KeyType, event: KeyEvent) -> [URL] {
        let eventSuffix = event == .press ? "press" : "release"
        let prefix = "\(id)_\(keyType.rawValue)_\(eventSuffix)"
        
        var urls: [URL] = []
        
        // Prefer the sanitized WAV assets bundled with the public build.
        let extensions = ["wav", "mp3", "caf"]

        // Try numbered variations (cherry-mx-blue_regular_press_1.wav, etc.)
        for i in 1...5 {
            for ext in extensions {
                if let url = Bundle.main.url(forResource: "\(prefix)_\(i)", withExtension: ext) {
                    urls.append(url)
                    break  // Found this variation, move to next number
                }
            }
        }
        
        // Fall back to single file without number (cherry-mx-blue_space_press.wav, etc.)
        if urls.isEmpty {
            for ext in extensions {
                if let url = Bundle.main.url(forResource: prefix, withExtension: ext) {
                    urls.append(url)
                    break
                }
            }
        }
        
        // If no specific sound, fall back to regular key sound
        if urls.isEmpty && keyType != .regular {
            return soundURLs(for: .regular, event: event)
        }
        
        return urls
    }
    
    static func == (lhs: SoundPack, rhs: SoundPack) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Pre-bundled Sound Packs

extension SoundPack {
    static let cherryMXBlue = SoundPack(
        id: "cherry-mx-blue",
        name: "Cherry MX Blue",
        description: "Clicky, tactile, loud"
    )
    
    static let defaultPack = cherryMXBlue
    
    /// All bundled sound packs for the public build.
    static let allPacks: [SoundPack] = [
        .cherryMXBlue
    ]
    
    static let visiblePacks = allPacks
}
