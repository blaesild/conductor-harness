---
description: "End-of-task ritual — writes memory, updates Linear, confirms PR-ready state"
---

Task completion for the current Linear issue:

1. Run the type checker and any available tests. Fix any failures before continuing.
2. Write a memory following the memory skill. Include what was built, key decisions, gotchas discovered, and patterns worth reusing. If in a worktree, write to the main repo's memory path (see session context).
3. Update `.harness/progress.md`: status: done, completed: [date], PR: [branch].
4. Update the Linear issue status to "In Review" using the Linear MCP tool. Add a comment with a one-sentence summary of what was done.
5. Confirm: "Ready for PR. Run ⌘⇧P in Conductor to create the PR."
