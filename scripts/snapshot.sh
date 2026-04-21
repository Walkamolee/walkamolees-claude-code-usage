#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
stamp="$(date +%Y-%m-%d)"

# Per-machine privacy override: set CCUSAGE_MACHINE in $HOME/.ccusage-env
# if the raw hostname is sensitive.
[ -f "$HOME/.ccusage-env" ] && . "$HOME/.ccusage-env"
slug="${CCUSAGE_MACHINE:-$(hostname)}"
outdir="$repo_root/reports/$slug"

mkdir -p "$outdir"
ccusage daily   --json > "$outdir/${stamp}-daily.json"
ccusage monthly --json > "$outdir/${stamp}-monthly.json"

echo "Wrote reports/$slug/${stamp}-daily.json and reports/$slug/${stamp}-monthly.json"
