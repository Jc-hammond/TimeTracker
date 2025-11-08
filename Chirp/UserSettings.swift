//
//  UserSettings.swift
//  Chirp
//
//  User settings and preferences
//

import Foundation
import SwiftData

@Model
final class UserSettings {
    var userName: String
    var currencyCode: String
    var defaultHourlyRate: Double
    var showEarningsInMenuBar: Bool
    var roundTimeToNearestMinute: Int // 0 = no rounding, 1, 5, 15, 30

    // Metadata
    var createdAt: Date
    var updatedAt: Date

    init(userName: String = "",
         currencyCode: String = "USD",
         defaultHourlyRate: Double = 0.0,
         showEarningsInMenuBar: Bool = false,
         roundTimeToNearestMinute: Int = 0) {
        self.userName = userName
        self.currencyCode = currencyCode
        self.defaultHourlyRate = defaultHourlyRate
        self.showEarningsInMenuBar = showEarningsInMenuBar
        self.roundTimeToNearestMinute = roundTimeToNearestMinute
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // Get or create singleton settings
    static func getOrCreate(context: ModelContext) -> UserSettings {
        let descriptor = FetchDescriptor<UserSettings>()

        do {
            let existing = try context.fetch(descriptor)
            if let settings = existing.first {
                return settings
            }
        } catch {
            LogManager.data.error("Failed to fetch user settings", error: error)
        }

        // Create default settings
        let newSettings = UserSettings()
        context.insert(newSettings)

        do {
            try context.save()
        } catch {
            LogManager.data.error("Failed to save new user settings", error: error)
        }

        return newSettings
    }
}

// MARK: - Currency Support
extension UserSettings {
    static let supportedCurrencies: [(code: String, name: String, symbol: String)] = [
        ("USD", "US Dollar", "$"),
        ("EUR", "Euro", "€"),
        ("GBP", "British Pound", "£"),
        ("JPY", "Japanese Yen", "¥"),
        ("CAD", "Canadian Dollar", "CA$"),
        ("AUD", "Australian Dollar", "A$"),
        ("CHF", "Swiss Franc", "CHF"),
        ("CNY", "Chinese Yuan", "¥"),
        ("INR", "Indian Rupee", "₹"),
        ("MXN", "Mexican Peso", "MX$"),
    ]

    var currencySymbol: String {
        UserSettings.supportedCurrencies.first(where: { $0.code == currencyCode })?.symbol ?? "$"
    }
}
