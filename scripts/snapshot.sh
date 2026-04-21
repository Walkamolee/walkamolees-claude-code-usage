#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
stamp="$(date +%Y-%m-%d)"
host="$(hostname)"
outdir="$repo_root/reports/$host"

mkdir -p "$outdir"
ccusage daily   --json > "$outdir/${stamp}-daily.json"
ccusage monthly --json > "$outdir/${stamp}-monthly.json"

echo "Wrote reports/$host/${stamp}-daily.json and reports/$host/${stamp}-monthly.json"
