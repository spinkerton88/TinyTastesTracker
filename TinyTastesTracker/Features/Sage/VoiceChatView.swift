//
//  VoiceChatView.swift
//  TinyTastesTracker
//
//  Voice chat interface for Sage AI assistant
//

import SwiftUI
import AVFoundation

struct VoiceChatView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var appState: AppState
    let initialContext: String
    
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var audioPlayer = AudioPlayer()
    @StateObject private var geminiLive: GeminiLiveService
    
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var audioLevel: CGFloat = 0.0
    
    init(appState: AppState, initialContext: String) {
        self.appState = appState
        self.initialContext = initialContext
        
        // Initialize GeminiLiveService with API key
        _geminiLive = StateObject(wrappedValue: GeminiLiveService(apiKey: appState.geminiApiKey ?? ""))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [appState.themeColor.opacity(0.1), appState.themeColor.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Status indicator
                    VStack(spacing: 12) {
                        Image(systemName: statusIcon)
                            .font(.system(size: 60)) // Large decorative icon
                            .foregroundStyle(appState.themeColor)
                            .symbolEffect(.pulse, isActive: audioRecorder.isRecording || geminiLive.isSpeaking)
                        
                        Text(statusText)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        if !geminiLive.transcript.isEmpty {
                            Text(geminiLive.transcript)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .frame(maxHeight: 200)
                        }
                    }
                    
                    // Waveform visualization
                    WaveformView(
                        isActive: audioRecorder.isRecording || geminiLive.isSpeaking,
                        level: audioLevel,
                        color: appState.themeColor
                    )
                    .frame(height: 100)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Controls
                    HStack(spacing: 40) {
                        // End call button
                        Button {
                            HapticManager.impact(style: .medium)
                            disconnect()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 60)) // Large decorative icon
                                .foregroundStyle(.red)
                                .symbolEffect(.bounce, value: audioRecorder.isRecording)
                        }
                        
                        // Push to talk button
                        Button {
                            toggleRecording()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(audioRecorder.isRecording ? appState.themeColor : Color.gray.opacity(0.3))
                                    .frame(width: 80, height: 80)
                                    .shadow(color: audioRecorder.isRecording ? appState.themeColor.opacity(0.5) : .clear, radius: 20)
                                
                                Image(systemName: "mic.fill")
                                    .font(.title) // Was .system(size: 32)
                                    .foregroundStyle(.white)
                            }
                        }
                        .scaleEffect(audioRecorder.isRecording ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3), value: audioRecorder.isRecording)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Sage Voice Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        disconnect()
                    }
                }
            }
            .alert("Voice Chat Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .task {
                await connectToGemini()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusIcon: String {
        if audioRecorder.isRecording {
            return "ear"
        } else if geminiLive.isSpeaking {
            return "speaker.wave.3"
        } else {
            return "sage.leaf.sprig"
        }
    }
    
    private var statusText: String {
        if audioRecorder.isRecording {
            return "Listening..."
        } else if geminiLive.isSpeaking {
            return "Sage is speaking..."
        } else if geminiLive.connectionState == .connecting {
            return "Connecting..."
        } else {
            return "Tap mic to talk"
        }
    }
    
    // MARK: - Actions
    
    private func connectToGemini() async {
        do {
            let systemInstruction = """
            You are Sage, a friendly and knowledgeable AI assistant for the Tiny Tastes Tracker app.
            You help parents with infant and toddler feeding, nutrition, and meal planning.
            
            Current context: \(initialContext)
            
            Be conversational, empathetic, and concise in your audio responses.
            Provide actionable advice and encourage healthy feeding practices.
            """
            
            try await geminiLive.connect(systemInstruction: systemInstruction)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func toggleRecording() {
        if audioRecorder.isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        guard audioRecorder.permissionGranted else {
            errorMessage = "Microphone permission is required for voice chat. Please enable it in Settings."
            showError = true
            return
        }
        
        HapticManager.impact(style: .medium)
        
        do {
            try audioRecorder.startRecording { buffer in
                Task {
                    try? await geminiLive.sendAudio(buffer)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func stopRecording() {
        HapticManager.impact(style: .light)
        audioRecorder.stopRecording()
    }
    
    private func disconnect() {
        stopRecording()
        audioPlayer.stop()
        geminiLive.disconnect()
        dismiss()
    }
}

// MARK: - Waveform View

struct WaveformView: View {
    let isActive: Bool
    let level: CGFloat
    let color: Color
    
    @State private var animationPhase = 0.0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<30, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(isActive ? 0.8 : 0.3))
                    .frame(width: 3)
                    .frame(height: barHeight(for: index))
                    .animation(.easeInOut(duration: 0.3).repeatForever(), value: animationPhase)
            }
        }
        .onAppear {
            if isActive {
                animationPhase = 1.0
            }
        }
        .onChange(of: isActive) { _, newValue in
            animationPhase = newValue ? 1.0 : 0.0
        }
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        if !isActive {
            return 4
        }
        
        let baseHeight: CGFloat = 10
        let maxHeight: CGFloat = 80
        let variation = sin(Double(index) * 0.5 + animationPhase * 2) * 0.5 + 0.5
        
        return baseHeight + (maxHeight - baseHeight) * variation
    }
}

#Preview {
    VoiceChatView(
        appState: AppState(),
        initialContext: "User is on the Newborn Dashboard"
    )
}
