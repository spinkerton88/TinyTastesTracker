//
//  GeminiLiveService.swift
//  TinyTastesTracker
//
//  WebSocket client for Gemini Live API bidirectional audio streaming
//

import Foundation
import AVFoundation
import Combine

/// Connection state for Gemini Live session
enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String) // Changed from Error to String for Equatable conformance
}

/// Gemini Live API WebSocket client for voice chat
class GeminiLiveService: NSObject, ObservableObject {
    @Published var connectionState: ConnectionState = .disconnected
    @Published var isSpeaking = false
    @Published var transcript: String = ""
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private let audioPlayer = AudioPlayer()

    // Base path for Gemini Live API logic
    private let bidiPath = "/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent"

    override init() {
        super.init()
    }
    
    /// Connect to Gemini Live API with system instruction
    /// - Parameter systemInstruction: Context for the AI assistant
    func connect(systemInstruction: String) async throws {
        guard connectionState != .connected && connectionState != .connecting else {
            return
        }

        await MainActor.run {
            connectionState = .connecting
        }

        // Fetch backend URL and build WebSocket URL
        var backendBaseURL = SecureAPIKeyManager.shared.getBackendURL()

        // Convert https to wss for WebSocket
        if backendBaseURL.hasPrefix("http://") {
            backendBaseURL = backendBaseURL.replacingOccurrences(of: "http://", with: "ws://")
        } else if backendBaseURL.hasPrefix("https://") {
            backendBaseURL = backendBaseURL.replacingOccurrences(of: "https://", with: "wss://")
        }

        let wsURLString = backendBaseURL + bidiPath

        guard let url = URL(string: wsURLString) else {
            await MainActor.run {
                connectionState = .error("Invalid WebSocket URL")
            }
            throw GeminiLiveError.invalidURL
        }

        print("🔌 Connecting to WebSocket: \(wsURLString)")

        // Create WebSocket session
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)

        webSocketTask = session?.webSocketTask(with: url)
        webSocketTask?.resume()

        do {
            // Send initial setup message with system instruction
            try await sendSetupMessage(systemInstruction: systemInstruction)

            // Start listening for messages
            receiveMessages()

            await MainActor.run {
                connectionState = .connected
            }
            print("✅ Connected to Gemini Live")

        } catch {
            let errorMsg = "Connection failed: \(error.localizedDescription)"
            print("❌ \(errorMsg)")
            await MainActor.run {
                connectionState = .error(errorMsg)
            }
            throw error
        }
    }
    
    /// Send setup configuration to Gemini Live
    private func sendSetupMessage(systemInstruction: String) async throws {
        let setupMessage: [String: Any] = [
            "setup": [
                "model": "models/gemini-2.0-flash-exp",
                "generation_config": [
                    "response_modalities": ["AUDIO"],
                    "speech_config": [
                        "voice_config": [
                            "prebuilt_voice_config": [
                                "voice_name": "Puck" // Friendly, helpful voice
                            ]
                        ]
                    ]
                ],
                "system_instruction": [
                    "parts": [
                        ["text": systemInstruction]
                    ]
                ]
            ]
        ]
        
        try await sendMessage(setupMessage)
    }
    
    /// Send audio buffer to Gemini Live
    /// - Parameter buffer: PCM audio buffer (16kHz mono)
    func sendAudio(_ buffer: AVAudioPCMBuffer) async throws {
        guard connectionState == .connected else {
            throw GeminiLiveError.notConnected
        }
        
        // Convert AVAudioPCMBuffer to base64-encoded PCM data
        guard let audioData = bufferToData(buffer) else {
            throw GeminiLiveError.audioConversionFailed
        }
        
        let base64Audio = audioData.base64EncodedString()
        
        let message: [String: Any] = [
            "realtime_input": [
                "media_chunks": [
                    [
                        "mime_type": "audio/pcm",
                        "data": base64Audio
                    ]
                ]
            ]
        ]
        
        try await sendMessage(message)
    }
    
    /// Send JSON message over WebSocket
    private func sendMessage(_ message: [String: Any]) async throws {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw GeminiLiveError.serializationFailed
        }
        
        let message = URLSessionWebSocketTask.Message.string(jsonString)
        try await webSocketTask?.send(message)
    }
    
    /// Listen for incoming messages from Gemini Live
    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let message):
                self.handleMessage(message)
                // Continue listening
                self.receiveMessages()

            case .failure(let error):
                let errorMsg: String
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet:
                        errorMsg = "No internet connection"
                    case .timedOut:
                        errorMsg = "Connection timed out"
                    case .cannotConnectToHost:
                        errorMsg = "Cannot connect to server"
                    case .networkConnectionLost:
                        errorMsg = "Network connection lost"
                    default:
                        errorMsg = "Network error: \(urlError.localizedDescription)"
                    }
                } else {
                    errorMsg = "WebSocket error: \(error.localizedDescription)"
                }

                print("❌ \(errorMsg)")
                Task { @MainActor in
                    self.connectionState = .error(errorMsg)
                }
            }
        }
    }
    
    /// Handle incoming WebSocket message
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            guard let data = text.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return
            }
            
            processServerMessage(json)
            
        case .data(let audioData):
            // Binary audio data from WebSocket
            Task { @MainActor in
                self.isSpeaking = true
            }
            // Play audio using AudioPlayer
            audioPlayer.play(audioData: audioData)
            
        @unknown default:
            break
        }
    }
    
    /// Process JSON server message
    private func processServerMessage(_ json: [String: Any]) {
        // Handle server text (transcripts, status updates, etc.)
        if let serverContent = json["serverContent"] as? [String: Any],
           let modelTurn = serverContent["modelTurn"] as? [String: Any],
           let parts = modelTurn["parts"] as? [[String: Any]] {
            
            for part in parts {
                // Extract text transcript if available
                if let text = part["text"] as? String {
                    Task { @MainActor in
                        self.transcript += text
                    }
                }
                
                // Extract audio data if available
                if let inlineData = part["inlineData"] as? [String: String],
                   let base64Audio = inlineData["data"],
                   let audioData = Data(base64Encoded: base64Audio) {

                    // Play audio using AudioPlayer
                    audioPlayer.play(audioData: audioData)
                    Task { @MainActor in
                        self.isSpeaking = true
                    }
                }
            }
        }
        
        // Handle turn complete
        if let serverContent = json["serverContent"] as? [String: Any],
           serverContent["turnComplete"] != nil {
            Task { @MainActor in
                self.isSpeaking = false
            }
        }
    }
    
    /// Convert AVAudioPCMBuffer to Data
    private func bufferToData(_ buffer: AVAudioPCMBuffer) -> Data? {
        guard let channelData = buffer.int16ChannelData else {
            return nil
        }
        
        let channelDataPointer = channelData.pointee
        let dataSize = Int(buffer.frameLength) * MemoryLayout<Int16>.size
        
        return Data(bytes: channelDataPointer, count: dataSize)
    }
    
    /// Disconnect from Gemini Live
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        session?.invalidateAndCancel()
        session = nil
        
        Task { @MainActor in
            connectionState = .disconnected
            isSpeaking = false
            transcript = ""
        }
    }
    
    deinit {
        disconnect()
    }
}

// MARK: - URLSessionWebSocketDelegate

extension GeminiLiveService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connected")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        Task { @MainActor in
            connectionState = .disconnected
        }
    }
}

// MARK: - Errors

enum GeminiLiveError: LocalizedError {
    case invalidURL
    case notConnected
    case audioConversionFailed
    case serializationFailed
    case connectionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Gemini Live API URL"
        case .notConnected:
            return "Not connected to Gemini Live"
        case .audioConversionFailed:
            return "Failed to convert audio data"
        case .serializationFailed:
            return "Failed to serialize message"
        case .connectionFailed:
            return "Connection to Gemini Live failed"
        }
    }
}
