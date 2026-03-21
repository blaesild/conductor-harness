# conductor-harness

A Claude Code harness for [Conductor](https://conductor.so) projects. Installs session hooks, memory integration, Linear workflow, and project context injection into any git repo in under a minute.

---

## What it does

- **SessionStart hook** — injects branch, recent commits, last session progress, and `WORKFLOW.md` context before every Claude Code session
- **Linear integration** — reads attached issues directly from Conductor's `+` button; falls back to Linear MCP for comments and history
- **Graphiti memory** — searches past decisions before starting work; writes episodes after `/done`
- **Context7 docs** — fetches up-to-date framework and package documentation before planning or implementing
- **`/start`, `/done`, `/status`** — task kickoff and closeout rituals that keep progress state and memory in sync
- **`/setup`** — analyzes your project and auto-generates `WORKFLOW.md`
- **`WORKFLOW.md`** — a project north star (what you're building, current phase, constraints) injected into every session

---

## Requirements

- [Claude Code](https://claude.ai/code)
- [Conductor](https://conductor.so)
- Node.js 18+
- A git repository

**Recommended MCP servers** (register once per machine):

```bash
# Graphiti memory (Zep Cloud)
claude mcp add graphiti-memory \
  --transport sse \
  --url https://mcp.getzep.com/sse \
  --header "Authorization: Api-Key $ZEP_API_KEY"

# Linear
claude mcp add linear -s user -- npx -y @linear/mcp-server

# Context7 (up-to-date docs)
claude mcp add context7 -s user -- npx -y @upstash/context7-mcp
```

---

## Install

Run from your project root:

```bash
npx conductor-harness
```

The installer will:

1. Detect your package manager (pnpm / yarn / bun / npm)
2. Ask if the project uses Railway
3. Copy hooks, commands, skills, and agents into `.claude/`
4. Merge harness hooks and permissions into `.claude/settings.local.json`
5. Write `CLAUDE.md` with orchestration principles and harness configuration
6. Write `conductor.json` with setup, run, and archive commands
7. Create `WORKFLOW.md` for project context
8. Create `.harness/progress.md` for session state

Re-running is safe — `settings.local.json` is always merged, never overwritten.

---

## Railway projects

If your project uses Railway, add these to your `.env`:

```env
RAILWAY_PROJECT_ID=your-project-id
RAILWAY_ENVIRONMENT_ID=your-environment-id
RAILWAY_SERVICE_ID=your-service-id
```

The generated `conductor.json` setup command will pick them up automatically via `source .env`.

---

## After install

**Fill in `WORKFLOW.md`** — or let Claude generate it:

```
/setup
```

**Start a task:**

```
/start LIN-123
```

Or attach a Linear issue via Conductor's `+` button and type `/start` — the harness reads it directly without an MCP fetch.

**End a task:**

```
/done
```

Closes the Linear issue, writes a Graphiti memory episode, and resets progress state.

---

## Project structure

```
runtime/
  .claude/
    CLAUDE.md.template      ← Orchestration principles + harness config
    hooks/
      session-start.sh      ← Injects context before every session
      stop.sh               ← Saves progress on session end
    commands/
      start.md              ← Task kickoff ritual
      done.md               ← Task closeout ritual
      status.md             ← Current task status
      setup.md              ← Project analysis + WORKFLOW.md generation
    skills/
      linear/SKILL.md       ← Linear issue read/write
      memory/SKILL.md       ← Graphiti memory search/write
      review/SKILL.md       ← Code review checklist
    agents/
      memory-writer.md      ← Subagent for writing memory episodes
    settings.json.template  ← Base permissions and hook registration
  WORKFLOW.md.template      ← Project north star template
  conductor.json.template   ← Conductor setup/run/archive commands
  install.sh                ← The installer (called by npx)
```

---

## License

MIT
