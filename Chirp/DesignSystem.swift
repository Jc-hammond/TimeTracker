//
//  DesignSystem.swift
//  TimeTracker
//
//  Created by Connor Hammond on 11/6/25.
//

import SwiftUI

// MARK: - Design System
enum DesignSystem {

    // MARK: - Colors
    enum Colors {
        // Primary accent
        static let accent = Color(hex: "FF6B35")
        static let accentDark = Color(hex: "FF8C42")

        // Success & earnings
        static let success = Color.green.opacity(0.7)

        // Client colors
        static let clientColors: [String] = [
            "007AFF", // Blue
            "AF52DE", // Purple
            "FF2D55", // Pink
            "FF3B30", // Red
            "FF9500", // Orange
            "FFCC00", // Yellow
            "34C759", // Green
            "5AC8FA"  // Teal
        ]

        // Backgrounds
        static var cardBackground: Color {
            Color(nsColor: .controlBackgroundColor)
        }

        static var secondaryBackground: Color {
            Color(nsColor: .windowBackgroundColor)
        }

        // Text colors
        static var primaryText: Color {
            Color(nsColor: .labelColor)
        }

        static var secondaryText: Color {
            Color(nsColor: .secondaryLabelColor)
        }

        static var tertiaryText: Color {
            Color(nsColor: .tertiaryLabelColor)
        }
    }

    // MARK: - Typography
    enum Typography {
        // Display (Timer)
        static let timerFont = Font.system(size: 48, weight: .semibold, design: .rounded)

        // Titles
        static let title1 = Font.system(size: 28, weight: .bold, design: .default)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .default)
        static let title3 = Font.system(size: 17, weight: .semibold, design: .default)

        // Body
        static let body = Font.system(size: 15, weight: .regular, design: .default)
        static let callout = Font.system(size: 13, weight: .regular, design: .default)
        static let caption = Font.system(size: 11, weight: .regular, design: .default)

        // Monospace (for numbers)
        static let monospace = Font.system(size: 15, weight: .regular, design: .monospaced)
        static let monospaceLarge = Font.system(size: 17, weight: .medium, design: .monospaced)
    }

    // MARK: - Spacing
    enum Spacing {
        static let tight: CGFloat = 4
        static let close: CGFloat = 8
        static let comfortable: CGFloat = 12
        static let clear: CGFloat = 16
        static let spacious: CGFloat = 24
        static let generous: CGFloat = 32
        static let dramatic: CGFloat = 48
    }

    // MARK: - Corner Radius
    enum CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let xlarge: CGFloat = 16
    }

    // MARK: - Shadows
    enum Shadows {
        static let card: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            Color.black.opacity(0.08), 24, 0, 8
        )

        static let subtle: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            Color.black.opacity(0.05), 8, 0, 2
        )
    }

    // MARK: - Animation Durations
    enum Animation {
        static let quick: Double = 0.12
        static let normal: Double = 0.18
        static let smooth: Double = 0.25
        static let slow: Double = 0.35
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.large)
            .shadow(
                color: DesignSystem.Shadows.card.color,
                radius: DesignSystem.Shadows.card.radius,
                x: DesignSystem.Shadows.card.x,
                y: DesignSystem.Shadows.card.y
            )
    }

    func subtleShadow() -> some View {
        self.shadow(
            color: DesignSystem.Shadows.subtle.color,
            radius: DesignSystem.Shadows.subtle.radius,
            x: DesignSystem.Shadows.subtle.x,
            y: DesignSystem.Shadows.subtle.y
        )
    }
}

// MARK: - Format Helpers
extension TimeInterval {
    var formattedDuration: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) / 60 % 60
        let seconds = Int(self) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var formattedShort: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) / 60 % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "< 1m"
        }
    }
}

extension Double {
    var formattedCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
}

extension Date {
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: self)
        switch hour {
        case 0..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }
}
