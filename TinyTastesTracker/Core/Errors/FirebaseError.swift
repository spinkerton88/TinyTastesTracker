//
//  FirebaseError.swift
//  TinyTastesTracker
//
//  Centralized error handling for Firebase operations
//

import Foundation
import FirebaseFirestore

/// Comprehensive error type for all Firebase operations
enum FirebaseError: LocalizedError {
    case networkUnavailable
    case authenticationExpired
    case permissionDenied
    case documentNotFound
    case operationTimeout
    case quotaExceeded
    case invalidData
    case conflictingOperation
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No Internet Connection"
        case .authenticationExpired:
            return "Session Expired"
        case .permissionDenied:
            return "Permission Denied"
        case .documentNotFound:
            return "Data Not Found"
        case .operationTimeout:
            return "Operation Timed Out"
        case .quotaExceeded:
            return "Storage Limit Reached"
        case .invalidData:
            return "Invalid Data"
        case .conflictingOperation:
            return "Conflicting Operation"
        case .unknown(let error):
            return "Unexpected Error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Please check your internet connection and try again. Your data has been saved locally and will sync when you're back online."
        case .authenticationExpired:
            return "Please sign in again to continue."
        case .permissionDenied:
            return "You don't have permission to perform this action. Please contact support if this seems wrong."
        case .documentNotFound:
            return "The requested data could not be found. It may have been deleted."
        case .operationTimeout:
            return "The operation took too long. Please check your connection and try again."
        case .quotaExceeded:
            return "You've reached your storage limit. Please free up space or upgrade your plan."
        case .invalidData:
            return "The data format is invalid. Please try again or contact support."
        case .conflictingOperation:
            return "Another operation is in progress. Please wait and try again."
        case .unknown:
            return "An unexpected error occurred. Please try again or contact support if the problem persists."
        }
    }
    
    /// Determines if this error type can be retried
    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .operationTimeout, .conflictingOperation:
            return true
        case .authenticationExpired, .permissionDenied, .documentNotFound, .quotaExceeded, .invalidData, .unknown:
            return false
        }
    }
    
    /// Priority level for error handling
    var priority: ErrorPriority {
        switch self {
        case .networkUnavailable:
            return .info // Common, expected scenario
        case .operationTimeout, .conflictingOperation:
            return .warning // Needs attention but not critical
        case .authenticationExpired, .permissionDenied, .documentNotFound, .quotaExceeded, .invalidData:
            return .critical // Requires immediate user action
        case .unknown:
            return .critical // Unknown errors are always critical
        }
    }
    
    /// Convert a Firebase error to our custom error type
    static func from(_ error: Error) -> FirebaseError {
        let nsError = error as NSError
        
        // Check for Firestore-specific errors
        if nsError.domain == FirestoreErrorDomain {
            switch FirestoreErrorCode.Code(rawValue: nsError.code) {
            case .unavailable:
                return .networkUnavailable
            case .unauthenticated:
                return .authenticationExpired
            case .permissionDenied:
                return .permissionDenied
            case .notFound:
                return .documentNotFound
            case .deadlineExceeded:
                return .operationTimeout
            case .resourceExhausted:
                return .quotaExceeded
            case .invalidArgument, .failedPrecondition:
                return .invalidData
            case .aborted:
                return .conflictingOperation
            default:
                return .unknown(error)
            }
        }
        
        // Check for network errors
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorCannotConnectToHost:
                return .networkUnavailable
            case NSURLErrorTimedOut:
                return .operationTimeout
            default:
                return .unknown(error)
            }
        }
        
        return .unknown(error)
    }
}

/// Priority level for error handling
enum ErrorPriority {
    case info       // Informational, no immediate action needed
    case warning    // Needs attention but not critical
    case critical   // Requires immediate user action
}
