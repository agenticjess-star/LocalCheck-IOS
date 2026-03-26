import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @Binding var hasSeenOnboarding: Bool

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "mappin.and.ellipse",
            iconSecondary: "figure.pickleball",
            headline: "Find Your Court",
            subtitle: "Discover pickup courts near you and see who's there right now — no group texts needed.",
            tint: Theme.orange
        ),
        OnboardingPage(
            icon: "person.3.fill",
            iconSecondary: nil,
            headline: "Check In. Show Up.",
            subtitle: "Let people know you're at the court. See who else is playing before you head out.",
            tint: Theme.teal
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            iconSecondary: nil,
            headline: "Track Your Rep",
            subtitle: "Log games, climb the ELO rankings, and build your local reputation over time.",
            tint: Theme.orange
        ),
    ]

    var body: some View {
        ZStack {
            Theme.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            withAnimation { hasSeenOnboarding = true }
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.textTertiary)
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, 12)
                .frame(height: 44)

                // Pages
                TabView(selection: $currentPage) {
                    pageView(pages[0]).tag(0)
                    pageView(pages[1]).tag(1)
                    pageView(pages[2]).tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Custom page indicator + CTA
                VStack(spacing: 24) {
                    // Dots
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? Theme.orange : Theme.textTertiary.opacity(0.4))
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }

                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation(.spring(response: 0.4)) { currentPage += 1 }
                        } else {
                            withAnimation { hasSeenOnboarding = true }
                        }
                    } label: {
                        Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: Theme.buttonHeight)
                            .background(Theme.orange, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                    }
                    .padding(.horizontal, Theme.screenPadding)
                }
                .padding(.bottom, 48)
            }
        }
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 16) {
            Spacer()

            // Icon cluster
            ZStack {
                Circle()
                    .fill(page.tint.opacity(0.1))
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(page.tint.opacity(0.06))
                    .frame(width: 180, height: 180)

                Image(systemName: page.icon)
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(page.tint)

                if let secondary = page.iconSecondary {
                    Image(systemName: secondary)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Theme.teal)
                        .offset(x: 48, y: -40)
                }
            }
            .padding(.bottom, 20)

            Text(page.headline)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)

            Text(page.subtitle)
                .font(.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

private struct OnboardingPage {
    let icon: String
    let iconSecondary: String?
    let headline: String
    let subtitle: String
    let tint: Color
}
