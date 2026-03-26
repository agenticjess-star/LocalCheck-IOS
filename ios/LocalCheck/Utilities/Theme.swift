import SwiftUI

enum Theme {
    // MARK: - Primary accent
    static let orange = Color(red: 1.0, green: 0.45, blue: 0.1)
    static let orangeLight = Color(red: 1.0, green: 0.55, blue: 0.25)
    static let orangeDark = Color(red: 0.85, green: 0.35, blue: 0.05)

    // MARK: - Secondary accent (community / social cues)
    static let teal = Color(red: 0.2, green: 0.78, blue: 0.82)
    static let tealMuted = Color(red: 0.2, green: 0.78, blue: 0.82).opacity(0.15)

    // MARK: - Surfaces
    static let surface = Color(red: 0.07, green: 0.07, blue: 0.09)
    static let surfaceElevated = Color(red: 0.12, green: 0.12, blue: 0.14)
    static let surfaceCard = Color(red: 0.15, green: 0.15, blue: 0.17)
    static let surfaceBorder = Color.white.opacity(0.08)

    // MARK: - Text
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.35)

    // MARK: - Semantic
    static let confirmed = orange
    static let unconfirmed = Color.white.opacity(0.25)
    static let green = Color(red: 0.2, green: 0.84, blue: 0.5)
    static let red = Color(red: 1.0, green: 0.35, blue: 0.35)

    // MARK: - Rankings
    static let eloGold = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let eloSilver = Color(red: 0.75, green: 0.75, blue: 0.78)
    static let eloBronze = Color(red: 0.8, green: 0.5, blue: 0.2)

    // MARK: - Gradients
    static let heroGradient = LinearGradient(
        colors: [surface, surfaceElevated, orange.opacity(0.25)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGlow = LinearGradient(
        colors: [orange.opacity(0.08), Color.clear],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Dimensions
    static let buttonHeight: CGFloat = 50
    static let inputHeight: CGFloat = 50
    static let cornerRadius: CGFloat = 14
    static let inputCornerRadius: CGFloat = 12
    static let screenPadding: CGFloat = 20
}
