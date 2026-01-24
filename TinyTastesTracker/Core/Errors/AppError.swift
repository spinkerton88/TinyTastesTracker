//
//  AppError.swift
//  TinyTastesTracker
//
//  Centralized error type system with user-friendly messages
//

import Foundation

enum AppError: LocalizedError {
    // MARK: - Network Errors
    case noInternetConnection
    case requestTimeout
    case serverUnavailable
    
    // MARK: - AI Service Errors
    case apiKeyMissing
    case apiKeyInvalid
    case rateLimitExceeded(retryAfter: TimeInterval?)
    case quotaExceeded
    case modelUnavailable
    case invalidResponse
    case contentFiltered
    
    // MARK: - Data Errors
    case dataCorrupted
    case saveFailed
    case loadFailed
    
    // MARK: - Generic
    case unknown(Error)
    
    // MARK: - User-Facing Error Messages
    
    var errorDescription: String? {
        switch self {
        // Network Errors
        case .noInternetConnection:
            return "No Internet Connection"
        case .requestTimeout:
            return "Request Timed Out"
        case .serverUnavailable:
            return "Service Unavailable"
            
        // AI Service Errors
        case .apiKeyMissing:
            return "AI Service Not Configured"
        case .apiKeyInvalid:
            return "Invalid API Configuration"
        case .rateLimitExceeded(let retryAfter):
            if let seconds = retryAfter {
                let minutes = Int(seconds / 60)
                return "Too Many Requests (Try again in \(minutes)m)"
            }
            return "Too Many Requests"
        case .quotaExceeded:
            return "Daily Limit Reached"
        case .modelUnavailable:
            return "AI Service Unavailable"
        case .invalidResponse:
            return "Invalid Response"
        case .contentFiltered:
            return "Content Filtered"
            
        // Data Errors
        case .dataCorrupted:
            return "Data Corrupted"
        case .saveFailed:
            return "Save Failed"
        case .loadFailed:
            return "Load Failed"
            
        // Generic
        case .unknown(let error):
            return "Unexpected Error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        // Network Errors
        case .noInternetConnection:
            return "Please check your internet connection and try again. Some features may work offline with cached data."
        case .requestTimeout:
            return "The request took too long. Please check your connection and try again."
        case .serverUnavailable:
            return "The service is temporarily unavailable. Please try again in a few moments."
            
        // AI Service Errors
        case .apiKeyMissing:
            return "The AI service is not configured. Please check your API key in the app settings."
        case .apiKeyInvalid:
            return "The API key is invalid or has been revoked. Please update your API key in GenerativeAI-Info.plist or check the console for details."
        case .rateLimitExceeded(let retryAfter):
            if let seconds = retryAfter {
                let minutes = Int(seconds / 60)
                return "You've made too many requests. Please wait \(minutes) minute\(minutes == 1 ? "" : "s") before trying again."
            }
            return "You've made too many requests. Please wait a moment before trying again."
        case .quotaExceeded:
            return "You've reached your daily AI usage limit. The limit will reset tomorrow. Some features may work with cached data."
        case .modelUnavailable:
            return "The AI model is temporarily unavailable. Please try again later."
        case .invalidResponse:
            return "Received an unexpected response from the AI service. Please try again."
        case .contentFiltered:
            return "The content was filtered by safety settings. Please try rephrasing your request."
            
        // Data Errors
        case .dataCorrupted:
            return "The data appears to be corrupted. You may need to delete and recreate this item."
        case .saveFailed:
            return "Failed to save data. Please ensure you have enough storage space and try again."
        case .loadFailed:
            return "Failed to load data. Please restart the app and try again."
            
        // Generic
        case .unknown:
            return "An unexpected error occurred. Please try again or restart the app."
        }
    }
    
    /// Indicates whether the operation should be retried
    var shouldRetry: Bool {
        switch self {
        case .noInternetConnection, .requestTimeout, .serverUnavailable:
            return true
        case .rateLimitExceeded, .modelUnavailable:
            return true
        case .apiKeyMissing, .apiKeyInvalid, .quotaExceeded, .contentFiltered:
            return false
        case .invalidResponse:
            return true
        case .dataCorrupted, .saveFailed, .loadFailed:
            return false
        case .unknown:
            return false
        }
    }
    
    /// Indicates whether this error should be logged for analytics
    var shouldLog: Bool {
        switch self {
        case .noInternetConnection:
            return false // Common, not actionable
        case .apiKeyMissing, .apiKeyInvalid:
            return true // Configuration issue
        case .quotaExceeded:
            return true // Usage monitoring
        case .dataCorrupted:
            return true // Data integrity issue
        default:
            return true
        }
    }
}

// MARK: - Error Mapping Helpers

extension AppError {
    /// Maps common errors to AppError types
    static func from(_ error: Error) -> AppError {
        // Already an AppError
        if let appError = error as? AppError {
            return appError
        }
        
        // Check error description for common patterns
        let errorDescription = error.localizedDescription.lowercased()
        
        // Network errors
        if errorDescription.contains("network") || errorDescription.contains("internet") {
            return .noInternetConnection
        }
        
        if errorDescription.contains("timeout") || errorDescription.contains("timed out") {
            return .requestTimeout
        }
        
        // API errors
        if errorDescription.contains("api key") || errorDescription.contains("apikey") {
            if errorDescription.contains("not found") || errorDescription.contains("missing") {
                return .apiKeyMissing
            }
            return .apiKeyInvalid
        }
        
        if errorDescription.contains("rate limit") || errorDescription.contains("too many requests") {
            return .rateLimitExceeded(retryAfter: nil)
        }
        
        if errorDescription.contains("quota") || errorDescription.contains("limit exceeded") {
            return .quotaExceeded
        }
        
        if errorDescription.contains("model") && errorDescription.contains("unavailable") {
            return .modelUnavailable
        }
        
        if errorDescription.contains("filtered") || errorDescription.contains("safety") {
            return .contentFiltered
        }
        
        // Data errors
        if errorDescription.contains("corrupt") {
            return .dataCorrupted
        }
        
        if errorDescription.contains("save") || errorDescription.contains("write") {
            return .saveFailed
        }
        
        if errorDescription.contains("load") || errorDescription.contains("read") {
            return .loadFailed
        }
        
        // Default to unknown
        return .unknown(error)
    }
}
