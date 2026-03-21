---
name: memory
description: "Search and write to Graphiti cross-session memory for this project"
---

# Memory Skill

Uses Graphiti MCP (Zep Cloud) for persistent cross-session memory.

## MCP tool reference
- `search_facts(query, group_id)` — semantic search for facts/edges
- `search_nodes(query, group_id)` — semantic search for entities
- `add_episode(name, episode_body, group_id, source_description)` — write new memory
- `get_episodes(group_id, last_n)` — get recent episodes

## group_id convention
Use the project name: `nerdic-next`, `monomos`, `openfang`, `data-agent`, etc.
Derive from the git remote URL or project root directory name.

## When to search memory
- At session start (automatically via SessionStart hook)
- Before implementing any non-trivial feature
- When encountering an error that might have been seen before
- Before making architectural decisions

## When to write memory
- After /done command completes
- After discovering a non-obvious gotcha
- After making an architectural decision with lasting implications

## Gotchas
- If MCP is not connected, instruct: `claude mcp add graphiti-memory --transport sse --url https://mcp.getzep.com/sse --header "Authorization: Api-Key $ZEP_API_KEY"`
- Keep episodes specific and brief — Graphiti retrieves by semantic similarity, verbose episodes dilute signal
- Do not write memory for obvious facts, boilerplate decisions, or things already in CLAUDE.md
