//
//  SageChatView.swift
//  TinyTastesTracker
//
//  Created by Antigravity AI on 12/24/24.
//

import SwiftUI

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp = Date()
    var followUps: [String] = []
    var confidence: Confidence? = .high
    var userFeedback: Feedback? = nil
    
    enum Confidence: String {
        case high = "High Confidence"
        case medium = "Likely accurate"
        case low = "Uncertain"
    }
    
    enum Feedback {
        case thumbsUp, thumbsDown
    }
}

struct SageChatView: View {
    @Bindable var appState: AppState
    var initialContext: String? = nil
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Welcome Message
                            if messages.isEmpty {
                                VStack(spacing: 16) {
                                    Image("sage.leaf.sprig")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 80, height: 80)
                                        .foregroundStyle(appState.themeColor)
                                        .padding()
                                        .background(appState.themeColor.opacity(0.1))
                                        .clipShape(Circle())
                                    
                                    Text("Hi, I'm Sage! 👋")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    if let context = initialContext {
                                        Text("I see you're working on: \"\(context)\"")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .padding(.bottom, 4)
                                    }
                                    
                                    Text("How can I help you with this?")
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                        .foregroundStyle(.secondary)
                                    
                                    // Initial Suggestions (Context Aware if possible, but generic for now)
                                    VStack(alignment: .leading, spacing: 12) {
                                        SuggestionButton(text: "Give me a tip for this", action: sendMessage)
                                        SuggestionButton(text: "Is this safe?", action: sendMessage)
                                    }
                                    .padding(.top)
                                }
                                .padding(.top, 40)
                                .padding()
                            }
                            
                            // Chat History
                            ForEach(messages) { message in
                                MessageBubble(message: message, themeColor: appState.themeColor, onFollowUpTap: sendMessage)
                            }
                            
                            if isLoading {
                                HStack {
                                    ProgressView()
                                        .tint(appState.themeColor)
                                    Text("Sage is verifying sources...")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages) { _, _ in
                        if let lastId = messages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input Area
                HStack(alignment: .bottom, spacing: 12) {
                    TextField("Ask Sage...", text: $inputText, axis: .vertical)
                        .padding(12)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .lineLimit(1...5)
                    
                    Button {
                        sendMessage(inputText)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title) // Was .system(size: 32)
                            .foregroundStyle(inputText.isEmpty || isLoading ? Color.gray : appState.themeColor)
                    }
                    .disabled(inputText.isEmpty || isLoading)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Ask Sage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func sendMessage(_ text: String) {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }
        
        let userMsg = ChatMessage(content: cleanText, isUser: true)
        messages.append(userMsg)
        inputText = ""
        isLoading = true
        
        Task {
            do {
                // Call Gemini via AppState
                let responseText = try await appState.askSage(question: cleanText)
                
                // Parse Follow-ups
                let parts = parseResponse(responseText)
                let aiMsg = ChatMessage(content: parts.content, isUser: false, followUps: parts.followUps)
                
                await MainActor.run {
                    messages.append(aiMsg)
                    isLoading = false
                }
            } catch GeminiError.apiKeyNotFound {
                await MainActor.run {
                    let errorMsg = ChatMessage(content: """
                    ⚠️ **API Key Not Configured**
                    
                    The Gemini API key is missing or invalid. Please check:
                    
                    • Ensure `GenerativeAI-Info.plist` exists with a valid API key
                    • The API key should not be "YOUR_GEMINI_API_KEY_HERE"
                    • Get your API key from [Google AI Studio](https://aistudio.google.com/app/apikey)
                    """, isUser: false, confidence: nil)
                    messages.append(errorMsg)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorDescription = error.localizedDescription
                    let errorMsg: ChatMessage
                    
                    // Check for specific Gemini API errors
                    if errorDescription.contains("GenerateContentError error 1") {
                        errorMsg = ChatMessage(content: """
                        🔑 **API Key Issue Detected**
                        
                        The Gemini API rejected your request. This usually means:
                        
                        **Most Common Causes:**
                        • **Invalid API Key** - The key may be incorrect or expired
                        • **API Key Restrictions** - Check if your key has IP/app restrictions
                        • **Quota Exceeded** - You may have hit the free tier limit
                        • **Model Access** - Your key might not have access to `gemini-2.0-flash`
                        
                        **To Fix:**
                        1. Visit [Google AI Studio](https://aistudio.google.com/app/apikey)
                        2. Verify your API key is active and has no restrictions
                        3. Check your usage quota
                        4. Try creating a new API key if needed
                        5. Update `GenerativeAI-Info.plist` with the new key
                        
                        **Alternative:** Try using `gemini-1.5-flash` model instead (update in `GeminiService.swift`)
                        """, isUser: false, confidence: nil)
                    } else if errorDescription.contains("network") || errorDescription.contains("connection") {
                        errorMsg = ChatMessage(content: """
                        🌐 **Network Connection Issue**
                        
                        I'm having trouble connecting to the Gemini API. Please check:
                        
                        • Your device has an active internet connection
                        • The Gemini API service is available
                        
                        Error: \(errorDescription)
                        """, isUser: false, confidence: nil)
                    } else {
                        errorMsg = ChatMessage(content: """
                        ⚠️ **Something Went Wrong**
                        
                        I encountered an error while processing your request.
                        
                        Error: \(errorDescription)
                        
                        Please try again or check your API configuration.
                        """, isUser: false, confidence: nil)
                    }
                    
                    messages.append(errorMsg)
                    isLoading = false
                }
            }
        }
    }
    
    private func parseResponse(_ text: String) -> (content: String, followUps: [String]) {
        var content = text
        var followUps: [String] = []
        
        if text.contains("FOLLOWUP:") {
            let components = text.components(separatedBy: "FOLLOWUP:")
            content = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Extract follow ups
            for i in 1..<components.count {
                let question = components[i].trimmingCharacters(in: .whitespacesAndNewlines)
                if !question.isEmpty {
                    followUps.append(question)
                }
            }
        }
        
        return (content, followUps)
    }
}

// MARK: - Subviews

struct MessageBubble: View {
    let message: ChatMessage
    let themeColor: Color
    let onFollowUpTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
            // Main Content
            Text(.init(message.content)) // Allows markdown
                .padding(12)
                .background(message.isUser ? themeColor : Color.gray.opacity(0.15))
                .foregroundStyle(message.isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .frame(maxWidth: 300, alignment: message.isUser ? .trailing : .leading)
            
            // Follow-up Suggestions (AI only)
            if !message.isUser && !message.followUps.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(message.followUps, id: \.self) { followUp in
                        Button {
                            onFollowUpTap(followUp)
                        } label: {
                            HStack {
                                Text(followUp)
                                    .font(.caption)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.left")
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
        
        // AI Attribution & Feedback (HIG Intelligence)
        if !message.isUser {
            HStack(spacing: 12) {
                if let confidence = message.confidence {
                    Label { Text(confidence.rawValue) } icon: { SageIcon(size: .small, style: .monochrome(.secondary)) }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Feedback Buttons
                HStack(spacing: 16) {
                    Button {
                        // Action handled by parent via binding in real app, local state for now
                    } label: {
                        Image(systemName: message.userFeedback == .thumbsUp ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.caption)
                            .foregroundStyle(message.userFeedback == .thumbsUp ? themeColor : .secondary)
                    }
                    
                    Button {
                        
                    } label: {
                        Image(systemName: message.userFeedback == .thumbsDown ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .font(.caption)
                            .foregroundStyle(message.userFeedback == .thumbsDown ? .orange : .secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
}

struct SuggestionButton: View {
    let text: String
    let action: (String) -> Void
    
    var body: some View {
        Button {
            action(text)
        } label: {
            HStack {
                Text(text)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Image(systemName: "arrow.up.left")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
