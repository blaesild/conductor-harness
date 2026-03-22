#!/usr/bin/env python3
# Stop hook — runs after Claude finishes each response
# Runs type checker. If errors: exit 2 (blocks, Claude sees stderr and fixes).
# Non-blocking: memory writes happen via the /done command, not on every stop.
import sys, json, subprocess, os

event = json.load(sys.stdin)
cwd = event.get("cwd", os.getcwd())

# Detect project type and run appropriate type checker
errors = []
if os.path.exists(os.path.join(cwd, "tsconfig.json")):
    try:
        result = subprocess.run(
            ["npx", "tsc", "--noEmit"],
            cwd=cwd, capture_output=True, text=True, timeout=30
        )
        if result.returncode != 0:
            errors.append(result.stdout + result.stderr)
    except subprocess.TimeoutExpired:
        pass  # Don't block on timeout
    except FileNotFoundError:
        pass  # npx not available, skip

if errors:
    # exit 2 = block, stderr is shown to Claude
    print("\n".join(errors), file=sys.stderr)
    sys.exit(2)

sys.exit(0)
