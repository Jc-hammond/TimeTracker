//
//  BirdMascot.swift
//  TimeTracker
//
//  Created by Connor Hammond on 11/6/25.
//

import SwiftUI

// MARK: - Bird Mascot Component
struct BirdMascot: View {
    let mood: Mood
    let size: CGFloat

    enum Mood {
        case focused      // Working, zen pose
        case celebrating  // Wings up, happy
        case encouraging  // Warm, friendly
        case resting      // Peaceful, relaxed
        case thoughtful   // Studying, contemplating
    }

    init(mood: Mood = .encouraging, size: CGFloat = 120) {
        self.mood = mood
        self.size = size
    }

    var body: some View {
        ZStack {
            // Body
            birdBody

            // Wings (position changes by mood)
            birdWings

            // Eyes
            birdEyes

            // Beak
            birdBeak
        }
        .frame(width: size, height: size)
    }

    // MARK: - Bird Parts

    private var birdBody: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.accentBlue.opacity(0.9),
                        DesignSystem.Colors.accentTeal.opacity(0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size * 0.6, height: size * 0.7)
            .overlay(
                // Belly highlight
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size * 0.4, height: size * 0.5)
                    .offset(y: size * 0.1)
            )
    }

    private var birdWings: some View {
        HStack(spacing: size * 0.4) {
            // Left wing
            wing(isLeft: true)

            // Right wing
            wing(isLeft: false)
        }
        .offset(y: wingsOffset)
    }

    private func wing(isLeft: Bool) -> some View {
        Ellipse()
            .fill(DesignSystem.Colors.accentBlue.opacity(0.7))
            .frame(width: size * 0.25, height: size * 0.35)
            .rotationEffect(.degrees(isLeft ? wingRotation : -wingRotation))
            .offset(x: isLeft ? -size * 0.15 : size * 0.15)
    }

    private var birdEyes: some View {
        HStack(spacing: size * 0.15) {
            eye
            eye
        }
        .offset(y: eyesOffset)
    }

    private var eye: some View {
        ZStack {
            // White part
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.12, height: size * 0.12)

            // Pupil
            Circle()
                .fill(Color.black)
                .frame(width: size * 0.06, height: eyeHeight)
        }
    }

    private var birdBeak: some View {
        // Simple triangle beak
        Triangle()
            .fill(DesignSystem.Colors.accentPurple.opacity(0.8))
            .frame(width: size * 0.1, height: size * 0.08)
            .offset(y: size * 0.05)
    }

    // MARK: - Mood-based Properties

    private var wingsOffset: CGFloat {
        switch mood {
        case .focused, .thoughtful, .resting:
            return size * 0.02 // Wings down
        case .celebrating:
            return -size * 0.1 // Wings up
        case .encouraging:
            return size * 0.05 // Slightly raised
        }
    }

    private var wingRotation: Double {
        switch mood {
        case .focused, .resting:
            return 20 // Relaxed
        case .celebrating:
            return 45 // Wide open
        case .encouraging:
            return 30 // Slightly open
        case .thoughtful:
            return 15 // Close to body
        }
    }

    private var eyesOffset: CGFloat {
        switch mood {
        case .focused:
            return -size * 0.15 // Eyes slightly closed
        case .celebrating, .encouraging:
            return -size * 0.18 // Eyes wide open
        case .resting:
            return -size * 0.12 // Eyes half closed
        case .thoughtful:
            return -size * 0.16 // Normal
        }
    }

    private var eyeHeight: CGFloat {
        switch mood {
        case .focused:
            return size * 0.04 // Squinted
        case .resting:
            return size * 0.03 // Almost closed
        default:
            return size * 0.06 // Normal
        }
    }
}

// MARK: - Triangle Shape for Beak
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Bird with Message Component
struct BirdMascotWithMessage: View {
    let mood: BirdMascot.Mood
    let message: String
    let size: CGFloat

    init(mood: BirdMascot.Mood, message: String, size: CGFloat = 120) {
        self.mood = mood
        self.message = message
        self.size = size
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.clear) {
            BirdMascot(mood: mood, size: size)
                .scaleEffect(animationScale)
                .animation(DesignSystem.Animations.bouncy.repeatForever(autoreverses: true), value: animationScale)
                .onAppear {
                    startAnimation()
                }

            if !message.isEmpty {
                Text(message)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }

    @State private var animationScale: CGFloat = 1.0

    private func startAnimation() {
        // Gentle breathing animation
        withAnimation(DesignSystem.Animations.smooth.repeatForever(autoreverses: true)) {
            animationScale = 1.05
        }
    }
}

// MARK: - Preview
#Preview("Bird Moods") {
    VStack(spacing: 32) {
        HStack(spacing: 24) {
            VStack {
                BirdMascot(mood: .focused, size: 80)
                Text("Focused")
                    .font(.caption)
            }

            VStack {
                BirdMascot(mood: .celebrating, size: 80)
                Text("Celebrating")
                    .font(.caption)
            }

            VStack {
                BirdMascot(mood: .encouraging, size: 80)
                Text("Encouraging")
                    .font(.caption)
            }
        }

        HStack(spacing: 24) {
            VStack {
                BirdMascot(mood: .resting, size: 80)
                Text("Resting")
                    .font(.caption)
            }

            VStack {
                BirdMascot(mood: .thoughtful, size: 80)
                Text("Thoughtful")
                    .font(.caption)
            }
        }

        Divider()
            .padding(.vertical)

        BirdMascotWithMessage(
            mood: .encouraging,
            message: "Ready to start tracking?",
            size: 120
        )
    }
    .padding()
}
