//
//  OnboardingValidator.swift
//  TinyTastesTracker
//
//  Validation service for onboarding data
//

import Foundation

struct OnboardingValidator {
    
    // MARK: - Validation Results
    
    struct ValidationResult {
        let isValid: Bool
        let errors: [ValidationError]
        
        var errorMessage: String? {
            errors.first?.message
        }
    }
    
    enum ValidationError: Error {
        case emptyName
        case nameTooLong
        case invalidCharacters
        case futureBirthDate
        case birthDateTooOld
        case invalidGender
        case modeMismatch
        
        var message: String {
            switch self {
            case .emptyName:
                return "Please enter your baby's name"
            case .nameTooLong:
                return "Name must be 50 characters or less"
            case .invalidCharacters:
                return "Name contains invalid characters"
            case .futureBirthDate:
                return "Birth date cannot be in the future"
            case .birthDateTooOld:
                return "Birth date seems too far in the past. Please check the date."
            case .invalidGender:
                return "Please select a gender"
            case .modeMismatch:
                return "Selected mode doesn't match baby's age. Would you like to continue anyway?"
            }
        }
    }
    
    // MARK: - Validation Methods
    
    /// Validate baby name
    static func validateName(_ name: String) -> ValidationResult {
        var errors: [ValidationError] = []
        
        // Check if empty
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            errors.append(.emptyName)
            return ValidationResult(isValid: false, errors: errors)
        }
        
        // Check length
        if trimmedName.count > 50 {
            errors.append(.nameTooLong)
        }
        
        // Check for invalid characters (allow letters, spaces, hyphens, apostrophes)
        let allowedCharacterSet = CharacterSet.letters
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: "-'"))
        
        if trimmedName.unicodeScalars.contains(where: { !allowedCharacterSet.contains($0) }) {
            errors.append(.invalidCharacters)
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    /// Validate birth date
    static func validateBirthDate(_ date: Date) -> ValidationResult {
        var errors: [ValidationError] = []
        
        let now = Date()
        let fiveYearsAgo = Calendar.current.date(byAdding: .year, value: -5, to: now)!
        
        // Check if in future
        if date > now {
            errors.append(.futureBirthDate)
        }
        
        // Check if too old (more than 5 years)
        if date < fiveYearsAgo {
            errors.append(.birthDateTooOld)
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    /// Validate mode selection against age
    static func validateModeForAge(mode: AppMode, birthDate: Date) -> ValidationResult {
        let ageInMonths = Calendar.current.dateComponents([.month], from: birthDate, to: Date()).month ?? 0
        
        var errors: [ValidationError] = []
        
        // Check if mode matches age appropriately
        switch mode {
        case .newborn:
            if ageInMonths > 6 {
                errors.append(.modeMismatch)
            }
        case .explorer:
            if ageInMonths < 6 || ageInMonths > 12 {
                errors.append(.modeMismatch)
            }
        case .toddler:
            if ageInMonths < 12 {
                errors.append(.modeMismatch)
            }
        }
        
        // Mode mismatch is a warning, not a hard error
        return ValidationResult(isValid: true, errors: errors)
    }
    
    /// Validate complete profile data
    static func validateProfile(
        name: String,
        birthDate: Date,
        gender: Gender,
        mode: AppMode
    ) -> ValidationResult {
        var allErrors: [ValidationError] = []
        
        // Validate name
        let nameResult = validateName(name)
        allErrors.append(contentsOf: nameResult.errors)
        
        // Validate birth date
        let dateResult = validateBirthDate(birthDate)
        allErrors.append(contentsOf: dateResult.errors)
        
        // Validate mode (warning only)
        _ = validateModeForAge(mode: mode, birthDate: birthDate)
        // Don't add mode mismatch to hard errors
        
        return ValidationResult(isValid: allErrors.isEmpty, errors: allErrors)
    }
    
    // MARK: - Helper Methods
    
    /// Get suggested mode based on age
    static func suggestedMode(for birthDate: Date) -> AppMode {
        let ageInMonths = Calendar.current.dateComponents([.month], from: birthDate, to: Date()).month ?? 0
        
        if ageInMonths < 6 {
            return .newborn
        } else if ageInMonths < 12 {
            return .explorer
        } else {
            return .toddler
        }
    }
    
    /// Format age for display
    static func formatAge(from birthDate: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month], from: birthDate, to: Date())
        
        if let years = components.year, years > 0 {
            if let months = components.month, months > 0 {
                return "\(years) year\(years > 1 ? "s" : ""), \(months) month\(months > 1 ? "s" : "")"
            } else {
                return "\(years) year\(years > 1 ? "s" : "")"
            }
        } else if let months = components.month {
            return "\(months) month\(months > 1 ? "s" : "")"
        } else {
            return "Newborn"
        }
    }
}

// MARK: - Analytics Extension

extension OnboardingValidator {
    
    /// Track validation failure for analytics
    static func trackValidationFailure(_ error: ValidationError) {
        let errorType: String
        switch error {
        case .emptyName: errorType = "empty_name"
        case .nameTooLong: errorType = "name_too_long"
        case .invalidCharacters: errorType = "invalid_characters"
        case .futureBirthDate: errorType = "future_birth_date"
        case .birthDateTooOld: errorType = "birth_date_too_old"
        case .invalidGender: errorType = "invalid_gender"
        case .modeMismatch: errorType = "mode_mismatch"
        }
        
        AnalyticsService.shared.trackOnboardingValidationError(errorType: errorType)
    }
}
