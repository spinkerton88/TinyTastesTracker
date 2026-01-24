//
//  AudioRecorder.swift
//  TinyTastesTracker
//
//  Real-time audio recording using AVFoundation for Gemini Live API
//

import AVFoundation
import Combine

/// Manages microphone audio capture for voice chat
class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var permissionGranted = false
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioFormat: AVAudioFormat?
    
    // Callback for streaming audio buffers
    private var onAudioBuffer: ((AVAudioPCMBuffer) -> Void)?
    
    override init() {
        super.init()
        checkPermission()
    }
    
    /// Check and request microphone permission
    func checkPermission() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            permissionGranted = true
        case .denied:
            permissionGranted = false
        case .undetermined:
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                }
            }
        @unknown default:
            permissionGranted = false
        }
    }
    
    /// Start recording audio
    /// - Parameter onAudioBuffer: Callback invoked with each audio buffer
    func startRecording(onAudioBuffer: @escaping (AVAudioPCMBuffer) -> Void) throws {
        guard permissionGranted else {
            throw AudioError.permissionDenied
        }
        
        guard !isRecording else { return }
        
        self.onAudioBuffer = onAudioBuffer
        
        // Configure audio session for recording
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create audio engine
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw AudioError.engineInitializationFailed
        }
        
        inputNode = audioEngine.inputNode
        
        // Configure audio format: 16-bit PCM, 16kHz mono (Gemini Live API requirement)
        audioFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 16000,
            channels: 1,
            interleaved: true
        )
        
        guard let audioFormat = audioFormat else {
            throw AudioError.invalidAudioFormat
        }
        
        // Install tap on input node to capture audio
        inputNode?.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: inputNode?.outputFormat(forBus: 0)
        ) { [weak self] (buffer, time) in
            guard let self = self else { return }
            
            // Convert to 16kHz mono if needed
            if let convertedBuffer = self.convertBuffer(buffer, to: audioFormat) {
                self.onAudioBuffer?(convertedBuffer)
            }
        }
        
        // Start audio engine
        try audioEngine.start()
        
        DispatchQueue.main.async {
            self.isRecording = true
        }
    }
    
    /// Stop recording audio
    func stopRecording() {
        guard isRecording else { return }
        
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
        
        onAudioBuffer = nil
    }
    
    /// Convert audio buffer to target format
    private func convertBuffer(_ buffer: AVAudioPCMBuffer, to format: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let converter = AVAudioConverter(from: buffer.format, to: format) else {
            return nil
        }
        
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * format.sampleRate / buffer.format.sampleRate)
        guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else {
            return nil
        }
        
        var error: NSError?
        converter.convert(to: convertedBuffer, error: &error) { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        return error == nil ? convertedBuffer : nil
    }
    
    deinit {
        stopRecording()
    }
}

// MARK: - Errors

enum AudioError: LocalizedError {
    case permissionDenied
    case engineInitializationFailed
    case invalidAudioFormat
    case recordingFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission is required for voice chat."
        case .engineInitializationFailed:
            return "Failed to initialize audio engine."
        case .invalidAudioFormat:
            return "Invalid audio format configuration."
        case .recordingFailed:
            return "Failed to start recording."
        }
    }
}
