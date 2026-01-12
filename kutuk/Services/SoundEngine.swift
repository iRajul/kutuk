//
//  SoundEngine.swift
//  kutuk
//
//  Audio engine for playing keyboard sounds with low latency
//

import Foundation
import AVFoundation
import Combine

/// High-performance audio engine for keyboard sounds
class SoundEngine: ObservableObject {
    
    // MARK: - Properties
    
    private var audioEngine: AVAudioEngine
    private var playerNodes: [AVAudioPlayerNode] = []
    private var mixerNode: AVAudioMixerNode
    
    /// Pre-loaded audio buffers for instant playback
    private var soundBuffers: [String: [AVAudioPCMBuffer]] = [:]
    
    /// Current sound pack
    private var currentPack: SoundPack?
    
    /// Volume (0.0 to 1.0)
    @Published var volume: Float = 0.8 {
        didSet {
            mixerNode.outputVolume = volume
        }
    }
    
    /// Number of player nodes for polyphony
    private let playerPoolSize = 8
    
    /// Current player index for round-robin scheduling
    private var currentPlayerIndex = 0
    
    // MARK: - Initialization
    
    init() {
        audioEngine = AVAudioEngine()
        mixerNode = audioEngine.mainMixerNode
        
        setupAudioEngine()
        // Sound pack will be loaded when MenuBarView appears
    }
    
    // MARK: - Setup
    
    private func setupAudioEngine() {
        // Create a pool of player nodes for polyphony
        for _ in 0..<playerPoolSize {
            let playerNode = AVAudioPlayerNode()
            audioEngine.attach(playerNode)
            audioEngine.connect(playerNode, to: mixerNode, format: nil)
            playerNodes.append(playerNode)
        }
        
        // Start the engine
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    // MARK: - Sound Pack Loading
    
    /// Load and buffer all sounds from a sound pack
    func loadSoundPack(_ pack: SoundPack) {
        guard pack.id != currentPack?.id else { return }
        
        currentPack = pack
        soundBuffers.removeAll()
        
        // Pre-load all sounds for each key type and event
        for keyType in KeyType.allCases {
            for event in [KeyEvent.press, KeyEvent.release] {
                let key = bufferKey(for: keyType, event: event)
                let urls = pack.soundURLs(for: keyType, event: event)
                
                var buffers: [AVAudioPCMBuffer] = []
                for url in urls {
                    if let buffer = loadAudioBuffer(from: url) {
                        buffers.append(buffer)
                    }
                }
                
                if !buffers.isEmpty {
                    soundBuffers[key] = buffers
                }
            }
        }
        
        print("Loaded sound pack: \(pack.name) with \(soundBuffers.count) sound groups")
    }
    
    private func loadAudioBuffer(from url: URL) -> AVAudioPCMBuffer? {
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat
            let frameCount = UInt32(audioFile.length)
            
            print("🔊 Loading: \(url.lastPathComponent) - \(format.sampleRate)Hz, \(format.channelCount)ch, \(frameCount) frames, duration: \(Double(frameCount)/format.sampleRate)s")
            
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                print("🔊 ❌ Failed to create buffer for \(url.lastPathComponent)")
                return nil
            }
            
            try audioFile.read(into: buffer)
            print("🔊 ✅ Loaded: \(url.lastPathComponent)")
            return buffer
        } catch {
            print("🔊 ❌ Failed to load audio file \(url.lastPathComponent): \(error)")
            return nil
        }
    }
    
    private func bufferKey(for keyType: KeyType, event: KeyEvent) -> String {
        "\(keyType.rawValue)_\(event == .press ? "press" : "release")"
    }
    
    // MARK: - Playback
    
    /// Play a sound for the given key type and event
    func playSound(for keyType: KeyType, event: KeyEvent) {
        let key = bufferKey(for: keyType, event: event)
        
        guard let buffers = soundBuffers[key], !buffers.isEmpty else {
            // Fall back to regular key sound if specific sound not found
            if keyType != .regular {
                playSound(for: .regular, event: event)
            }
            return
        }
        
        // Pick a random variation
        let buffer = buffers.randomElement()!
        
        // Get the next player from the pool (round-robin)
        let player = playerNodes[currentPlayerIndex]
        currentPlayerIndex = (currentPlayerIndex + 1) % playerPoolSize
        
        // Stop any currently playing sound on this player
        player.stop()
        
        // Apply random pitch and volume variation for natural feel
        let pitchVariation = Float.random(in: 0.95...1.05)
        let volumeVariation = Float.random(in: 0.9...1.0)
        
        player.volume = volume * volumeVariation
        player.rate = pitchVariation
        
        // Schedule and play
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        
        if !player.isPlaying {
            player.play()
        }
    }
    
    /// Play a preview sound for the current pack
    func playPreview() {
        playSound(for: .regular, event: .press)
        
        // Slight delay then play release sound
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.playSound(for: .regular, event: .release)
        }
    }
    
    // MARK: - Engine Control
    
    func pause() {
        audioEngine.pause()
    }
    
    func resume() {
        do {
            try audioEngine.start()
        } catch {
            print("Failed to resume audio engine: \(error)")
        }
    }
}
