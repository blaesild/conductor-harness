# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

`conductor-harness` is an npm package (`npx conductor-harness`) that installs a portable Claude Code harness into any git repo. It adds session hooks, slash commands, memory integration, Linear workflow, and project context injection. Published via `package.json` with a `bin` entry pointing to `bin/conductor-harness.js`, which shells out to `runtime/install.sh`.

## Architecture

**Installer flow** (`runtime/install.sh`): Detects package manager from lockfile, prompts for Railway, then copies the entire `runtime/.claude/` tree into the target project's `.claude/`. Merges (never overwrites) `settings.local.json` using Python's `json` module. Auto-generates `CLAUDE.md` in the target project by detecting framework/database/deployment from `package.json` and file markers.

**Runtime files** (what gets installed into target projects):

| Path | Role |
|------|------|
| `hooks/session-start.sh` | Python 3 script. Reads git branch, extracts Linear ID via regex, loads `.harness/progress.md`, outputs JSON `{promptText: "..."}` to stdout |
| `hooks/stop.sh` | Python 3 script. Runs `tsc --noEmit` if tsconfig exists. Exit 2 on errors (blocks Claude). |
| `commands/{start,done,status,setup}.md` | Slash command prompts for task lifecycle |
| `skills/{linear,memory,review}/SKILL.md` | Loaded via `@import` in CLAUDE.md.template — describe when/how to use each tool (memory uses native Claude Code memory by default, Hindsight optional) |
| `agents/` | Directory for project-specific subagents (empty by default) |
| `CLAUDE.md.template` | Template with `[placeholders]` substituted by install.sh's Python |
| `settings.json.template` | Hook registration + permission allowlist, `<PKG_MANAGER>` substituted at install |

**Key design decisions:**
- Hooks (not CLAUDE.md instructions) enforce must-happen logic — hooks are 100% deterministic vs ~70% CLAUDE.md compliance
- Only 3 skills to minimize context cost (linear, memory, review cover full task lifecycle)
- `.harness/` is gitignored local state; memory is cloud-based per-project (group_id from git remote)
- Settings merge strategy: append harness hooks/permissions to existing, deduplicated, never destructive

## Development

No build step. No tests. The package is a thin Node wrapper (`bin/conductor-harness.js`) around a bash installer (`runtime/install.sh`) that uses inline Python 3 for JSON manipulation and project detection.

To test changes locally:
```bash
cd /path/to/test-project
bash /path/to/Harness/runtime/install.sh
```

To publish:
```bash
npm version patch && npm publish
```

## Template Placeholders

`CLAUDE.md.template` uses: `[project-name]`, `[framework]`, `[database]`, `[deployment]`, `[pkg-manager]`, `[mcp-servers-table]`, `[key-docs]`

`settings.json.template` uses: `<PKG_MANAGER>`

Both are substituted by Python blocks in `install.sh` — keep placeholder formats consistent when editing templates.

## Hook Contract

- **SessionStart**: Receives JSON event on stdin with `cwd`. Must output `{"promptText": "..."}` to stdout.
- **Stop**: Receives JSON event on stdin with `cwd`. Exit 0 = pass, exit 2 = block (stderr shown to Claude for self-fix).
