import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var showCheckIn: Bool = false
    @State private var showPostToFeed: Bool = false
    @State private var showMap: Bool = false
    @State private var appeared: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if appState.isLoadingHome && appState.localCourt == nil {
                        ProgressView("Loading your court…")
                            .padding(.top, 100)
                    } else {
                        courtHeader
                        presenceSection
                        feedSection
                    }
                }
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .background(Theme.surface)
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Map", systemImage: "map.fill") { showMap = true }
                        .tint(Theme.orange)
                }
            }
            .sheet(isPresented: $showCheckIn) {
                CheckInSheet(
                    isCheckedIn: appState.isCheckedIn,
                    onCheckIn: { note in
                        guard let courtID = appState.localCourt?.id else { return }
                        Task { await appState.performCheckIn(courtID: courtID, note: note) }
                    },
                    onCheckOut: {
                        Task { await appState.performCheckOut() }
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.surfaceElevated)
            }
            .sheet(isPresented: $showPostToFeed) {
                PostToCourtSheet { content in
                    guard let courtID = appState.localCourt?.id else { return }
                    Task { await appState.postToFeed(courtID: courtID, content: content, type: .note) }
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.surfaceElevated)
            }
            .fullScreenCover(isPresented: $showMap) {
                CourtMapView()
            }
            .task {
                await appState.loadHome()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                    appeared = true
                }
            }
        }
    }

    // MARK: - Court header

    private var courtHeader: some View {
        VStack(spacing: 14) {
            if let court = appState.localCourt {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: court.sportType.icon)
                            .font(.title3)
                            .foregroundStyle(Theme.orange)
                        Text(court.name)
                            .font(.title3.bold())
                            .foregroundStyle(Theme.textPrimary)
                    }
                    Text(court.address)
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                // Check-in button
                Button {
                    showCheckIn = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: appState.isCheckedIn ? "checkmark.circle.fill" : "mappin.and.ellipse")
                        Text(appState.isCheckedIn ? "Checked In" : "Check In")
                            .font(.body.weight(.semibold))
                    }
                    .foregroundStyle(appState.isCheckedIn ? Theme.green : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: Theme.buttonHeight)
                    .background(
                        appState.isCheckedIn ? Theme.green.opacity(0.15) : Theme.orange,
                        in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    )
                }
                .sensoryFeedback(.impact(weight: .medium), trigger: appState.isCheckedIn)
            } else {
                VStack(spacing: 14) {
                    Image(systemName: "mappin.slash")
                        .font(.system(size: 36))
                        .foregroundStyle(Theme.textTertiary)
                    Text("No local court set")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                    Text("Pick a court from the map to see activity here.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textTertiary)
                        .multilineTextAlignment(.center)
                    Button {
                        showMap = true
                    } label: {
                        Text("Choose Your Court")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: Theme.buttonHeight)
                            .background(Theme.orange, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(28)
                .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, 12)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.5).delay(0.05), value: appeared)
    }

    // MARK: - Presence

    private var presenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Live at Court")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(appState.activeCheckIns.count) here now")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.orange)
            }

            if appState.activeCheckIns.isEmpty {
                Text("No one is checked in right now.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(appState.activeCheckIns) { checkIn in
                            VStack(spacing: 4) {
                                AvatarView(name: checkIn.playerName, size: 44)
                                Text(checkIn.playerName.split(separator: " ").first.map(String.init) ?? "")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, 28)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.5).delay(0.15), value: appeared)
    }

    // MARK: - Feed

    private var feedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Court Feed")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button("Post", systemImage: "square.and.pencil") { showPostToFeed = true }
                    .tint(Theme.orange)
            }

            if appState.courtFeed.isEmpty {
                Text("No posts yet. Be the first to post!")
                    .font(.footnote)
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.vertical, 8)
            } else {
                ForEach(appState.courtFeed) { post in
                    FeedPostRow(post: post)
                }
            }
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.top, 28)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.5).delay(0.25), value: appeared)
    }
}
