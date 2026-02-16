//
//  RetryUtilities.swift
//  TinyTastesTracker
//
//  Utilities for retry logic and timeout handling
//

import Foundation

/// Execute an async operation with retry logic
func withRetry<T>(
    maxAttempts: Int = 3,
    operation: @escaping () async throws -> T
) async throws -> T {
    var lastError: Error?
    
    for attempt in 1...maxAttempts {
        do {
            return try await operation()
        } catch {
            lastError = error
            let firebaseError = FirebaseError.from(error)
            
            // Don't retry if error is not retryable
            guard firebaseError.isRetryable else {
                throw firebaseError
            }
            
            // Don't wait after last attempt
            if attempt < maxAttempts {
                let delay = calculateBackoff(attempt: attempt)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }
    
    throw lastError ?? FirebaseError.unknown(NSError(domain: "RetryFailed", code: -1))
}

/// Execute an async operation with timeout
func withTimeout<T>(
    seconds: TimeInterval,
    operation: @escaping () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        // Add the actual operation
        group.addTask {
            try await operation()
        }
        
        // Add timeout task
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw FirebaseError.operationTimeout
        }
        
        // Return first result (either success or timeout)
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

/// Calculate exponential backoff delay with jitter
private func calculateBackoff(attempt: Int) -> TimeInterval {
    let baseDelay = pow(2.0, Double(attempt - 1))
    let jitter = Double.random(in: 0...0.5)
    return min(baseDelay + jitter, 8.0) // Cap at 8 seconds
}
