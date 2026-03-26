import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: Int = 0
    @State private var hasSeenOnboarding: Bool = false

    var body: some View {
        Group {
            if appState.isInitializingApp {
                launchView
            } else if !appState.isAuthenticated && !hasSeenOnboarding {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
            } else if appState.requiresLocalCourtSelection {
                CourtMapView(onboardingMode: true)
            } else if appState.isAuthenticated {
                authenticatedTabs
            } else {
                AuthView()
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await appState.initializeApp()
            // If already signed in, skip onboarding
            if appState.isAuthenticated {
                hasSeenOnboarding = true
            }
        }
        .alert("Heads Up", isPresented: errorAlertIsPresented) {
            Button("OK", role: .cancel) {
                appState.errorMessage = nil
            }
        } message: {
            Text(appState.errorMessage ?? "Something unexpected happened. Try again.")
        }
    }

    private var authenticatedTabs: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: 0) {
                HomeView()
            }
            Tab("Schedule", systemImage: "calendar", value: 1) {
                ScheduleView()
            }
            Tab("Rankings", systemImage: "trophy.fill", value: 2) {
                RankingsView()
            }
            Tab("Activity", systemImage: "figure.run", value: 3) {
                ActivityFeedView()
            }
            Tab("Profile", systemImage: "person.fill", value: 4) {
                ProfileView()
            }
        }
        .tint(Theme.orange)
    }

    private var launchView: some View {
        ZStack {
            Theme.surface.ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Theme.orange.opacity(0.12))
                        .frame(width: 88, height: 88)
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Theme.orange)
                }

                VStack(spacing: 6) {
                    Text("LocalCheck")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Loading your court…")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }

                ProgressView()
                    .tint(Theme.orange)
                    .scaleEffect(1.1)
            }
        }
    }

    private var errorAlertIsPresented: Binding<Bool> {
        Binding(
            get: { appState.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    appState.errorMessage = nil
                }
            }
        )
    }
}
