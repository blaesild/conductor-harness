#!/usr/bin/env bash
# Harness install.sh — installs Claude Code harness into any project root
# Usage: cd /path/to/your-project && bash /path/to/Harness/runtime/install.sh
set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(pwd)"

# ── 1. Must be in a git repo ─────────────────────────────────────────────────
if ! git -C "$TARGET_DIR" rev-parse --git-dir > /dev/null 2>&1; then
  echo "ERROR: Not a git repository. Run install.sh from your project root." >&2
  exit 1
fi

echo "Installing Harness into: $TARGET_DIR"
echo ""

# ── 2. Detect package manager ────────────────────────────────────────────────
if [ -f "$TARGET_DIR/pnpm-lock.yaml" ]; then
  PKG_MANAGER="pnpm"
elif [ -f "$TARGET_DIR/yarn.lock" ]; then
  PKG_MANAGER="yarn"
elif [ -f "$TARGET_DIR/bun.lockb" ]; then
  PKG_MANAGER="bun"
elif [ -f "$TARGET_DIR/package-lock.json" ]; then
  PKG_MANAGER="npm"
else
  echo "WARNING: No lockfile found. Defaulting to npm."
  PKG_MANAGER="npm"
fi
echo "Detected package manager: $PKG_MANAGER"

# ── 3. Railway prompt ────────────────────────────────────────────────────────
read -r -p "Does this project use Railway? [y/N] " USE_RAILWAY
USE_RAILWAY="$(echo "$USE_RAILWAY" | tr '[:upper:]' '[:lower:]')"

# ── 4. Create .claude subdirs ────────────────────────────────────────────────
mkdir -p \
  "$TARGET_DIR/.claude/hooks" \
  "$TARGET_DIR/.claude/commands" \
  "$TARGET_DIR/.claude/agents" \
  "$TARGET_DIR/.claude/skills/linear" \
  "$TARGET_DIR/.claude/skills/memory" \
  "$TARGET_DIR/.claude/skills/review"

# ── 5. Copy hook scripts ─────────────────────────────────────────────────────
cp "$HARNESS_DIR/.claude/hooks/session-start.sh" "$TARGET_DIR/.claude/hooks/session-start.sh"
cp "$HARNESS_DIR/.claude/hooks/stop.sh" "$TARGET_DIR/.claude/hooks/stop.sh"
chmod +x "$TARGET_DIR/.claude/hooks/session-start.sh"
chmod +x "$TARGET_DIR/.claude/hooks/stop.sh"
echo "✓ Hooks installed"

# ── 6. Copy commands ─────────────────────────────────────────────────────────
cp "$HARNESS_DIR/.claude/commands/start.md"  "$TARGET_DIR/.claude/commands/start.md"
cp "$HARNESS_DIR/.claude/commands/done.md"   "$TARGET_DIR/.claude/commands/done.md"
cp "$HARNESS_DIR/.claude/commands/status.md" "$TARGET_DIR/.claude/commands/status.md"
echo "✓ Commands installed (/start, /done, /status)"

# ── 7. Copy agents ───────────────────────────────────────────────────────────
cp "$HARNESS_DIR/.claude/agents/memory-writer.md" "$TARGET_DIR/.claude/agents/memory-writer.md"
echo "✓ Agents installed"

# ── 8. Copy skills ───────────────────────────────────────────────────────────
cp "$HARNESS_DIR/.claude/skills/linear/SKILL.md"  "$TARGET_DIR/.claude/skills/linear/SKILL.md"
cp "$HARNESS_DIR/.claude/skills/memory/SKILL.md"  "$TARGET_DIR/.claude/skills/memory/SKILL.md"
cp "$HARNESS_DIR/.claude/skills/review/SKILL.md"  "$TARGET_DIR/.claude/skills/review/SKILL.md"
echo "✓ Skills installed (linear, memory, review)"

# ── 9. settings.local.json — always merge (never overwrite) ──────────────────
SETTINGS_FILE="$TARGET_DIR/.claude/settings.local.json"

if [ -f "$SETTINGS_FILE" ]; then
  echo "Merging hooks into existing .claude/settings.local.json..."
  python3 - "$SETTINGS_FILE" "$PKG_MANAGER" <<'PYEOF'
import sys, json

settings_path = sys.argv[1]
pkg_manager = sys.argv[2]

with open(settings_path) as f:
    existing = json.load(f)

harness_hooks = {
    "SessionStart": {"matcher": "", "hooks": [{"type": "command", "command": ".claude/hooks/session-start.sh"}]},
    "Stop": {"matcher": "", "hooks": [{"type": "command", "command": ".claude/hooks/stop.sh", "timeout": 30}]}
}

harness_allow = [
    f"Bash(git *)",
    f"Bash({pkg_manager} *)",
    "Bash(npx *)",
    "Bash(tsc *)"
]

harness_deny = [
    "Bash(git push --force *)",
    "Bash(git push -f *)"
]

# Merge hooks — each event is a list of {matcher, hooks} objects
if "hooks" not in existing:
    existing["hooks"] = {}
for event, entry in harness_hooks.items():
    if event not in existing["hooks"]:
        existing["hooks"][event] = []
    existing_cmds = [
        cmd.get("command")
        for h in existing["hooks"][event]
        for cmd in h.get("hooks", [])
    ]
    cmd = entry["hooks"][0].get("command")
    if cmd not in existing_cmds:
        existing["hooks"][event].append(entry)

# Merge permissions
if "permissions" not in existing:
    existing["permissions"] = {}
if "allow" not in existing["permissions"]:
    existing["permissions"]["allow"] = []
if "deny" not in existing["permissions"]:
    existing["permissions"]["deny"] = []

for item in harness_allow:
    if item not in existing["permissions"]["allow"]:
        existing["permissions"]["allow"].append(item)
for item in harness_deny:
    if item not in existing["permissions"]["deny"]:
        existing["permissions"]["deny"].append(item)

with open(settings_path, "w") as f:
    json.dump(existing, f, indent=2)
print("✓ settings.local.json merged")
PYEOF
else
  # Create fresh settings.local.json from template with PKG_MANAGER substituted
  python3 - "$HARNESS_DIR/.claude/settings.json.template" "$SETTINGS_FILE" "$PKG_MANAGER" <<'PYEOF'
import sys, json, re

template_path = sys.argv[1]
out_path = sys.argv[2]
pkg_manager = sys.argv[3]

with open(template_path) as f:
    content = f.read()

content = content.replace("<PKG_MANAGER>", pkg_manager)

# Strip the trailing Note comment before parsing JSON
content = re.sub(r'\n\nNote:.*', '', content, flags=re.DOTALL)

data = json.loads(content)
with open(out_path, "w") as f:
    json.dump(data, f, indent=2)
print("✓ settings.local.json created")
PYEOF
fi

# ── 10. CLAUDE.md — always overwrite ─────────────────────────────────────────
CLAUDE_MD="$TARGET_DIR/CLAUDE.md"
cp "$HARNESS_DIR/.claude/CLAUDE.md.template" "$CLAUDE_MD"
echo "✓ CLAUDE.md written (overwritten)"

# ── 11. conductor.json — always overwrite ─────────────────────────────────────
CONDUCTOR_FILE="$TARGET_DIR/conductor.json"

if true; then
  if [ "$USE_RAILWAY" = "y" ] || [ "$USE_RAILWAY" = "yes" ]; then
    SETUP_CMD="ln -s \"\$CONDUCTOR_ROOT_PATH/.env\" .env && source .env && ${PKG_MANAGER} install && ${PKG_MANAGER} run generate:types 2>/dev/null || true && railway link --project \$RAILWAY_PROJECT_ID --environment \$RAILWAY_ENVIRONMENT_ID --service \$RAILWAY_SERVICE_ID"
  else
    SETUP_CMD="ln -s \"\$CONDUCTOR_ROOT_PATH/.env\" .env && ${PKG_MANAGER} install && ${PKG_MANAGER} run generate:types 2>/dev/null || true"
  fi

  python3 - "$CONDUCTOR_FILE" "$PKG_MANAGER" "$SETUP_CMD" <<'PYEOF'
import sys, json

out_path = sys.argv[1]
pkg_manager = sys.argv[2]
setup_cmd = sys.argv[3]

data = {
    "setup": setup_cmd,
    "run": f"{pkg_manager} dev --port $CONDUCTOR_PORT",
    "archive": "rm -rf .next node_modules .turbo"
}
with open(out_path, "w") as f:
    json.dump(data, f, indent=2)
print("✓ conductor.json written (overwritten)")
PYEOF
  if [ "$USE_RAILWAY" = "y" ] || [ "$USE_RAILWAY" = "yes" ]; then
    echo "  → Add RAILWAY_PROJECT_ID, RAILWAY_ENVIRONMENT_ID, RAILWAY_SERVICE_ID to your .env"
  fi
fi

# ── 12. .gitignore — append .harness/ if missing ─────────────────────────────
GITIGNORE="$TARGET_DIR/.gitignore"
if [ -f "$GITIGNORE" ]; then
  if grep -qF ".harness/" "$GITIGNORE"; then
    echo "✓ .gitignore already ignores .harness/ (skipped)"
  else
    echo "" >> "$GITIGNORE"
    echo "# Harness local state" >> "$GITIGNORE"
    echo ".harness/" >> "$GITIGNORE"
    echo "✓ .harness/ added to .gitignore"
  fi
else
  printf "# Harness local state\n.harness/\n" > "$GITIGNORE"
  echo "✓ .gitignore created with .harness/"
fi

# ── 13. Create .harness/ with progress stub ───────────────────────────────────
mkdir -p "$TARGET_DIR/.harness"
if [ ! -f "$TARGET_DIR/.harness/progress.md" ]; then
  cat > "$TARGET_DIR/.harness/progress.md" <<'EOF'
# Harness Progress

<!-- Updated automatically by /start and /done commands -->

status: idle
EOF
  echo "✓ .harness/progress.md created"
fi

# ── 14. WORKFLOW.md — copy template if not already present ───────────────────
if [ ! -f "$TARGET_DIR/WORKFLOW.md" ]; then
  cp "$HARNESS_DIR/WORKFLOW.md.template" "$TARGET_DIR/WORKFLOW.md"
  echo "✓ WORKFLOW.md created — fill in your project context"
else
  echo "✓ WORKFLOW.md already exists (skipped)"
fi

# ── 15. .mcp.json — create or append Hindsight MCP entry ─────────────────────
MCP_JSON="$TARGET_DIR/.mcp.json"

python3 - "$MCP_JSON" <<'PYEOF'
import sys, json, os

mcp_path = sys.argv[1]

hindsight_entry = {
    "type": "http",
    "url": "https://api.hindsight.vectorize.io/mcp/Claude/",
    "headers": {
        "Authorization": "Bearer ${HINDSIGHT_API_KEY}"
    }
}

if os.path.exists(mcp_path):
    with open(mcp_path) as f:
        data = json.load(f)
    if "mcpServers" not in data:
        data["mcpServers"] = {}
    if "hindsight" not in data["mcpServers"]:
        data["mcpServers"]["hindsight"] = hindsight_entry
        print("✓ Hindsight MCP added to existing .mcp.json")
    else:
        print("✓ .mcp.json already has hindsight entry (skipped)")
else:
    data = {"mcpServers": {"hindsight": hindsight_entry}}
    print("✓ .mcp.json created with Hindsight MCP")

with open(mcp_path, "w") as f:
    json.dump(data, f, indent=2)
PYEOF

# ── 16. Next steps ────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════"
echo "  Harness installed successfully!"
echo "══════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo ""
echo "1. Add your Hindsight API key to .env:"
echo "   HINDSIGHT_API_KEY=your_key_here"
echo "   Get a key at: https://ui.hindsight.vectorize.io/connect"
echo ""
echo "2. Register Linear MCP (once per machine, if not already):"
echo "   claude mcp add linear -s user -- npx -y @linear/mcp-server"
echo ""
echo "3. Open this project in Claude Code — hooks will fire automatically."
echo ""
echo "4. Start a task: /start LIN-123"
echo "   End a task:   /done"
echo "   Check status: /status"
echo ""
echo "5. Fill in WORKFLOW.md — injected into every Claude Code session as project context."
echo "   Or type /setup inside Claude Code to auto-generate it from your project structure."
echo ""
if [ "$USE_RAILWAY" = "y" ] || [ "$USE_RAILWAY" = "yes" ]; then
  echo "6. Edit conductor.json and replace the RAILWAY_* placeholders."
  echo ""
fi
echo "Docs: https://github.com/blaesild/conductor-harness"
