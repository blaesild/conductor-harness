---
name: memory
description: "Write and recall cross-session memory using Claude Code's native memory system"
---

# Memory Skill

Uses Claude Code's built-in memory system. Memories are stored as markdown files in `~/.claude/projects/[project-path]/memory/` with a `MEMORY.md` index that is automatically loaded into every session.

## How it works

- **MEMORY.md** (the index) is loaded into context at session start — no action needed to recall
- To **write** a memory: use the Write tool to create a file in the memory directory with YAML frontmatter
- To **read** a specific memory: use the Read tool on a file listed in MEMORY.md
- To **update** the index: add a one-line pointer to MEMORY.md after writing a memory file

## Memory file format

```markdown
---
name: descriptive name
description: one-line summary — used for relevance matching in future sessions
type: project
---

[Memory content here]
```

## Types

| Type | Use for |
|------|---------|
| `project` | What was built, decisions made, gotchas discovered, patterns worth reusing |
| `feedback` | How the user wants Claude to work — corrections and confirmed approaches |
| `user` | User's role, expertise, preferences |
| `reference` | Pointers to external resources (Linear projects, dashboards, docs) |

## When to write memory

- After `/done` — what was built, key decisions, gotchas, reusable patterns
- After discovering a non-obvious gotcha or edge case
- After architectural decisions with lasting implications

## When NOT to write memory

- Obvious facts or boilerplate decisions
- Things already in CLAUDE.md
- Ephemeral state (current git status, in-progress work)
- Information derivable from code or git history

## Episode structure (for project memories after /done)

```markdown
---
name: branch-or-feature-name
description: one-line summary of what was done
type: project
---

## What was built
[Concrete: filenames, function names, components]

## Key decisions
- [Decision]: [why]

## Gotchas
- [Non-obvious discovery]

## Reusable patterns
- [Pattern]: [where in codebase]
```

## Optional: Hindsight cloud memory

If Hindsight MCP is configured (via `.mcp.json` and `HINDSIGHT_API_KEY`), you may also use:
- `recall(query)` — semantic search across cloud-stored memories
- `retain(content, tags)` — write to cloud memory

Native memory is the default. Hindsight is a supplemental option for semantic search across large memory sets.
