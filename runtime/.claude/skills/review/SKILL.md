---
name: review
description: "Pre-PR code review checklist for harness-engineered projects"
---

# Review Skill

Run this before creating a PR. Check each item:

## Code quality
- [ ] TypeScript: `tsc --noEmit` passes with zero errors
- [ ] No `console.log` debug statements committed
- [ ] No hardcoded secrets, API keys, or environment-specific values
- [ ] All new files follow existing naming conventions

## Correctness
- [ ] The Linear acceptance criteria are met (re-read them now)
- [ ] Edge cases handled (empty states, error paths, loading states)
- [ ] No obvious N+1 queries or unnecessary re-renders

## Harness hygiene
- [ ] `.harness/progress.md` updated with done status
- [ ] Memory episode written to Graphiti (run /done if not done)
- [ ] No debug/temp files committed

## Git
- [ ] Commits are clean and descriptive (not "fix stuff" or "wip")
- [ ] Branch is up to date with main (run `git fetch && git rebase origin/main` if needed)

If anything fails, fix it before creating the PR.
