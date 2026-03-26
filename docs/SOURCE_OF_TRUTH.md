# LocalCheck iOS — Source of Truth

> Last updated: 2026-03-26

## What is LocalCheck?

A community-driven pickup sports app. Players find courts, check in to show they're there, track ELO rankings, schedule runs, and build a local court community. Started as basketball + pickleball, expandable to any court sport.

**Tagline:** "The best pickup game is the one that actually happens."

## Key Links

| Resource | Link |
|----------|------|
| iOS Repo | https://github.com/agenticjess-star/LocalCheck-IOS |
| Webapp Repo | https://github.com/agenticjess-star/localcheck |
| Webapp Live | localcheck.lovable.app |
| Supabase Dashboard | https://supabase.com/dashboard/project/jzclwnzcektqhgkkdeje |
| Bundle ID | `com.realjess.localcheck` |
| Apple Dev Team | `WAX386UG9W` |
| Notion Source of Truth | https://www.notion.so/32b6091ba7b1814788c1e54dc6686530 |

## Current State (2026-03-26)

### What Works
- App builds and runs in simulator
- Email auth (sign up + sign in) works
- Tab navigation renders (Home, Schedule, Rankings, Activity, Profile)
- Dark theme with orange accent renders correctly
- Supabase REST integration is wired up

### What's Broken / Incomplete
1. **Court onboarding blocks users** — no skip button, no error recovery, empty map if no courts nearby
2. **No court data seeded** — new users see nothing on the map
3. **Rankings filter is decorative** — Week/Month buttons don't change the query
4. **Notification toggles are UI-only** — not connected to push
5. **Apple Sign-In is stubbed** — needs entitlements + paid dev account
6. **Supabase key is hardcoded** — should be in xcconfig
7. **No app icon**
8. **No tests**
9. **PDF/RTF files committed to repo** — should be removed

### Git State
- **Branch:** `main` (4 commits, latest: `f6caf40`)
- **Other branches:** `codex/review-app-auth-status` (same commit)
- All branches are at the same commit — no divergent work

## Database Schema

### Core Tables
| Table | Purpose | Key Columns |
|-------|---------|-------------|
| profiles | User accounts | id, display_name, username, elo_rating, wins, losses, local_court_id |
| courts | Court locations | id, name, address, latitude, longitude, sport_type, added_by |
| check_ins | Court presence | id, user_id, court_id, checked_in_at, checked_out_at |
| feed_posts | Court feed | id, author_id, court_id, content, post_type |
| games | Match results | id, court_id, winning_team, team_a_score, team_b_score |
| game_participants | Who played | id, game_id, user_id, team_side |
| scheduled_games | Upcoming games | id, court_id, organizer_id, scheduled_for, max_players |
| scheduled_game_participants | RSVPs | id, scheduled_game_id, user_id |

### Views
| View | Purpose |
|------|---------|
| courts_with_stats | Courts + local_player_count, is_confirmed, is_archived |
| active_check_ins | Currently checked-in users |
| feed_posts_with_counts | Posts + author info + like counts |
| games_with_counts | Games + court name + like/comment counts |

### Social Tables
game_likes, game_comments, feed_post_likes, friendships

### Monetization Tables
subscriptions, subscription_events

## App Flow

```
Launch
  → Splash (gradient + spinner)
  → Auth check
    → NOT authenticated → AuthView (email sign in/up)
    → Authenticated, NO court → CourtMapView (onboarding mode, must pick court)
    → Authenticated + court → Main Tabs
      Tab 1: Home (court header, live check-ins, feed)
      Tab 2: Schedule (date strip, upcoming games, RSVP)
      Tab 3: Rankings (ELO leaderboard)
      Tab 4: Activity (game history feed)
      Tab 5: Profile (stats, opponents, settings)
```

## Feature Parity: Webapp vs iOS

| Feature | Webapp | iOS |
|---------|--------|-----|
| Email auth | Done | Done |
| Apple Sign-In | No | Scaffolded |
| Real-time check-ins | Done (live) | View exists |
| Court map | Done (Mapbox) | Done (MapKit) |
| Add courts | Done | Done |
| ELO rankings | Done (with disputes) | View exists |
| Schedule | Done (cal views) | View exists |
| Event runs | Done (RSVP, teams) | Not started |
| Notifications | Done (real-time) | Not started |
| Activity feed | No | Done |
| Profile | Done | Done |
| Landing page | Done | N/A |

## Roadmap to App Store

### Phase 1: Fix Core Loop (Current)
- [ ] Fix court onboarding (skip button, error recovery, location-based default)
- [ ] Seed real court data (or improve "Add Court" UX)
- [ ] Verify all Supabase queries work end-to-end
- [ ] Move anon key to xcconfig

### Phase 2: Polish MVP
- [ ] App icon and launch screen
- [ ] Make rankings filter functional
- [ ] Remove dead code (SampleData.swift)
- [ ] Remove PDF/RTF from repo
- [ ] Basic error states for all views
- [ ] Loading states for all data fetches

### Phase 3: Apple Sign-In + Push
- [ ] Add entitlements
- [ ] Implement Apple Sign-In flow
- [ ] Set up push notifications via Supabase
- [ ] Wire notification toggles to real preferences

### Phase 4: App Store Submission
- [ ] App Store screenshots
- [ ] App Store description and metadata
- [ ] Privacy policy URL
- [ ] TestFlight beta testing
- [ ] Submit for review
