---
name: memory
description: "Search and write to Hindsight cross-session memory for this project"
---

# Memory Skill

Uses Hindsight MCP for persistent cross-session memory.

## MCP tool reference
- `recall(query)` — semantic search across stored memories
- `retain(content, tags)` — write a new memory (decisions, gotchas, patterns)
- `reflect(question)` — get an AI answer using your memories as context
- `create_mental_model(name, description)` — create a living summary document

## When to search memory
- At session start (automatically via SessionStart hook)
- Before implementing any non-trivial feature
- When encountering an error that might have been seen before
- Before making architectural decisions

## When to write memory
- After /done command completes
- After discovering a non-obvious gotcha
- After making an architectural decision with lasting implications

## Tagging convention
Always tag memories with the project name derived from the git remote URL or project root directory name (e.g. `my-project`, `api-service`).

## Gotchas
- If MCP is not connected, add `HINDSIGHT_API_KEY` to `.env` and ensure `.mcp.json` is present
- Keep memories specific and brief — recall uses semantic search, verbose entries dilute signal
- Do not write memory for obvious facts, boilerplate decisions, or things already in CLAUDE.md
