Run all tests for LocalCheck.

```bash
xcodebuild -project ios/LocalCheck.xcodeproj -scheme LocalCheck -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test 2>&1 | tail -30
```

Report: total tests, passed, failed, and any failure details.
