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

# Detect worktree — resolve main repo root for memory persistence
main_repo_root = cwd
try:
    git_common = subprocess.check_output(
        ["git", "-C", cwd, "rev-parse", "--git-common-dir"],
        stderr=subprocess.DEVNULL, text=True
    ).strip()
    # git-common-dir returns the .git dir of the main repo (not worktree's .git file)
    # If it's not the same as the local .git dir, we're in a worktree
    local_git = subprocess.check_output(
        ["git", "-C", cwd, "rev-parse", "--git-dir"],
        stderr=subprocess.DEVNULL, text=True
    ).strip()
    if os.path.abspath(git_common) != os.path.abspath(local_git):
        # We're in a worktree — main repo root is parent of .git/
        main_repo_root = os.path.dirname(os.path.abspath(git_common))
except Exception:
    pass

is_worktree = os.path.abspath(main_repo_root) != os.path.abspath(cwd)

# Read main repo's MEMORY.md if in a worktree (worktree memory path is ephemeral)
main_memory = ""
if is_worktree:
    # Claude Code memory path: ~/.claude/projects/-path-segments/memory/MEMORY.md
    sanitized = main_repo_root.replace("/", "-")
    main_memory_path = os.path.expanduser(f"~/.claude/projects/{sanitized}/memory/MEMORY.md")
    if os.path.exists(main_memory_path):
        with open(main_memory_path) as f:
            main_memory = f.read().strip()

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
if is_worktree:
    lines.append("")
    lines.append(f"**Worktree detected.** Main repo: `{main_repo_root}`")
    lines.append(f"Write all memories to the main repo's memory path, not the worktree's.")
    # Provide the resolved main memory dir so Claude can write there
    sanitized = main_repo_root.replace("/", "-")
    main_mem_dir = os.path.expanduser(f"~/.claude/projects/{sanitized}/memory")
    lines.append(f"**Memory directory:** `{main_mem_dir}/`")
    lines.append(f"**Memory index:** `{main_mem_dir}/MEMORY.md`")
    if main_memory:
        lines.append("")
        lines.append("**Main repo MEMORY.md:**")
        lines.append(main_memory)
    lines.append("")
    lines.append("**Action:** Scan the main repo memory above for entries relevant to this branch/task before responding.")
else:
    lines.append("")
    lines.append("**Action:** MEMORY.md is loaded automatically. Scan it for entries relevant to this branch/task before responding.")

print(json.dumps({"promptText": "\n".join(lines)}))
