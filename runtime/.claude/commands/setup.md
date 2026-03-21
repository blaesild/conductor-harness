---
description: "One-time project setup — analyze project context, generate WORKFLOW.md, tailor harness"
---

Analyze this project and generate a WORKFLOW.md:

1. Read `package.json` (if exists): extract name, scripts, key dependencies.
2. Read existing `CLAUDE.md` for any stated conventions or architecture notes.
3. Check for: `railway.toml`, `vercel.json`, `fly.toml`, `.env.example` — detect deployment platform.
4. Run `git log --oneline -20` — summarize the recent direction of work.
5. Check `.claude/` for existing skills, hooks, commands — note what's already configured.
6. Check `docs/` or `README.md` for architecture documentation.

Then write `WORKFLOW.md` at the project root with:
- **What We're Building**: 1-3 sentences from package.json name/description + README context
- **Current Phase**: inferred from git log and feature names (MVP / scaling / maintenance / etc.)
- **Stack**: detected framework, database, deployment, package manager
- **Architecture Notes**: 3-5 non-obvious decisions derived from the codebase structure
- **Active Constraints**: any rules found in CLAUDE.md or docs
- **What We're NOT Building**: leave blank — ask Sebastian to fill this in

After writing WORKFLOW.md:
- Print "WORKFLOW.md created. Review it and fill in 'What We're NOT Building'."
- Suggest any MCP servers not yet configured that would help this project (based on detected stack).
- If the project uses Railway and `conductor.json` is missing, suggest running install.sh.
