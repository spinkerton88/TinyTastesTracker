//
//  AudioPlayer.swift
//  TinyTastesTracker
//
//  Plays audio responses from Gemini Live API
//

import AVFoundation
import Combine

/// Manages audio playback for voice chat responses
class AudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    
    private var audioPlayer: AVAudioPlayer?
    private var audioQueue: [Data] = []
    private var isProcessingQueue = false
    
    override init() {
        super.init()
        configureAudioSession()
    }
    
    /// Configure audio session for playback
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    /// Play audio data (24kHz from Gemini Live API)
    /// - Parameter audioData: PCM audio data
    func play(audioData: Data) {
        // Add to queue
        audioQueue.append(audioData)
        
        // Start processing queue if not already processing
        if !isProcessingQueue {
            processQueue()
        }
    }
    
    /// Process queued audio data
    private func processQueue() {
        guard !audioQueue.isEmpty else {
            isProcessingQueue = false
            return
        }
        
        isProcessingQueue = true
        let audioData = audioQueue.removeFirst()
        
        do {
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            DispatchQueue.main.async {
                self.isPlaying = true
            }
        } catch {
            print("Failed to play audio: \(error)")
            // Continue processing queue even if one fails
            processQueue()
        }
    }
    
    /// Stop current playback and clear queue
    func stop() {
        audioPlayer?.stop()
        audioQueue.removeAll()
        isProcessingQueue = false
        
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
        }
        
        // Process next item in queue
        processQueue()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Audio player decode error: \(error?.localizedDescription ?? "unknown")")
        
        DispatchQueue.main.async {
            self.isPlaying = false
        }
        
        // Try next item in queue
        processQueue()
    }
    
    deinit {
        stop()
    }
}
