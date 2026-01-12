//
//  HotKeyManager.swift
//  kutuk
//
//  Global hotkey registration for toggle shortcut
//

import Foundation
import Carbon.HIToolbox
import AppKit

/// Manages global hotkey for toggling sounds
class HotKeyManager {
    
    // MARK: - Properties
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    
    /// Callback when hotkey is pressed
    var onHotKeyPressed: (() -> Void)?
    
    /// Default hotkey: Option + Command + K
    private let defaultKeyCode: UInt32 = UInt32(kVK_ANSI_K)
    private let defaultModifiers: UInt32 = UInt32(optionKey | cmdKey)
    
    // MARK: - Initialization
    
    init() {
        registerHotKey()
    }
    
    deinit {
        unregisterHotKey()
    }
    
    // MARK: - Registration
    
    private func registerHotKey() {
        // Create event type spec for hotkey events
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        // Install event handler
        let handlerCallback: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            
            DispatchQueue.main.async {
                manager.onHotKeyPressed?()
            }
            
            return noErr
        }
        
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            handlerCallback,
            1,
            &eventType,
            selfPointer,
            &eventHandler
        )
        
        // Register the hotkey
        var hotKeyID = EventHotKeyID(signature: OSType(0x4B555455), id: 1)  // "KUTU" signature
        
        RegisterEventHotKey(
            defaultKeyCode,
            defaultModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        print("Registered hotkey: ⌥⌘K")
    }
    
    private func unregisterHotKey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
}
