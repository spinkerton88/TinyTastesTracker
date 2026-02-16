import Foundation
import FirebaseAuth
import Observation

/// Protocol defining authentication service capabilities for dependency injection
protocol AuthenticationService {
    var userSession: FirebaseAuth.User? { get }
    func signInAnonymously() async throws
    func signInWithEmail(email: String, password: String) async throws
    func createAccount(email: String, password: String) async throws
    func signOut() throws
    func getUserId() -> String?
    func refreshAuthToken() async throws
    func handleAuthError(_ error: Error) async -> Bool
    func isAuthError(_ error: Error) -> Bool
}

@MainActor
@Observable
class AuthenticationManager: AuthenticationService {
    var userSession: FirebaseAuth.User?

    init() {
        self.userSession = Auth.auth().currentUser

        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.userSession = user
        }
    }

    func signInAnonymously() async throws {
        let result = try await Auth.auth().signInAnonymously()
        self.userSession = result.user
    }

    func signInWithEmail(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        self.userSession = result.user
    }

    func createAccount(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        self.userSession = result.user
    }

    func signOut() throws {
        try Auth.auth().signOut()
        self.userSession = nil
    }

    func getUserId() -> String? {
        return userSession?.uid
    }
    
    // MARK: - Token Refresh
    
    /// Refresh the authentication token
    func refreshAuthToken() async throws {
        guard let user = Auth.auth().currentUser else {
            throw FirebaseError.authenticationExpired
        }
        
        do {
            try await user.getIDTokenForcingRefresh(true)
        } catch {
            throw FirebaseError.from(error)
        }
    }
    
    /// Handle authentication errors and attempt recovery
    func handleAuthError(_ error: Error) async -> Bool {
        let firebaseError = FirebaseError.from(error)
        
        // Check if it's an auth expiration error
        if case .authenticationExpired = firebaseError {
            // Attempt token refresh
            do {
                try await refreshAuthToken()
                return true // Can retry operation
            } catch {
                print("❌ Token refresh failed: \(error)")
                // Token refresh failed, user needs to re-authenticate
                await MainActor.run {
                    // Sign out to force re-authentication
                    try? signOut()
                }
                return false
            }
        }
        
        return false
    }
    
    /// Check if an error is auth-related
    func isAuthError(_ error: Error) -> Bool {
        let firebaseError = FirebaseError.from(error)
        if case .authenticationExpired = firebaseError {
            return true
        }
        if case .permissionDenied = firebaseError {
            return true
        }
        return false
    }
}

enum AuthError: LocalizedError {
    case googleSignInNotAvailable

    var errorDescription: String? {
        switch self {
        case .googleSignInNotAvailable:
            return "Google Sign-In is not configured"
        }
    }
}
