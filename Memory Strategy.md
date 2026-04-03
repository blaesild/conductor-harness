---
tags: [harness-engineering, claude-code, conductor, ai]
created: 2026-03-20
status: superseded
---

# Memory Strategy

## Update: Migration to Native Memory (2026-04)

Claude Code now includes a built-in filesystem memory system at `~/.claude/projects/`. This replaces Zep Cloud / Hindsight as the **default** memory backend.

- Zero cost, zero config, zero API key
- Memories stored as markdown files with YAML frontmatter
- MEMORY.md index loaded automatically into every session
- Per-project isolation via filesystem path (not group_id)

Hindsight remains available as an **optional** cloud supplement for semantic search across large memory sets. The episode schema and write/don't-write guidance remain unchanged.

---

## Historical: Zep Cloud Flex (2026-03)

**Choice:** Zep Cloud Flex tier (~$25/mo)
**Engine:** Graphiti (same engine used in Nerdic-next — Sebastian already knows it)
**MCP:** Production HTTP/SSE server at `https://mcp.getzep.com/sse`

### Why Zep Cloud

- Zero infrastructure — no Railway Neo4j to deploy and maintain
- Safe MCP transport: HTTP/SSE avoids the `stdio` hang bug (Claude Code Issue #15945, status: NOT_PLANNED)
- Per-project isolation via `group_id` — no cross-project topic bleed
- Mobile access: cloud URL works from any device, no VPN or local server
- Migration path exists: single URL/key swap to move to self-hosted Railway Graphiti

### What Was Ruled Out

| Option | Reason Rejected |
|--------|----------------|
| Local file memory (plain markdown) | Not semantic; no retrieval; not cross-session queryable |
| mem0 cloud | Different engine; no Graphiti familiarity |
| Self-hosted Railway Graphiti | Correct engine, but requires infra setup for baseline; use for cost optimization later |
| Obsidian vault as memory | Read-only for Claude; not structured for retrieval |

## group_id Convention

Memory is namespaced per project using `group_id`. Convention:

```
nerdic-next    → group_id: "nerdic-next"
monomos        → group_id: "monomos"
openfang       → group_id: "openfang"
data-agent     → group_id: "data-agent"
kriminyt       → group_id: "kriminyt"
```

Derivation logic (in hooks/skills):
1. Try `git remote get-url origin` → extract repo name → slugify
2. Fall back to `basename $PWD` → slugify (lowercase, spaces→hyphens)

No cross-project memory. Episodes written to `group_id: "nerdic-next"` are never returned in queries with `group_id: "monomos"`.

## Episode Schema

What to write in a memory episode (via `/done` or memory-writer subagent):

### Write this
- What was built or changed (concrete: file names, function names, component names)
- Key architectural decisions and the reason behind them
- Gotchas: non-obvious behavior, edge cases, framework quirks discovered
- Patterns worth reusing in the same project (utilities, hooks, query patterns)
- Why a particular approach was chosen over alternatives considered

### Don't write this
- Obvious facts (TypeScript uses types, Payload CMS has collections)
- Things already documented in CLAUDE.md
- Boilerplate decisions (naming conventions already established)
- Ephemeral state (current git status, in-progress work)
- Information already in the codebase or git history

### Episode name format
```
[2026-03-20] [feat/LIN-42-auth-flow]: Added JWT refresh token rotation
[2026-03-20] [fix/LIN-99-memory-leak]: Discovered unsubscribed RxJS observable in sidebar
[2026-03-20] [refactor/LIN-77-query-layer]: Moved all db queries to repository pattern
```

### Episode body structure
```
## What was built
[Specific description of changes]

## Key decisions
- [Decision 1]: [why]
- [Decision 2]: [why]

## Gotchas
- [Non-obvious thing discovered]

## Reusable patterns
- [Pattern]: [where it appears in the codebase]
```

## MCP Registration

One-time setup per machine (not per project):

```bash
# Zep Cloud memory MCP
export ZEP_API_KEY=your_zep_api_key
claude mcp add graphiti-memory \
  --transport sse \
  --url https://mcp.getzep.com/sse \
  --header "Authorization: Api-Key $ZEP_API_KEY"

# Linear MCP (user-scoped)
claude mcp add linear -s user -- npx -y @linear/mcp-server
```

Verify: open Claude Code, type `/mcp` — both should appear.

## Migration Path to Self-Hosted

When Zep Cloud cost justification tips (e.g. $25/mo feels high for usage level, or you want full data control):

1. Deploy Railway Graphiti: see `[[Memory/Railway Graphiti Deployment]]`
2. Note your Railway service URL (e.g. `https://graphiti-xyz.up.railway.app`)
3. Update MCP registration:
   ```bash
   claude mcp remove graphiti-memory
   claude mcp add graphiti-memory \
     --transport sse \
     --url https://your-railway-url/sse \
     --header "Authorization: Api-Key $YOUR_GRAPHITI_KEY"
   ```
4. All existing memory in Zep Cloud stays there. New episodes go to self-hosted.
5. Optionally export/import Zep Cloud episodes to Railway Graphiti (Graphiti export API).

**That's it.** The skills, hooks, and commands are unchanged. Only the MCP URL changes.

## Related

- `[[Memory/Railway Graphiti Deployment]]` — self-hosted deployment guide
- `Architecture.md` — how memory fits into the full harness flow
- `00 Harness.md` — quick start and decision log
