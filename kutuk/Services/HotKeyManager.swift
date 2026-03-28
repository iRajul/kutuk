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
    private var currentShortcut: HotKeyShortcut
    
    /// Callback when hotkey is pressed
    var onHotKeyPressed: (() -> Void)?
    
    // MARK: - Initialization
    
    init(shortcut: HotKeyShortcut = .defaultShortcut) {
        self.currentShortcut = shortcut
        installEventHandlerIfNeeded()
        registerHotKey(shortcut)
    }
    
    deinit {
        unregisterHotKey()
    }
    
    // MARK: - Registration
    
    private func installEventHandlerIfNeeded() {
        guard eventHandler == nil else { return }
        
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
        
    }
    
    private func registerHotKey(_ shortcut: HotKeyShortcut) {
        unregisterRegisteredHotKey()
        
        let hotKeyID = EventHotKeyID(signature: OSType(0x4B555455), id: 1)  // "KUTU" signature
        
        RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        print("Registered hotkey: \(shortcut.displayString)")
    }
    
    func updateHotKey(_ shortcut: HotKeyShortcut) {
        guard shortcut != currentShortcut else { return }
        
        currentShortcut = shortcut
        registerHotKey(shortcut)
    }
    
    private func unregisterHotKey() {
        unregisterRegisteredHotKey()
        
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
    
    private func unregisterRegisteredHotKey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }
}
