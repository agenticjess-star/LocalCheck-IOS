---
paths: ["ios/LocalCheck/Services/Supabase*.swift", "ios/LocalCheck/Models/*.swift"]
---

# Supabase Integration Patterns

## REST API Pattern
All Supabase calls use URLSession with PostgREST query parameters:
- Select: `?select=col1,col2&column=eq.value`
- Insert: POST with JSON body, `Prefer: return=representation`
- Update: PATCH with `?id=eq.value`
- Upsert: POST with `Prefer: resolution=merge-duplicates`
- Delete: DELETE with `?id=eq.value`

## Headers (every request)
- `apikey`: anon key
- `Authorization`: `Bearer {access_token}`
- `Content-Type`: `application/json`

## Adding a New Table/Query
1. Add the Row struct in SupabaseService (e.g., `MyTableRow: Codable`)
2. Add the fetch/create/update/delete method on the SupabaseService actor
3. Add the domain model in Models/ if the row struct isn't sufficient
4. Wire into AppState with a loading method
5. Test with a print statement before building UI

## Common Gotchas
- Views (like `courts_with_stats`) may have different column sets than base tables
- RLS means queries silently return empty if the user isn't authorized
- `conflict` parameter on upsert must match a unique constraint
- Date columns from Supabase can arrive in multiple ISO 8601 formats
