//
//  KeyboardMonitor.swift
//  kutuk
//
//  Global keyboard monitoring using CGEvent tap
//

import Foundation
import Cocoa
import Combine
import Carbon.HIToolbox

/// Monitors global keyboard events and triggers sound playback
class KeyboardMonitor: ObservableObject {
    
    // MARK: - Properties
    
    @Published var hasPermission: Bool = false
    @Published var isMonitoring: Bool = false
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    /// Callback for key events
    var onKeyEvent: ((KeyType, KeyEvent) -> Void)?
    
    // MARK: - Initialization
    
    init() {
        // Permission will be checked when MenuBarView appears
    }
    
    // MARK: - Permission
    
    /// Check if we have Input Monitoring permission
    /// Note: AXIsProcessTrusted() can return stale/cached values, so we also
    /// try creating an event tap as the true test of permission
    @discardableResult
    func checkPermission() -> Bool {
        // First check the API (may be cached/stale)
        let axTrusted = AXIsProcessTrusted()
        
        // More reliable check: try to actually create an event tap
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        let testTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { _, _, event, _ in Unmanaged.passUnretained(event) },
            userInfo: nil
        )
        
        // Permission is granted if event tap creation succeeds
        let hasActualPermission = testTap != nil
        
        print("🔐 Permission check - AXIsProcessTrusted: \(axTrusted), EventTap: \(hasActualPermission)")
        
        Task { @MainActor in
            self.hasPermission = hasActualPermission
        }
        
        return hasActualPermission
    }
    
    /// Request permission by opening System Preferences
    func requestPermission() {
        // Create options dictionary requesting to prompt the user
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    /// Open System Preferences to the correct pane
    func openSystemPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Monitoring
    
    /// Start monitoring keyboard events
    func startMonitoring() {
        // Skip permission check - just try to create tap
        // (AXIsProcessTrusted can return stale results)
        
        guard eventTap == nil else {
            print("Already monitoring")
            return
        }
        
        print("🎹 Creating event tap...")
        
        // Create event tap for key events
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
        
        // Use a wrapper to bridge to the callback
        let callback: CGEventTapCallBack = { proxy, type, event, refcon -> Unmanaged<CGEvent>? in
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
            
            let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon).takeUnretainedValue()
            
            // Handle tap being disabled (system might disable it temporarily)
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let tap = monitor.eventTap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
                return Unmanaged.passUnretained(event)
            }
            
            // Get key code
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let keyType = monitor.classifyKey(Int(keyCode))
            let keyEvent: KeyEvent = type == .keyDown ? .press : .release
            
            // Dispatch to main thread
            DispatchQueue.main.async {
                monitor.onKeyEvent?(keyType, keyEvent)
            }
            
            // Pass the event through (don't consume it)
            return Unmanaged.passUnretained(event)
        }
        
        // Create the tap
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,  // We only listen, don't modify events
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: selfPointer
        )
        
        guard let eventTap = eventTap else {
            print("Failed to create event tap")
            return
        }
        
        // Add to run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        isMonitoring = true
        print("Started keyboard monitoring")
    }
    
    /// Stop monitoring keyboard events
    func stopMonitoring() {
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        
        eventTap = nil
        runLoopSource = nil
        isMonitoring = false
        
        print("Stopped keyboard monitoring")
    }
    
    // MARK: - Key Classification
    
    /// Classify a key code into a KeyType
    private func classifyKey(_ keyCode: Int) -> KeyType {
        switch keyCode {
        // Spacebar
        case kVK_Space:
            return .space
            
        // Enter/Return
        case kVK_Return, kVK_ANSI_KeypadEnter:
            return .enter
            
        // Backspace/Delete
        case kVK_Delete, kVK_ForwardDelete:
            return .backspace
            
        // Modifiers
        case kVK_Shift, kVK_RightShift,
             kVK_Control, kVK_RightControl,
             kVK_Option, kVK_RightOption,
             kVK_Command, kVK_RightCommand,
             kVK_CapsLock, kVK_Function:
            return .modifier
            
        // Everything else is a regular key
        default:
            return .regular
        }
    }
}
