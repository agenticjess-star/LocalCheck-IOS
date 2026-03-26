Plan and implement a new feature for LocalCheck. $ARGUMENTS

Workflow:
1. **Clarify**: Ask me any questions before starting if the feature is ambiguous
2. **Plan**: List the files you'll create or modify, and the approach
3. **Implement**: Build it incrementally — models first, then services, then views
4. **Wire up**: Connect to AppState and navigation
5. **Build**: Verify it compiles
6. **Report**: Summary of what was built, any decisions made, and next steps

Rules:
- Follow existing patterns (check AppState for examples)
- New views go in Views/, new models in Models/
- All Supabase calls go through SupabaseService
- Use the existing Theme colors and styling
- Keep the dark theme aesthetic
