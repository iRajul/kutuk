//
//  OnboardingView.swift
//  kutuk
//
//  Permission request onboarding screen
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var permissionGranted = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "keyboard.fill")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Title
            Text("Kutuk needs access")
                .font(.system(size: 20, weight: .semibold))
            
            // Description
            VStack(spacing: 12) {
                Text("To play sounds when you type, Kutuk needs **Input Monitoring** permission.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Text("Your keystrokes are never recorded or transmitted.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .italic()
            }
            .frame(maxWidth: 280)
            
            // Action Button
            Button {
                openSystemPreferences()
            } label: {
                HStack {
                    Text("Open System Settings")
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            // Check Permission Button
            if !permissionGranted {
                Button {
                    checkPermission()
                } label: {
                    Text("I've granted permission")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(32)
        .frame(width: 360, height: 340)
        .onAppear {
            startPermissionPolling()
        }
    }
    
    private func openSystemPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func checkPermission() {
        if canCreateEventTap() {
            print("🔐 Permission granted! Dismissing onboarding.")
            permissionGranted = true
            dismiss()
        }
    }
    
    private func startPermissionPolling() {
        // Poll for permission every second
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            let hasPermission = canCreateEventTap()
            print("🔐 Polling permission: \(hasPermission)")
            if hasPermission {
                timer.invalidate()
                permissionGranted = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismiss()
                }
            }
        }
    }
    
    /// More reliable permission check - try creating an event tap
    /// AXIsProcessTrusted() can return stale cached values on macOS
    private func canCreateEventTap() -> Bool {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        let testTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { _, _, event, _ in Unmanaged.passUnretained(event) },
            userInfo: nil
        )
        return testTap != nil
    }
}

#Preview {
    OnboardingView()
}
