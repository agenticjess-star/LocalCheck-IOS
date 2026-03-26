# Agent Framework — Reusable Template

> How the `.claude/` directory is structured for any iOS project, and how to replicate it.

## Directory Structure

```
your-project/
├── CLAUDE.md                          # Project brain — tech stack, structure, rules, gotchas
├── .claude/
│   ├── settings.json                  # Permissions (committed, shared with team)
│   ├── settings.local.json            # Personal overrides (gitignored)
│   ├── commands/                      # Slash commands → /project:command-name
│   │   ├── build.md                   # /project:build
│   │   ├── run.md                     # /project:run
│   │   ├── test.md                    # /project:test
│   │   ├── fix-issue.md              # /project:fix-issue [desc]
│   │   └── create-feature.md         # /project:create-feature [desc]
│   ├── rules/                         # Auto-loaded context rules (path-scoped)
│   │   ├── swift-conventions.md       # Swift/SwiftUI patterns
│   │   ├── supabase-patterns.md       # Backend integration patterns
│   │   └── safety.md                  # Never-edit files, secret handling
│   ├── skills/                        # Auto-triggered workflows
│   │   └── ship-feature/
│   │       └── SKILL.md
│   └── agents/                        # Specialized subagent definitions
│       └── code-reviewer.md
├── docs/
│   ├── SOURCE_OF_TRUTH.md             # Product state, roadmap, schema, links
│   ├── XCODE_GUIDE.md                 # How to build/run/preview (for humans)
│   ├── SHIPPING_PLAYBOOK.md           # The repeatable process
│   └── AGENT_FRAMEWORK.md            # This file — the template reference
└── .gitignore                         # Must include safety exclusions
```

## What Each File Does

### CLAUDE.md (The Brain)
- Loaded automatically every conversation
- Contains: stack, structure, build commands, architecture rules, known issues, safety rules
- Keep under 200 lines — link to docs/ for details
- Update when: architecture changes, new gotchas discovered, conventions established

### settings.json (Permissions)
- Controls what Claude can do without asking
- `allow`: safe commands (build, test, git read operations, file tools)
- `deny`: dangerous commands (rm -rf, force push, curl)
- Everything else: Claude asks before running

### commands/ (Your Shortcuts)
- Each `.md` file becomes `/project:filename`
- Use `$ARGUMENTS` for parameterized commands
- Keep them focused — one action per command
- These are explicit (you invoke them) vs. skills (auto-triggered)

### rules/ (Auto-Loaded Context)
- Loaded automatically when Claude works on matching files
- Use YAML frontmatter `paths:` to scope (e.g., only load Swift rules for .swift files)
- Rules without paths load for every conversation
- Use for: coding conventions, integration patterns, safety guardrails

### skills/ (Auto-Triggered Workflows)
- Each skill is a folder with a `SKILL.md`
- Triggered automatically when the conversation matches the skill's description
- Can include reference files, templates, scripts in the skill folder
- Use for: complex multi-step workflows that should be consistent every time

### docs/ (Human-Readable Reference)
- Not loaded by Claude automatically — Claude reads these when needed
- SOURCE_OF_TRUTH.md: the canonical state of the product
- Keep updated as the product evolves

## Adapting for a New Project

1. Copy this structure to your new project
2. Update CLAUDE.md with the new project's tech stack, structure, and rules
3. Update build/run/test commands for the new project's toolchain
4. Update rules/ for the new project's conventions
5. Create a new SOURCE_OF_TRUTH.md with the product context
6. Update .gitignore for the project's needs

## Recommended Enhancements

### XcodeBuildMCP
MCP server that provides Xcode build/test/run tools. Install for a smoother build experience.
Source: github.com/nicklama/xcode-mcp-server (or similar)

### iOS Simulator Skill
Community skill with 21 Python scripts for simulator interaction. Good for automated UI verification.
Source: github.com/conorluddy/ios-simulator-skill

### Hooks (Advanced)
Add to settings.json when ready:
- **PreToolUse hook** on Edit: block edits to .pbxproj
- **PostToolUse hook** on Edit for .swift files: auto-format
- **Notification hook**: desktop notification when Claude needs input

## Design Patterns for Skills (from research)

1. **Tool Wrapper** — Load library docs on demand from `references/`
2. **Generator** — Enforce consistent output with templates in `assets/`
3. **Reviewer** — Score against a checklist in `references/review-checklist.md`
4. **Inversion** — Interview the user before acting (requirements gathering)
5. **Pipeline** — Sequential steps with hard checkpoints and user approval gates

Choose the pattern that fits the skill's purpose. Most skills are Tool Wrappers or Generators.
