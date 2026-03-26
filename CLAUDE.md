# LocalCheck iOS

Community pickup sports app. Find courts, check in, see who's playing, track rankings, schedule runs.

## Tech Stack
- **Language:** Swift 6 (strict concurrency), SwiftUI, iOS 18+
- **Backend:** Supabase (REST via URLSession — no Supabase Swift SDK)
- **Auth:** Email/password + Apple Sign-In (scaffolded)
- **State:** `@Observable` AppState, injected via `.environment()`
- **Maps:** MapKit
- **Storage:** Keychain via SecureStore
- **Dependencies:** Zero third-party packages

## Project Structure
```
ios/
  LocalCheck.xcodeproj/
  LocalCheck/
    LocalCheckApp.swift          # @main entry
    ContentView.swift            # Root router: splash → auth → court onboarding → tabs
    Models/                      # Codable data types
    Services/
      AppState.swift             # Central state + all business logic
      SupabaseService.swift      # REST client (CRUD)
      SupabaseAuthService.swift  # Auth REST client
      SecureStore.swift          # Keychain wrapper
    Views/                       # All SwiftUI views
    Utilities/                   # Theme, AvatarView, AuthNonce
```

## Build & Run
```bash
xcodebuild -project ios/LocalCheck.xcodeproj -scheme LocalCheck -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
xcodebuild -project ios/LocalCheck.xcodeproj -scheme LocalCheck -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
```

## Supabase
- **Project:** `jzclwnzcektqhgkkdeje`
- **Tables:** profiles, courts, check_ins, feed_posts, games, game_participants, scheduled_games, scheduled_game_participants
- **Views:** courts_with_stats, active_check_ins, feed_posts_with_counts, games_with_counts
- All queries use REST API with `apikey` and `Authorization` headers
- RLS is enabled on all tables

## Architecture Rules
- AppState is the single source of truth — views read from it, call methods on it
- All Supabase calls go through SupabaseService/SupabaseAuthService actors
- Models use `nonisolated` to opt out of MainActor default isolation
- Date decoding handles 4 ISO 8601 format variants
- Court onboarding is gated: user MUST select a court before accessing main tabs

## Known Issues (as of 2026-03-26)
- Supabase anon key is hardcoded in SupabaseService.swift (should move to xcconfig)
- Entitlements file is empty (needs Apple Sign-In, push entitlements before those features work)
- Rankings filter (Week/Month/All) is UI-only — query always returns all-time
- Notification toggles in Settings are UI-only — not connected to push system
- Court onboarding has no skip/escape — if network fails, user is stuck
- SampleData.swift is dead code

## Safety
- NEVER edit `project.pbxproj` directly — file sync is automatic in Xcode 16+
- NEVER hardcode secrets — use xcconfig or environment injection
- NEVER commit .env, Config.swift, or credentials
- PDF/RTF files at repo root contain Supabase details — should be removed from git

## Conventions
- Use `@Observable` (not `ObservableObject`)
- Prefer `NavigationStack` with type-safe destinations
- Keep views thin — logic belongs in AppState
- Private extensions stay in the file that uses them
- Error handling: show `.alert()` to user, print to console for debugging
