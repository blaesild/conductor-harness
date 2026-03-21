---
name: linear
description: "Fetch and update Linear issues for the current task"
---

# Linear Skill

Use the Linear MCP tool to interact with issues.

## Common operations

**Fetch issue:**
Use `linear_get_issue` with the issue ID (e.g. LIN-123). Read title, description, comments, and acceptance criteria.

**Update status:**
Use `linear_save_issue` to update the status field. Valid transitions: Todo → In Progress → In Review → Done.

**Add comment:**
Use `linear_save_comment` to add a progress note or completion summary.

## Gotchas
- Issue IDs in branch names are uppercase (LIN-123); Linear API accepts both cases
- Always check acceptance criteria before marking done — it's often in the description
- If no Linear MCP is connected, instruct the user to run: `claude mcp add linear -s user -- npx -y @linear/mcp-server`
