//
//  DesignSystem.swift
//  Chirp
//
//  Created by Connor Hammond on 11/6/25.
//

import SwiftUI

// MARK: - Design System
enum DesignSystem {

    // MARK: - Currency Configuration
    private static var currentCurrencyCode: String = "USD"
    private static var currentCurrencySymbol: String = "$"

    static func updateCurrency(code: String, symbol: String) {
        currentCurrencyCode = code
        currentCurrencySymbol = symbol
    }

    static var currencyCode: String { currentCurrencyCode }
    static var currencySymbol: String { currentCurrencySymbol }

    // MARK: - Colors
    enum Colors {
        // Primary accent (Blue for trust & productivity)
        static var accent: Color {
            Color(nsColor: NSColor(named: "AccentColor") ?? NSColor.controlAccentColor)
        }

        static let accentBlue = Color(hex: "007AFF")      // SF Blue
        static let accentTeal = Color(hex: "5AC8FA")      // Teal
        static let accentPurple = Color(hex: "AF52DE")    // Purple for special moments

        // Success & earnings (Green for balance)
        static let success = Color(hex: "34C759")
        static let successSubtle = Color(hex: "34C759").opacity(0.7)

        // Focus & concentration
        static let focusBlue = Color(hex: "0A84FF")       // Lighter blue for dark mode
        static let focusTeal = Color(hex: "64D2FF")       // Cyan for highlights

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

        // Gradients
        static let primaryGradient = LinearGradient(
            colors: [accentBlue, accentTeal],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let celebrationGradient = LinearGradient(
            colors: [accentPurple, accentBlue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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

    // MARK: - Animations
    enum Animations {
        // SwiftUI Spring Animations (feels alive!)
        static let smooth = SwiftUI.Animation.smooth(duration: 0.25)
        static let snappy = SwiftUI.Animation.snappy(duration: 0.18)
        static let bouncy = SwiftUI.Animation.bouncy(duration: 0.35)

        // Custom springs for specific interactions
        static let buttonPress = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let cardEntrance = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let celebration = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)

        // Legacy durations (for non-animation use)
        static let quickDuration: Double = 0.12
        static let normalDuration: Double = 0.18
        static let smoothDuration: Double = 0.25
        static let slowDuration: Double = 0.35
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

    // Hover effects for interactive elements
    func hoverEffect(scale: CGFloat = 1.02) -> some View {
        self.modifier(HoverEffectModifier(scale: scale))
    }

    // Animated spring transition
    func springTransition(value: some Equatable) -> some View {
        self.animation(DesignSystem.Animations.smooth, value: value)
    }
}

// MARK: - Hover Effect Modifier
struct HoverEffectModifier: ViewModifier {
    let scale: CGFloat
    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovering ? scale : 1.0)
            .brightness(isHovering ? 0.05 : 0)
            .animation(DesignSystem.Animations.snappy, value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
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
        formatter.currencyCode = DesignSystem.currencyCode
        return formatter.string(from: NSNumber(value: self)) ?? "\(DesignSystem.currencySymbol)0.00"
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
