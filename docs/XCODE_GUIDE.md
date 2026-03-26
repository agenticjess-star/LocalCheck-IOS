# Xcode Guide for LocalCheck

> For developers new to Xcode — answers the "how do I actually build and run this?" questions.

## Opening the Project

1. Open Xcode
2. File → Open → navigate to `ios/LocalCheck.xcodeproj`
3. Xcode will index the project (may take a minute first time)

## Building

**In Xcode:**
- Select a simulator from the device dropdown (top center toolbar) — pick "iPhone 16 Pro"
- Press `Cmd + B` to build (or Product → Build)
- Build status appears in the activity bar at the top

**From command line:**
```bash
xcodebuild -project ios/LocalCheck.xcodeproj -scheme LocalCheck \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

## Running

**In Xcode:**
- Press `Cmd + R` (or the Play button) to build AND run in the simulator
- The simulator app launches automatically
- Console output appears in the bottom panel (View → Debug Area → Activate Console)

**From command line:**
```bash
# Boot simulator
xcrun simctl boot "iPhone 16 Pro"
open -a Simulator

# Build, install, and launch
xcodebuild -project ios/LocalCheck.xcodeproj -scheme LocalCheck \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

## Does it auto-update when I push to Git?

**No.** Git pushes do not trigger builds. You must:
1. Pull changes in Xcode (Source Control → Pull) or `git pull` in terminal
2. Build again (`Cmd + B`)
3. Run again (`Cmd + R`)

This project uses Xcode 16's **file system sync** — when you add/remove Swift files on disk, Xcode picks them up automatically. You do NOT need to manually add files to the project.

## SwiftUI Previews

SwiftUI has a live preview system:
1. Open any View file (e.g., `AuthView.swift`)
2. Press `Cmd + Option + P` to toggle the preview canvas
3. Add a `#Preview` block at the bottom of the file if one doesn't exist:
   ```swift
   #Preview {
       AuthView()
           .environment(AppState())
   }
   ```
4. Previews update live as you edit code

**Note:** Previews may not work for views that depend on real Supabase data. Use `SampleData` for preview environments.

## Common Issues

### "No such module" error
The project has zero dependencies — if you see this, clean the build folder: `Cmd + Shift + K`

### Simulator is slow
Product → Destination → choose a simpler device (iPhone SE)

### Build succeeds but app crashes on launch
Check the console output (bottom panel). Common causes:
- Missing entitlements for features being used
- Keychain access issues in simulator
- Network calls failing (check Supabase URL)

### "Signing requires a development team"
1. Click on the project in the navigator (blue icon, top left)
2. Select the "LocalCheck" target
3. Go to "Signing & Capabilities"
4. Select your Apple developer team (or personal team for free development)

## Testing

**In Xcode:**
- `Cmd + U` runs all tests
- Click the diamond icon next to a test function to run just that test

**From command line:**
```bash
xcodebuild -project ios/LocalCheck.xcodeproj -scheme LocalCheck \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
```

## Key Xcode Shortcuts

| Action | Shortcut |
|--------|----------|
| Build | `Cmd + B` |
| Run | `Cmd + R` |
| Stop | `Cmd + .` |
| Clean | `Cmd + Shift + K` |
| Test | `Cmd + U` |
| Toggle Preview | `Cmd + Option + P` |
| Open Quickly | `Cmd + Shift + O` |
| Show/Hide Navigator | `Cmd + 0` |
| Show/Hide Console | `Cmd + Shift + Y` |
