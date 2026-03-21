import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
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
        .preferredColorScheme(.dark)
    }
}
