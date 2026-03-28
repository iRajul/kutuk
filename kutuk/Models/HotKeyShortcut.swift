//
//  HotKeyShortcut.swift
//  kutuk
//
//  Persisted model for the global toggle shortcut
//

import Foundation
import Carbon.HIToolbox

struct HotKeyShortcut: Equatable, Hashable {
    struct KeyOption: Identifiable, Hashable {
        let keyCode: UInt32
        let title: String
        
        var id: UInt32 { keyCode }
    }
    
    enum ModifierPreset: String, CaseIterable, Identifiable {
        case command
        case optionCommand
        case controlCommand
        case shiftCommand
        case controlOptionCommand
        
        var id: String { rawValue }
        
        var carbonFlags: UInt32 {
            switch self {
            case .command:
                return UInt32(cmdKey)
            case .optionCommand:
                return UInt32(optionKey | cmdKey)
            case .controlCommand:
                return UInt32(controlKey | cmdKey)
            case .shiftCommand:
                return UInt32(shiftKey | cmdKey)
            case .controlOptionCommand:
                return UInt32(controlKey | optionKey | cmdKey)
            }
        }
        
        var title: String {
            switch self {
            case .command:
                return "Command"
            case .optionCommand:
                return "Option + Command"
            case .controlCommand:
                return "Control + Command"
            case .shiftCommand:
                return "Shift + Command"
            case .controlOptionCommand:
                return "Control + Option + Command"
            }
        }
        
        var symbols: String {
            switch self {
            case .command:
                return "⌘"
            case .optionCommand:
                return "⌥⌘"
            case .controlCommand:
                return "⌃⌘"
            case .shiftCommand:
                return "⇧⌘"
            case .controlOptionCommand:
                return "⌃⌥⌘"
            }
        }
    }
    
    let keyCode: UInt32
    let modifierPreset: ModifierPreset
    
    static let defaultShortcut = HotKeyShortcut(
        keyCode: UInt32(kVK_ANSI_K),
        modifierPreset: .optionCommand
    )
    
    static let keyOptions: [KeyOption] = [
        KeyOption(keyCode: UInt32(kVK_ANSI_A), title: "A"),
        KeyOption(keyCode: UInt32(kVK_ANSI_B), title: "B"),
        KeyOption(keyCode: UInt32(kVK_ANSI_C), title: "C"),
        KeyOption(keyCode: UInt32(kVK_ANSI_D), title: "D"),
        KeyOption(keyCode: UInt32(kVK_ANSI_E), title: "E"),
        KeyOption(keyCode: UInt32(kVK_ANSI_F), title: "F"),
        KeyOption(keyCode: UInt32(kVK_ANSI_G), title: "G"),
        KeyOption(keyCode: UInt32(kVK_ANSI_H), title: "H"),
        KeyOption(keyCode: UInt32(kVK_ANSI_I), title: "I"),
        KeyOption(keyCode: UInt32(kVK_ANSI_J), title: "J"),
        KeyOption(keyCode: UInt32(kVK_ANSI_K), title: "K"),
        KeyOption(keyCode: UInt32(kVK_ANSI_L), title: "L"),
        KeyOption(keyCode: UInt32(kVK_ANSI_M), title: "M"),
        KeyOption(keyCode: UInt32(kVK_ANSI_N), title: "N"),
        KeyOption(keyCode: UInt32(kVK_ANSI_O), title: "O"),
        KeyOption(keyCode: UInt32(kVK_ANSI_P), title: "P"),
        KeyOption(keyCode: UInt32(kVK_ANSI_Q), title: "Q"),
        KeyOption(keyCode: UInt32(kVK_ANSI_R), title: "R"),
        KeyOption(keyCode: UInt32(kVK_ANSI_S), title: "S"),
        KeyOption(keyCode: UInt32(kVK_ANSI_T), title: "T"),
        KeyOption(keyCode: UInt32(kVK_ANSI_U), title: "U"),
        KeyOption(keyCode: UInt32(kVK_ANSI_V), title: "V"),
        KeyOption(keyCode: UInt32(kVK_ANSI_W), title: "W"),
        KeyOption(keyCode: UInt32(kVK_ANSI_X), title: "X"),
        KeyOption(keyCode: UInt32(kVK_ANSI_Y), title: "Y"),
        KeyOption(keyCode: UInt32(kVK_ANSI_Z), title: "Z"),
    ]
    
    var carbonModifiers: UInt32 {
        modifierPreset.carbonFlags
    }
    
    var keyTitle: String {
        Self.keyOptions.first(where: { $0.keyCode == keyCode })?.title ?? "K"
    }
    
    var displayString: String {
        modifierPreset.symbols + keyTitle
    }
}
