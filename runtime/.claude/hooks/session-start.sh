#!/usr/bin/env python3
# SessionStart hook — injects structured context before first user message
# Receives JSON event on stdin, returns {"promptText": "..."} on stdout
import sys, json, subprocess, os, re

event = json.load(sys.stdin)
cwd = event.get("cwd", os.getcwd())

# Get branch name → extract Linear issue ID
try:
    branch = subprocess.check_output(
        ["git", "-C", cwd, "branch", "--show-current"],
        stderr=subprocess.DEVNULL, text=True
    ).strip()
except Exception:
    branch = "unknown"

linear_match = re.search(r'([A-Z]+-\d+)', branch.upper())
linear_id = linear_match.group(1) if linear_match else None

# Recent git log
try:
    git_log = subprocess.check_output(
        ["git", "-C", cwd, "log", "--oneline", "-8"],
        stderr=subprocess.DEVNULL, text=True
    ).strip()
except Exception:
    git_log = "(no git history)"

# Ensure .harness/ exists (worktrees don't inherit gitignored dirs)
harness_dir = os.path.join(cwd, ".harness")
os.makedirs(harness_dir, exist_ok=True)

# Progress file
progress = ""
progress_path = os.path.join(harness_dir, "progress.md")
if os.path.exists(progress_path):
    with open(progress_path) as f:
        progress = f.read().strip()
else:
    with open(progress_path, "w") as f:
        f.write("# Harness Progress\n\nstatus: idle\n")

# Build context block
lines = ["## Harness: Session Context", ""]
lines.append(f"**Branch:** `{branch}`")
if linear_id:
    lines.append(f"**Linear issue detected:** `{linear_id}` — fetch details with the Linear MCP tool before starting work.")
lines.append("")
lines.append("**Recent commits:**")
lines.append("```")
lines.append(git_log or "(none)")
lines.append("```")
if progress:
    lines.append("")
    lines.append("**Last session progress:**")
    lines.append(progress)
lines.append("")
lines.append("**Action:** MEMORY.md is loaded automatically. Scan it for entries relevant to this branch/task before responding.")

print(json.dumps({"promptText": "\n".join(lines)}))
