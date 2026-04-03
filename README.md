# conductor-harness

A Claude Code harness for [Conductor](https://conductor.build) projects. Installs session hooks, memory integration, Linear workflow, and project context injection into any git repo in under a minute.

---

## What it does

- **SessionStart hook** — injects branch, recent commits, and last session progress before every Claude Code session
- **Linear integration** — reads attached issues directly from Conductor's `+` button; falls back to Linear MCP for comments and history
- **Native memory** — persists decisions across sessions using Claude Code's built-in memory system; optionally augmented with Hindsight cloud
- **Context7 docs** — fetches up-to-date framework and package documentation before planning or implementing
- **`/start`, `/done`, `/status`** — task kickoff and closeout rituals that keep progress state and memory in sync

---

## Setup

### 1. Install MCP servers (once per machine)

**Linear** — read and update issues from Claude Code:
```bash
claude mcp add linear -s user -- npx -y @linear/mcp-server
```

**Context7** — fetch up-to-date framework and package docs:
```bash
claude mcp add context7 -s user -- npx -y @upstash/context7-mcp
```

### 2. Install the harness into a project

From your project root (must be a git repo):
```bash
npx conductor-harness
```

The installer will ask two questions:
- **Package manager** — auto-detected from your lockfile
- **Railway?** — adds `railway link` to the Conductor setup command

### 3. Configure Railway (if applicable)

Add to your `.env`:
```env
RAILWAY_PROJECT_ID=your-project-id
RAILWAY_ENVIRONMENT_ID=your-environment-id
RAILWAY_SERVICE_ID=your-service-id
```

### 4. Start working

Open the project in Claude Code via Conductor. The SessionStart hook fires automatically and injects your project context.

```
/start LIN-123    ← kick off a task
/done             ← close it out, write memory
/status           ← check current state
```

---

## Requirements

- [Claude Code](https://claude.ai/code)
- [Conductor](https://conductor.build)
- Node.js 18+
- A git repository

Or attach a Linear issue via Conductor's `+` button and type `/start` — the harness reads it directly without an MCP fetch.

`/done` closes the Linear issue, writes a memory file, and resets progress state.

### Optional: Hindsight cloud memory

For semantic search across large memory sets, you can optionally enable Hindsight cloud memory during install. The installer will prompt you — native Claude Code memory is the default.

1. Get an API key at [ui.hindsight.vectorize.io/connect](https://ui.hindsight.vectorize.io/connect)
2. Add to your `.env`: `HINDSIGHT_API_KEY=your_key_here`
3. Re-run the installer and answer "y" to Hindsight

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
    skills/
      linear/SKILL.md       ← Linear issue read/write
      memory/SKILL.md       ← Graphiti memory search/write
      review/SKILL.md       ← Code review checklist
    agents/                  ← Project-specific subagents
    settings.json.template  ← Base permissions and hook registration
  conductor.json.template   ← Conductor setup/run/archive commands
  install.sh                ← The installer (called by npx)
```

---

## License

MIT
