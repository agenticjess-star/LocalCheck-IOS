# Safety Rules

## Files You Must NEVER Edit
- `ios/LocalCheck.xcodeproj/project.pbxproj` — Xcode manages this automatically
- Any `.env` or `Config.swift` file — contains secrets
- `ios/LocalCheck.xcodeproj/project.xcworkspace/` — Xcode-managed

## Secrets
- The Supabase anon key in SupabaseService.swift is publishable (like a public API key)
- Never add service_role keys, JWT secrets, or database passwords to source
- If you need to add a new secret, use xcconfig files and document in CLAUDE.md

## Git Safety
- Never force push
- Never amend commits that have been pushed
- Always commit with descriptive messages
- Check `git status` before committing to avoid staging unwanted files

## Build Safety
- Always build after making changes to verify compilation
- If you break the build, fix it before moving on
- Don't delete files without checking they're truly unused
