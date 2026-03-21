---
tags: [harness-engineering, claude-code, conductor, ai]
created: 2026-03-20
status: active
---

# 00 Harness

A portable, self-managing harness for Claude Code + Conductor that works across all projects. Installs in 30 seconds. Solves the "cold start" problem for every new workspace.

## What It Solves

- Every Conductor workspace starts cold — no project context, no memory of past decisions
- No standard startup ritual across projects
- No persistent memory of decisions, gotchas, and patterns across sessions
- Every project needs its own harness; no installable standard existed

## Quick Start — 3 Steps

```bash
# 1. Run the installer from any project root (must be a git repo)
bash /Users/blaesild/Documents/Brain/projects/Harness/runtime/install.sh

# 2. Register the MCPs (one-time per machine, not per project)
export ZEP_API_KEY=your_key_here
claude mcp add graphiti-memory --transport sse --url https://mcp.getzep.com/sse --header "Authorization: Api-Key $ZEP_API_KEY"
claude mcp add linear -s user -- npx -y @linear/mcp-server

# 3. Open the project in Claude Code — hooks fire automatically
```

After install, every Claude Code session in the project will:
- Inject branch/Linear context before your first message
- Run the type checker after each response (blocks if errors)
- Give you `/start`, `/done`, and `/status` commands

## Session Lifecycle

```
Linear issue created
      ↓
Conductor: ⌘⇧N → creates workspace from Linear issue
      ↓
conductor.json setup script (init.sh) runs once:
  - npm install (or equivalent)
  - symlink .env
  - mkdir -p .harness
  - log workspace init
      ↓
Claude Code session starts
      ↓
SessionStart hook fires (session-start.sh):
  - parse Linear issue ID from branch name
  - git log --oneline -10
  - load .harness/progress.md if exists
  - call Graphiti MCP: search_nodes(query=branch/issue context)
  - inject all as structured context block → Claude reads before first user message
      ↓
User runs /start LIN-123 (or Claude auto-starts from injected context)
      ↓
Claude works: reads Linear issue via MCP, implements, commits
      ↓
Stop hook fires after each response (stop.sh):
  - run type checker (non-blocking stderr on failure → exit 2 = Claude fixes)
  - update .harness/progress.md
      ↓
User runs /done
      ↓
/done command:
  - Claude updates Linear issue status via MCP
  - writes final episode to Graphiti
  - confirms ready for PR
      ↓
Conductor: ⌘D review → ⌘⇧P create PR → merge → archive workspace
```

## Files in This Folder

| File | Purpose |
|------|---------|
| `00 Harness.md` | This file — MoC, quick start, lifecycle |
| `Architecture.md` | Component map, hook flow, design decisions |
| `Memory Strategy.md` | Zep Cloud decision, group_id convention, migration path |
| `runtime/install.sh` | The installer — run this in any project root |
| `runtime/.claude/` | All installable Claude Code config files |

## Decision Log

| Decision | Choice | Reason |
|----------|--------|--------|
| Memory backend | Zep Cloud Flex ($25/mo) | Same Graphiti engine as Nerdic-next. Zero infra. HTTP/SSE MCP (safe — avoids hang bug). |
| MCP transport | SSE (not stdio) | Claude Code Issue #15945: stdio can hang indefinitely |
| Number of skills | 3 (linear, memory, review) | Progressive disclosure; context cost; maintenance burden |
| Hook types | 2 (SessionStart, Stop) | SessionStart = context injection. Stop = type check enforcement. |
| CLAUDE.md length | Import-only (harness section < 10 lines) | ETH Zurich study: bloated CLAUDE.md = ignored. Content lives in skill files. |
| Hooks vs CLAUDE.md | Hooks for must-happen logic | Hooks = 100% deterministic. CLAUDE.md = ~70% compliance. |
| Cross-project memory | No (per-project group_id only) | Topic bleed risk too high across unrelated projects |

## Related

- [[Memory/00 Agent Memory for Harness Engineering]]
- [[Conductor/00 Conductor]]
- [[Claude Code/00 Claude Code]]
- `Memory Strategy.md` — full Zep Cloud decision + migration path
- `Architecture.md` — component map and hook flow detail

## Verification

### How to install
```bash
cd /path/to/any-project
bash /Users/blaesild/Documents/Brain/projects/Harness/runtime/install.sh
```

### How to verify hooks loaded
Open Claude Code in the project, type `/hooks` — you should see `session-start.sh` and `stop.sh` listed.

### How to verify memory MCP
Type `/mcp` in a Claude Code session — `graphiti-memory` should appear in the list.

### How to verify SessionStart
Open a new Claude Code session in the project. The first context block should show a `## Harness: Session Context` header with branch name, recent commits, and last session progress.

### How to verify /start
Run `/start LIN-123` — Claude should fetch the Linear issue, search Graphiti memory, show git status, and write `.harness/progress.md`.
