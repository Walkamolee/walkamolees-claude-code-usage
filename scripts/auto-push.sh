#!/usr/bin/env bash
# Cron-safe wrapper: regenerate today's snapshot for this machine, then commit/push.
# Only touches reports/<machine-slug>/ so multiple machines don't clobber each other.
set -euo pipefail

# --- make node/ccusage visible under cron / Task Scheduler's minimal PATH ---
# Linux/macOS nvm (if installed)
export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" >/dev/null 2>&1 || true
if [ -d "$NVM_DIR/versions/node" ]; then
    export PATH="$NVM_DIR/versions/node/$(ls -1 "$NVM_DIR/versions/node" 2>/dev/null | sort -V | tail -n1)/bin:$PATH"
fi
# Windows (Git Bash / MSYS under Task Scheduler): npm globals + system Node.
# $APPDATA arrives as Windows-style "C:\..."; Git Bash's Node shim needs MSYS-style.
case "${OSTYPE:-}" in
    msys*|cygwin*|win32*)
        if [ -n "${APPDATA:-}" ] && command -v cygpath >/dev/null 2>&1; then
            export PATH="$(cygpath -u "$APPDATA")/npm:$PATH"
        fi
        [ -d "/c/Program Files/nodejs" ] && export PATH="/c/Program Files/nodejs:$PATH"
        ;;
esac
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

# Per-machine privacy overrides: CCUSAGE_MACHINE (folder slug) and
# CCUSAGE_MACHINE_DISPLAY (pretty commit-message name). Set these in
# $HOME/.ccusage-env (not committed) if the raw hostname is sensitive.
[ -f "$HOME/.ccusage-env" ] && . "$HOME/.ccusage-env"
slug="${CCUSAGE_MACHINE:-$(hostname)}"
display="${CCUSAGE_MACHINE_DISPLAY:-$slug}"

cd "$repo_root"

# pull latest so other machines' pushes don't block ours
git pull --rebase --autostash origin main >/dev/null

bash "$repo_root/scripts/snapshot.sh"

# stage only this host's folder
git add "reports/$slug"

if git diff --cached --quiet; then
    echo "[$(date -Is)] $slug: no changes"
    exit 0
fi

git -c user.name="ccusage-bot" -c user.email="ccusage-bot@users.noreply.github.com" \
    commit -m "[$display] snapshot $(date +%Y-%m-%d)"

# retry push a few times in case another machine is pushing simultaneously
for i in 1 2 3; do
    if git push origin main; then
        echo "[$(date -Is)] $slug: pushed"
        exit 0
    fi
    echo "[$(date -Is)] $slug: push attempt $i failed, rebasing and retrying"
    git pull --rebase --autostash origin main >/dev/null || true
    sleep $((i * 5))
done

echo "[$(date -Is)] $slug: push failed after 3 attempts" >&2
exit 1
