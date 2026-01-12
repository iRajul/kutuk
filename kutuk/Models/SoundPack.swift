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
    /// Files are expected to be named: {packId}_{keyType}_{event}_{variation}.mp3
    /// e.g., cherry-mx-blue_regular_press_1.mp3
    func soundURLs(for keyType: KeyType, event: KeyEvent) -> [URL] {
        let eventSuffix = event == .press ? "press" : "release"
        let prefix = "\(id)_\(keyType.rawValue)_\(eventSuffix)"
        
        var urls: [URL] = []
        
        // Supported audio formats (prefer MP3, fallback to WAV)
        let extensions = ["mp3", "wav", "caf"]
        
        // Try numbered variations (cherry-mx-blue_regular_press_1.mp3, etc.)
        for i in 1...5 {
            for ext in extensions {
                if let url = Bundle.main.url(forResource: "\(prefix)_\(i)", withExtension: ext) {
                    urls.append(url)
                    break  // Found this variation, move to next number
                }
            }
        }
        
        // Fall back to single file without number (cherry-mx-blue_space_press.mp3, etc.)
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
    
    static let cherryMXBrown = SoundPack(
        id: "cherry-mx-brown",
        name: "Cherry MX Brown",
        description: "Tactile, quieter"
    )
    
    static let cherryMXRed = SoundPack(
        id: "cherry-mx-red",
        name: "Cherry MX Red",
        description: "Linear, smooth, quiet"
    )
    
    static let topre = SoundPack(
        id: "topre",
        name: "Topre",
        description: "Thocky, rubber dome feel"
    )
    
    static let bucklingSpring = SoundPack(
        id: "buckling-spring",
        name: "Buckling Spring",
        description: "Classic IBM Model M"
    )
    
    /// All available sound packs
    static let allPacks: [SoundPack] = [
        .cherryMXBlue,
        .cherryMXBrown,
        .cherryMXRed,
        .topre,
        .bucklingSpring
    ]
}
