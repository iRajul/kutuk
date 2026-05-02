//
//  MenuBarView.swift
//  kutuk
//
//  Main menu bar dropdown UI
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var soundEngine: SoundEngine
    @EnvironmentObject var keyboardMonitor: KeyboardMonitor

    /// Tracks what permission state the UI should show
    @State private var permissionState: PermissionUIState = .checking

    /// Timer that polls for permission changes after the user visits System Settings
    @State private var permissionPollTimer: Timer?

    /// Whether the user has clicked "Grant Input Monitoring" at least once this session
    @State private var userAttemptedGrant = false

    private enum PermissionUIState {
        case checking       // Initial state while we verify
        case granted        // Permission OK, monitoring works
        case needsGrant     // No permission yet — show "Grant Input Monitoring"
        case needsRestart   // Permission toggled on in Settings but process can't create tap — restart required
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            toggleSection

            Divider().padding(.vertical, 4)

            volumeSection

            Divider().padding(.vertical, 4)

            soundPackSection

            Divider().padding(.vertical, 4)

            settingsSection

            Divider().padding(.vertical, 4)

            footerSection
        }
        .padding(.vertical, 8)
        .frame(width: 300)
        .onAppear {
            syncPermissionState()
            startPermissionPollingIfNeeded()
        }
        .onDisappear {
            stopPermissionPolling()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            syncPermissionState()
        }
        .onChange(of: settings.isEnabled) { _, _ in
            syncPermissionState()
        }
    }

    // MARK: - Toggle Section

    private var toggleSection: some View {
        Button {
            settings.toggleEnabled()
        } label: {
            HStack {
                Image(systemName: settings.isEnabled ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(settings.isEnabled ? .green : .secondary)
                    .font(.system(size: 16))

                Text("Enabled")
                    .font(.system(size: 13))

                Spacer()

                Text(settings.hotKeyShortcut.displayString)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    // MARK: - Volume Section

    private var volumeSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "speaker.fill")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Slider(value: $settings.volume, in: 0...1) { _ in
                soundEngine.volume = Float(settings.volume)
            }
            .controlSize(.small)

            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Text("\(Int(settings.volume * 100))%")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 32, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    // MARK: - Sound Pack Section

    private var soundPackSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Sound Pack")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.bottom, 2)

            ForEach(SoundPack.visiblePacks) { pack in
                Button {
                    settings.selectSoundPack(pack)
                    soundEngine.loadSoundPack(pack)
                    soundEngine.playPreview()
                } label: {
                    HStack {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .semibold))
                            .frame(width: 16)
                            .opacity(settings.selectedSoundPackId == pack.id ? 1 : 0)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(pack.name)
                                .font(.system(size: 13))

                            Text(pack.description)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 3)
            }
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 2) {

            // Permission banner — only shown when there's a problem
            switch permissionState {
            case .needsGrant:
                Button {
                    userAttemptedGrant = true
                    keyboardMonitor.requestPermission()
                    keyboardMonitor.openSystemPreferences()
                } label: {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 12))

                        Text("Grant Input Monitoring")
                            .font(.system(size: 13))

                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)

            case .needsRestart:
                Button {
                    keyboardMonitor.restartApp()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 12))

                        Text("Restart to Apply Permission")
                            .font(.system(size: 13))

                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)

            case .checking, .granted:
                EmptyView()
            }

            // Launch at Login
            Button {
                settings.launchAtLogin.toggle()
            } label: {
                HStack {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 16)
                        .opacity(settings.launchAtLogin ? 1 : 0)

                    Text("Launch at Login")
                        .font(.system(size: 13))

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 6) {
                Text("Toggle Shortcut")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                HStack {
                    Text("Modifiers")
                        .font(.system(size: 12))

                    Spacer()

                    Picker("Modifiers", selection: $settings.hotKeyModifierPresetRawValue) {
                        ForEach(HotKeyShortcut.ModifierPreset.allCases) { preset in
                            Text(preset.title).tag(preset.rawValue)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 160)
                }

                HStack {
                    Text("Key")
                        .font(.system(size: 12))

                    Spacer()

                    Picker("Key", selection: $settings.hotKeyKeyCode) {
                        ForEach(HotKeyShortcut.keyOptions) { option in
                            Text(option.title).tag(Int(option.keyCode))
                        }
                    }
                    .labelsHidden()
                    .frame(width: 72)
                }

                Text("Current: \(settings.hotKeyShortcut.displayString)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                if let url = URL(string: "https://github.com/iRajul/kutuk") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                HStack {
                    Text("About Kutuk")
                        .font(.system(size: 13))
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Text("Quit")
                        .font(.system(size: 13))

                    Spacer()

                    Text("⌘Q")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q", modifiers: .command)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Permission Management

    private func syncPermissionState() {
        // Try to start monitoring — this is the most reliable permission check
        if settings.isEnabled {
            let started = keyboardMonitor.startMonitoring()
            if started {
                permissionState = .granted
                stopPermissionPolling()
            } else {
                // Could not create event tap
                keyboardMonitor.stopMonitoring()
                // Check if preflight says yes but tap fails — means restart needed
                let preflightSaysYes = CGPreflightListenEventAccess()
                if preflightSaysYes || userAttemptedGrant {
                    permissionState = .needsRestart
                } else {
                    permissionState = .needsGrant
                }
                startPermissionPollingIfNeeded()
            }
        } else {
            keyboardMonitor.stopMonitoring()
            // Just check permission status without starting
            let canCreateTap = keyboardMonitor.checkPermission()
            if canCreateTap {
                permissionState = .granted
                stopPermissionPolling()
            } else {
                let preflightSaysYes = CGPreflightListenEventAccess()
                if preflightSaysYes || userAttemptedGrant {
                    permissionState = .needsRestart
                } else {
                    permissionState = .needsGrant
                }
                startPermissionPollingIfNeeded()
            }
        }
    }

    /// Poll every 2 seconds to detect when the user grants Input Monitoring permission
    private func startPermissionPollingIfNeeded() {
        guard permissionPollTimer == nil else { return }
        guard permissionState == .needsGrant || permissionState == .needsRestart else { return }

        permissionPollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            DispatchQueue.main.async {
                // Try to actually create event tap
                let canTap = keyboardMonitor.checkPermission()
                if canTap {
                    permissionState = .granted
                    stopPermissionPolling()
                    if settings.isEnabled {
                        keyboardMonitor.startMonitoring()
                    }
                } else {
                    // Check if preflight changed (user toggled it on in Settings)
                    let preflightSaysYes = CGPreflightListenEventAccess()
                    if preflightSaysYes && permissionState == .needsGrant {
                        permissionState = .needsRestart
                    }
                }
            }
        }
    }

    private func stopPermissionPolling() {
        permissionPollTimer?.invalidate()
        permissionPollTimer = nil
    }
}

#Preview {
    MenuBarView()
        .environmentObject(SettingsManager())
        .environmentObject(SoundEngine())
        .environmentObject(KeyboardMonitor())
}
