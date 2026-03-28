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

    /// Check if we have Input Monitoring permission by actually trying to create an event tap.
    /// This is more reliable than CGPreflightListenEventAccess() which can cache stale results.
    @discardableResult
    func checkPermission() -> Bool {
        // If we already have an active event tap, permission is definitely granted
        if eventTap != nil {
            setPermissionState(true)
            return true
        }

        // Try creating a test event tap — this is the ground truth
        let hasActualPermission = canCreateListenOnlyEventTap()
        print("🔐 Input Monitoring permission check: \(hasActualPermission)")
        setPermissionState(hasActualPermission)
        return hasActualPermission
    }

    /// Request Input Monitoring permission using the native macOS prompt
    func requestPermission() {
        _ = CGRequestListenEventAccess()
    }

    /// Open System Settings to the Input Monitoring pane
    func openSystemPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Monitoring

    /// Start monitoring keyboard events. Returns true if monitoring started successfully.
    @discardableResult
    func startMonitoring() -> Bool {
        guard eventTap == nil else {
            print("Already monitoring")
            return true
        }

        print("🎹 Creating event tap...")

        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)

        let callback: CGEventTapCallBack = { proxy, type, event, refcon -> Unmanaged<CGEvent>? in
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }

            let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon).takeUnretainedValue()

            // Handle tap being disabled by system
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let tap = monitor.eventTap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
                return Unmanaged.passUnretained(event)
            }

            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let keyType = monitor.classifyKey(Int(keyCode))
            let keyEvent: KeyEvent = type == .keyDown ? .press : .release

            DispatchQueue.main.async {
                monitor.onKeyEvent?(keyType, keyEvent)
            }

            return Unmanaged.passUnretained(event)
        }

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: selfPointer
        )

        guard let eventTap = eventTap else {
            print("❌ Failed to create event tap — permission not granted or restart required")
            setPermissionState(false)
            setMonitoringState(false)
            return false
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        setPermissionState(true)
        setMonitoringState(true)
        print("✅ Keyboard monitoring started")
        return true
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
        setMonitoringState(false)

        print("⏹ Stopped keyboard monitoring")
    }

    /// Restart the app to pick up newly granted permissions
    func restartApp() {
        let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [path]
        task.launch()
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Private

    private func canCreateListenOnlyEventTap() -> Bool {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        let testTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { _, _, event, _ in Unmanaged.passUnretained(event) },
            userInfo: nil
        )
        let hasTapAccess = testTap != nil
        if let testTap {
            CFMachPortInvalidate(testTap)
        }
        return hasTapAccess
    }

    private func setPermissionState(_ hasPermission: Bool) {
        if Thread.isMainThread {
            self.hasPermission = hasPermission
        } else {
            DispatchQueue.main.async {
                self.hasPermission = hasPermission
            }
        }
    }

    private func setMonitoringState(_ isMonitoring: Bool) {
        if Thread.isMainThread {
            self.isMonitoring = isMonitoring
        } else {
            DispatchQueue.main.async {
                self.isMonitoring = isMonitoring
            }
        }
    }

    // MARK: - Key Classification

    private func classifyKey(_ keyCode: Int) -> KeyType {
        switch keyCode {
        case kVK_Space:
            return .space
        case kVK_Return, kVK_ANSI_KeypadEnter:
            return .enter
        case kVK_Delete, kVK_ForwardDelete:
            return .backspace
        case kVK_Shift, kVK_RightShift,
             kVK_Control, kVK_RightControl,
             kVK_Option, kVK_RightOption,
             kVK_Command, kVK_RightCommand,
             kVK_CapsLock, kVK_Function:
            return .modifier
        default:
            return .regular
        }
    }
}
