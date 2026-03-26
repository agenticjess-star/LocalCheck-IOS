---
name: ship-feature
description: End-to-end feature implementation for LocalCheck iOS. Triggers when user describes a new feature, screen, or user-facing change to build.
---

# Ship Feature Workflow

When a user describes a feature to build, follow this pipeline:

## Phase 1: Understand
1. Read `docs/SOURCE_OF_TRUTH.md` to understand current product state
2. Read relevant existing source files to understand current patterns
3. If the feature is ambiguous, ask clarifying questions before proceeding
4. DO NOT start coding until you understand exactly what's being asked

## Phase 2: Plan
1. List every file that will be created or modified
2. Describe the approach in 3-5 bullet points
3. Identify any Supabase schema changes needed
4. Present the plan and wait for approval

## Phase 3: Implement
1. **Models first** — add/modify data types in `Models/`
2. **Services second** — add Supabase queries in `SupabaseService.swift`
3. **State third** — wire into `AppState.swift`
4. **Views last** — build the UI in `Views/`
5. Follow patterns from `references/implementation-checklist.md`

## Phase 4: Verify
1. Build the project: `xcodebuild -project ios/LocalCheck.xcodeproj -scheme LocalCheck -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -20`
2. Fix any build errors
3. Report what was built and any decisions made

## Rules
- Follow existing code patterns — check AppState for examples
- Use Theme colors for all UI
- All views need: loading state, empty state, error state
- Keep AppState as the single source of truth
- No new dependencies without explicit approval
