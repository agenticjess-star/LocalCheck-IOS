Build the LocalCheck iOS app for the simulator.

Run: `xcodebuild -project ios/LocalCheck.xcodeproj -scheme LocalCheck -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -20`

If the build fails:
1. Read the error output carefully
2. Fix the issue in the source code
3. Rebuild and verify it passes
4. Report what was wrong and what you fixed
