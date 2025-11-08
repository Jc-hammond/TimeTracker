//
//  ValidationUtility.swift
//  Chirp
//
//  Input validation and sanitization utilities
//

import Foundation

enum ValidationUtility {

    // MARK: - Character Limits

    enum Limits {
        static let projectName = 100
        static let clientName = 100
        static let userName = 50
        static let notes = 1000
        static let hourlyRate = 999999.99
        static let maxDurationHours = 24.0
    }

    // MARK: - Validation Methods

    /// Validate and sanitize project name
    static func validateProjectName(_ name: String) -> ValidationResult {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return .invalid("Project name cannot be empty")
        }

        if trimmed.count > Limits.projectName {
            return .invalid("Project name must be \(Limits.projectName) characters or less")
        }

        return .valid(trimmed)
    }

    /// Validate and sanitize client name
    static func validateClientName(_ name: String) -> ValidationResult {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return .invalid("Client name cannot be empty")
        }

        if trimmed.count > Limits.clientName {
            return .invalid("Client name must be \(Limits.clientName) characters or less")
        }

        return .valid(trimmed)
    }

    /// Validate and sanitize user name
    static func validateUserName(_ name: String) -> ValidationResult {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.count > Limits.userName {
            return .invalid("Name must be \(Limits.userName) characters or less")
        }

        return .valid(trimmed)
    }

    /// Validate and sanitize notes
    static func validateNotes(_ notes: String) -> ValidationResult {
        if notes.count > Limits.notes {
            return .invalid("Notes must be \(Limits.notes) characters or less")
        }

        // Remove excessive newlines (more than 2 consecutive)
        let sanitized = notes.replacingOccurrences(
            of: "\n{3,}",
            with: "\n\n",
            options: .regularExpression
        )

        return .valid(sanitized)
    }

    /// Validate hourly rate
    static func validateHourlyRate(_ rate: String) -> ValidationResult {
        let trimmed = rate.trimmingCharacters(in: .whitespacesAndNewlines)

        // Allow empty (will be 0)
        if trimmed.isEmpty {
            return .valid("0")
        }

        // Check if valid number
        guard let rateValue = Double(trimmed) else {
            return .invalid("Please enter a valid number")
        }

        // Check range
        if rateValue < 0 {
            return .invalid("Rate cannot be negative")
        }

        if rateValue > Limits.hourlyRate {
            return .invalid("Rate cannot exceed \(Limits.hourlyRate.formattedCurrency)")
        }

        return .valid(String(format: "%.2f", rateValue))
    }

    /// Validate time entry duration
    static func validateDuration(start: Date, end: Date) -> ValidationResult {
        guard end > start else {
            return .invalid("End time must be after start time")
        }

        let duration = end.timeIntervalSince(start)
        let hours = duration / 3600.0

        if hours > Limits.maxDurationHours {
            return .warning("This entry is \(String(format: "%.1f", hours)) hours long. Is this correct?")
        }

        return .valid("")
    }

    /// Sanitize string for safe storage (remove control characters)
    static func sanitizeString(_ string: String) -> String {
        return string.components(separatedBy: .controlCharacters).joined()
    }

    /// Truncate string to maximum length
    static func truncate(_ string: String, to length: Int) -> String {
        if string.count <= length {
            return string
        }
        return String(string.prefix(length))
    }
}

// MARK: - Validation Result

enum ValidationResult {
    case valid(String)
    case invalid(String)
    case warning(String)

    var isValid: Bool {
        switch self {
        case .valid, .warning:
            return true
        case .invalid:
            return false
        }
    }

    var value: String? {
        switch self {
        case .valid(let value):
            return value
        default:
            return nil
        }
    }

    var message: String? {
        switch self {
        case .invalid(let msg), .warning(let msg):
            return msg
        case .valid:
            return nil
        }
    }

    var isWarning: Bool {
        if case .warning = self {
            return true
        }
        return false
    }
}

// MARK: - String Extensions for Validation

extension String {
    var isValidEmail: Bool {
        let emailRegex = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES[c] %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }

    var containsOnlyDigits: Bool {
        return CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: self))
    }

    var sanitized: String {
        return ValidationUtility.sanitizeString(self)
    }
}
