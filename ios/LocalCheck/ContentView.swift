import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: Int = 0

    var body: some View {
        Group {
            if appState.isInitializingApp {
                launchView
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
        }
        .alert("Something went wrong", isPresented: errorAlertIsPresented) {
            Button("OK", role: .cancel) {
                appState.errorMessage = nil
            }
        } message: {
            Text(appState.errorMessage ?? "Unknown error")
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
            LinearGradient(
                colors: [Theme.surface, Theme.surfaceElevated, Theme.orangeDark.opacity(0.65)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(Theme.orange.opacity(0.18))
                        .frame(width: 92, height: 92)
                    Image(systemName: "basketball.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(Theme.orange)
                }

                VStack(spacing: 6) {
                    Text("LocalCheck")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Loading your court.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }

                ProgressView()
                    .tint(Theme.orange)
                    .scaleEffect(1.15)
            }
            .padding(32)
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
