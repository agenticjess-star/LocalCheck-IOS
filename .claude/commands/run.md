Build and run LocalCheck in the iOS Simulator.

Steps:
1. Build: `xcodebuild -project ios/LocalCheck.xcodeproj -scheme LocalCheck -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build`
2. Boot simulator if needed: `xcrun simctl boot "iPhone 16 Pro" 2>/dev/null; open -a Simulator`
3. Install: `xcrun simctl install booted $(xcodebuild -project ios/LocalCheck.xcodeproj -scheme LocalCheck -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -showBuildSettings 2>/dev/null | grep -m1 BUILT_PRODUCTS_DIR | awk '{print $3}')/LocalCheck.app`
4. Launch: `xcrun simctl launch booted com.realjess.localcheck`

Report the result of each step.
