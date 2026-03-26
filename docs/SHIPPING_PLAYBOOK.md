# Shipping Playbook

> A repeatable process for shipping features with Claude Code. Designed for a product-minded founder who wants to focus on what to build, not how to build it.

## Your Role vs Claude's Role

**You decide:**
- What feature to build next
- What the UX should feel like
- When something looks right
- When to ship

**Claude handles:**
- Reading and understanding the codebase
- Writing the Swift code
- Fixing build errors
- Following patterns already in the codebase
- Running builds and tests

## The Process

### 1. Describe What You Want (plain English)

Just tell Claude what you want. Be specific about the user experience, not the code.

**Good:** "When a user opens the app for the first time and there are no courts near them, show a friendly empty state with a big 'Add Your Court' button instead of a blank map"

**Also good:** "The rankings screen should actually filter by week/month when I tap those buttons"

**Too vague:** "Fix the rankings" (fix what about them?)

### 2. Claude Plans, You Approve

Claude will describe what it's going to do before doing it. Read the plan — it takes 30 seconds and prevents wasted work.

If something sounds wrong, say so. "No, don't create a new view for that — just add it to the existing HomeView" is exactly the kind of feedback that saves time.

### 3. Claude Implements

Claude writes the code, builds to verify it compiles. You'll see the changes being made in real time.

### 4. You Verify in Simulator

Run the app (`Cmd + R` in Xcode) and check:
- Does it look right?
- Does the flow feel right?
- Does it handle the empty/error/loading states?

If something's off, describe what you see and what you expected. Screenshots help.

### 5. Commit When Happy

Tell Claude to commit. It will write a descriptive commit message and stage only the relevant files.

---

## Slash Commands (Quick Actions)

These are shortcuts you can use in Claude Code:

| Command | What it does |
|---------|-------------|
| `/project:build` | Build the app, fix any errors |
| `/project:run` | Build and launch in simulator |
| `/project:test` | Run all tests |
| `/project:fix-issue` [description] | Debug and fix a specific problem |
| `/project:create-feature` [description] | Plan and build a new feature |

## Daily Workflow

```
Morning:
1. Open Claude Code in the project directory
2. "What's the current state? Any build errors?"
3. Pick the next item from the roadmap (docs/SOURCE_OF_TRUTH.md)
4. Describe what you want built
5. Review plan → approve → verify in simulator → commit

End of session:
1. "Commit everything we did today"
2. "Push to GitHub"
3. Update the roadmap if priorities changed
```

## Feature Shipping Checklist

Before calling a feature "done":

- [ ] It builds without warnings
- [ ] It handles loading states (spinner or skeleton)
- [ ] It handles empty states (no data yet)
- [ ] It handles error states (network failure)
- [ ] Dark theme looks correct
- [ ] Text is readable and not truncated
- [ ] Navigation works (back buttons, tab switches)
- [ ] Data persists after app restart (if it should)

## Tips for Working with Claude

1. **One thing at a time.** "Fix the court selection bug" is better than "fix the court bug and also add push notifications and refactor the auth flow"

2. **Show, don't just tell.** If something looks wrong, say "the text is cut off on the right side" rather than "the layout is broken"

3. **Trust the process.** If Claude suggests reading files first, let it. Context prevents bad code.

4. **Feedback compounds.** If Claude does something you like, say so. If it does something you don't like, say so. It remembers for next time.

5. **Keep commits small.** One feature or fix per commit. Makes it easy to undo if needed.
