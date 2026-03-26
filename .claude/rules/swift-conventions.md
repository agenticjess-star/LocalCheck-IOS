---
paths: ["ios/**/*.swift"]
---

# Swift Conventions for LocalCheck

- Use `@Observable` class pattern (not `ObservableObject` / `@Published`)
- All model structs: `nonisolated struct` with `Codable, Identifiable, Sendable`
- CodingKeys: use `convertFromSnakeCase` strategy or explicit keys matching Supabase column names
- Dates: always use the shared `SupabaseService.jsonDecoder` which handles 4 ISO formats
- Errors: print to console + show `.alert()` — no silent failures
- Async/await everywhere — no Combine, no completion handlers
- Keep view bodies under ~80 lines — extract subviews as private computed properties or separate structs
- Use `Theme.` constants for all colors
