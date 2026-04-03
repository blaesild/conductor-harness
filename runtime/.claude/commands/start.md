---
description: "Task kickoff ritual — loads Linear issue, checks memory, sets progress"
---

Load task context for $ARGUMENTS:

0. Check if a Linear issue is already provided in the current message context (attached via Conductor's + button). If so, read it directly — skip the MCP fetch. Only use the Linear MCP tool if additional detail is needed (comments, linked issues, acceptance criteria not shown).
1. If $ARGUMENTS contains a Linear issue ID (e.g. LIN-123) and no issue was attached: fetch it now using the Linear MCP tool. Read the description, comments, and acceptance criteria.
2. Check MEMORY.md (already in context) for entries relevant to this task or feature area. Read specific memory files if needed for detail.
3. Identify the primary frameworks/packages this task touches. Fetch current docs for each via Context7 — resolve the library ID first, then query for the relevant API surface. Do this before planning, not after.
4. Run `git status` and `git log --oneline -5`.
5. Read `.harness/progress.md` if it exists.
6. Write a 3-5 line summary of: what you're building, what you know from memory, and the first concrete action you'll take.
7. Update `.harness/progress.md` with: Linear issue, task summary, status: in-progress, started: [date].
