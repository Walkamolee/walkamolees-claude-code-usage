#!/usr/bin/env bash
# Install the claude-code-usage-check skill into ~/.claude/skills/ so Claude Code finds it.
# Run on each machine after cloning the repo.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
src="$repo_root/skills/claude-code-usage-check"
dst="$HOME/.claude/skills/claude-code-usage-check"

if [ ! -d "$src" ]; then
    echo "Source skill not found at $src" >&2
    exit 1
fi

mkdir -p "$HOME/.claude/skills"
rm -rf "$dst"
cp -r "$src" "$dst"
echo "Installed skill at $dst"
echo "Restart Claude Code (or start a new session) to pick it up."
