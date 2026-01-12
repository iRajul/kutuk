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
    
    @State private var showingOnboarding = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Enable/Disable Toggle
            toggleSection
            
            Divider()
                .padding(.vertical, 4)
            
            // Volume Control
            volumeSection
            
            Divider()
                .padding(.vertical, 4)
            
            // Sound Pack Selection
            soundPackSection
            
            Divider()
                .padding(.vertical, 4)
            
            // Settings
            settingsSection
            
            Divider()
                .padding(.vertical, 4)
            
            // Footer
            footerSection
        }
        .padding(.vertical, 8)
        .frame(width: 260)
        .onAppear {
            setupKeyboardMonitoring()
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView()
        }
    }
    
    // MARK: - Toggle Section
    
    private var toggleSection: some View {
        Button {
            settings.toggleEnabled()
            if settings.isEnabled {
                keyboardMonitor.startMonitoring()
            } else {
                keyboardMonitor.stopMonitoring()
            }
        } label: {
            HStack {
                Image(systemName: settings.isEnabled ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(settings.isEnabled ? .green : .secondary)
                    .font(.system(size: 16))
                
                Text("Enabled")
                    .font(.system(size: 13))
                
                Spacer()
                
                Text("⌥⌘K")
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
            
            ForEach(SoundPack.allPacks) { pack in
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
            // Permission Status
            if !keyboardMonitor.hasPermission {
                Button {
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
        }
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                // Show about window
                if let url = URL(string: "https://github.com/kutuk-app") {
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
    
    // MARK: - Setup
    
    private func setupKeyboardMonitoring() {
        print("🎹 Setting up keyboard monitoring...")
        
        // Check permission on appear
        let hasPermission = keyboardMonitor.checkPermission()
        print("🎹 Permission status: \(hasPermission)")
        
        if !hasPermission {
            showingOnboarding = true
        } else if settings.isEnabled {
            keyboardMonitor.startMonitoring()
            print("🎹 Started monitoring")
        }
        
        // Connect keyboard events to sound engine
        // Capture references we need
        let engine = soundEngine
        let settingsRef = settings
        
        keyboardMonitor.onKeyEvent = { keyType, keyEvent in
            print("🎹 Key event: \(keyType) - \(keyEvent)")
            guard settingsRef.isEnabled else {
                print("🎹 Sound disabled, skipping")
                return
            }
            engine.playSound(for: keyType, event: keyEvent)
        }
        
        // Sync volume and load sound pack
        print("🎹 Loading sound pack: \(settings.selectedSoundPack.name)")
        soundEngine.volume = Float(settings.volume)
        soundEngine.loadSoundPack(settings.selectedSoundPack)
        print("🎹 Setup complete")
    }
}

#Preview {
    MenuBarView()
        .environmentObject(SettingsManager())
        .environmentObject(SoundEngine())
        .environmentObject(KeyboardMonitor())
}
