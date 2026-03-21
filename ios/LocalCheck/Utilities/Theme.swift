import SwiftUI

enum Theme {
    static let orange = Color(red: 1.0, green: 0.45, blue: 0.1)
    static let orangeLight = Color(red: 1.0, green: 0.55, blue: 0.25)
    static let orangeDark = Color(red: 0.85, green: 0.35, blue: 0.05)

    static let surface = Color(red: 0.09, green: 0.09, blue: 0.1)
    static let surfaceElevated = Color(red: 0.13, green: 0.13, blue: 0.14)
    static let surfaceCard = Color(red: 0.15, green: 0.15, blue: 0.16)
    static let surfaceBorder = Color.white.opacity(0.06)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.35)

    static let confirmed = orange
    static let unconfirmed = Color.white.opacity(0.25)

    static let eloGold = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let eloSilver = Color(red: 0.75, green: 0.75, blue: 0.78)
    static let eloBronze = Color(red: 0.8, green: 0.5, blue: 0.2)

    static let green = Color(red: 0.2, green: 0.84, blue: 0.5)
    static let red = Color(red: 1.0, green: 0.35, blue: 0.35)
}
