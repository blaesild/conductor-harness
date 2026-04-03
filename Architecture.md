---
tags: [harness-engineering, claude-code, conductor, ai]
created: 2026-03-20
status: active
---

# Harness Architecture

## Component Map

| Component | File | What It Does | Why It Exists |
|-----------|------|-------------|---------------|
| Installer | `runtime/install.sh` | Copies harness into any project's `.claude/` | One command, zero manual config |
| Session hook | `.claude/hooks/session-start.sh` | Injects branch + Linear + memory context at session start | Solves cold-start; Claude knows what it's working on |
| Stop hook | `.claude/hooks/stop.sh` | Runs type checker after each response; exits 2 on error | Deterministic enforcement; Claude sees errors and self-fixes |
| Settings | `.claude/settings.json` | Registers hooks + permission allowlist | Required for Claude Code to run hooks |
| CLAUDE.md import | `.claude/CLAUDE.md.template` | Imports 3 skills; startup/end-of-task rules | Keeps project CLAUDE.md lean; skill content in skill files |
| /start command | `.claude/commands/start.md` | Task kickoff: fetch Linear, search memory, write progress | Explicit ritual; Claude loads full context before acting |
| /done command | `.claude/commands/done.md` | Type check + write memory + update Linear + PR confirm | Explicit ritual; ensures memory is written before closing task |
| /status command | `.claude/commands/status.md` | Show branch, Linear issue, progress, recent commits | Quick orientation check mid-task |
| Linear skill | `.claude/skills/linear/SKILL.md` | How to use Linear MCP tool | Loaded by @import; available to all commands |
| Memory skill | `.claude/skills/memory/SKILL.md` | How to use native memory system | Loaded by @import; available to all commands |
| Review skill | `.claude/skills/review/SKILL.md` | Pre-PR checklist | Loaded by @import; run before every PR |
| Progress file | `.harness/progress.md` | Persists task state between Claude responses | Survives session restarts; hooks read it |
| Conductor config | `conductor.json` | Setup + run scripts for Conductor workspace | Wires package install, .env symlink, Railway link |

## Hook Flow

```
Claude Code opens project
        │
        ▼
[SessionStart hook fires]
  session-start.sh (Python 3)
  ├── git branch --show-current → extract Linear ID (regex: [A-Z]+-\d+)
  ├── git log --oneline -8
  ├── read .harness/progress.md (if exists)
  └── → stdout: JSON {promptText: "## Harness: Session Context\n..."}
        │
        ▼  (Claude receives promptText before user's first message)
        │
  [User sends message / Claude responds]
        │
        ▼
[Stop hook fires after each response]
  stop.sh (Python 3)
  ├── detect tsconfig.json → run tsc --noEmit
  ├── errors? → stderr + exit 2 (BLOCK — Claude sees errors and fixes)
  └── no errors? → exit 0 (pass through)
        │
        ▼
  [Repeat: user message → Claude response → Stop hook]
        │
        ▼
  User runs /done
        │
        ▼
[/done command]
  ├── run type checker + tests
  ├── write native memory file (memory skill)
  ├── update .harness/progress.md (status: done)
  ├── update Linear issue → "In Review" + comment
  └── confirm: "Ready for PR. Run ⌘⇧P in Conductor."
```

## Settings.json Merge Strategy

`install.sh` merges rather than overwrites `.claude/settings.json`:

1. If `.claude/settings.json` does not exist → write template directly
2. If it exists → load as JSON, extend the `hooks` arrays, merge `permissions.allow` and `permissions.deny` arrays (deduplicated), write back

The merge uses Python's `json` module (no external deps). Existing hooks are preserved; harness hooks are appended. This means the harness can be installed on top of a project that already has hooks without losing them.

## Portability Model

The harness is project-local but memory is shared across sessions of the same project:

```
Project A (nerdic-next)
  .claude/hooks/session-start.sh
  .claude/hooks/stop.sh
  .harness/progress.md            → local task state
  ~/.claude/projects/.../memory/  → native memory (per project path)

Project B (monomos)
  .claude/hooks/session-start.sh
  ...
  ~/.claude/projects/.../memory/  → separate namespace (different path)
```

No cross-project memory bleed. Isolation via filesystem path (each project gets its own `~/.claude/projects/` subdirectory).

## Why 3 Skills, Not More

Skills are loaded via `@import` in CLAUDE.md — they consume context on every session. The tradeoff:

- **More skills** = more context used = higher cost, slower responses, increased noise
- **Fewer skills** = less context = Claude doesn't know what tools to use

3 skills covers the full task lifecycle (linear → memory → review) without bloat. Additional capabilities (database, deployment, etc.) should be added as project-specific extensions, not as harness core.

Progressive disclosure: skills describe the MCP tools and when to use them. Claude reads them once at session start and applies them throughout. No need to repeat instructions mid-session.

## Memory Backend

Default: **Claude Code native memory** — zero config, zero cost. Memories stored as markdown files in `~/.claude/projects/[project-path]/memory/` with MEMORY.md index auto-loaded into every session.

Optional: **Hindsight cloud** (opt-in during install) — adds semantic search via MCP. See `Memory Strategy.md` for historical context on cloud memory decisions.

## Conductor Integration

`conductor.json` is installed by `install.sh` (if not already present). It wires:

1. **Setup script** — runs once when Conductor creates the workspace:
   - Symlinks `.env` from `$CONDUCTOR_ROOT_PATH`
   - Runs package install
   - Attempts `generate:types` (no-op if script doesn't exist)
   - Links Railway project (if applicable — skipped if user opts out during install)

2. **Run script** — starts the dev server via detected package manager

The `SessionStart` hook fires when Claude Code opens within the Conductor workspace, layering context on top of what Conductor already provides.
