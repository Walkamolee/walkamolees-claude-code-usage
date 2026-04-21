#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
stamp="$(date +%Y-%m-%d)"

mkdir -p "$repo_root/reports"
ccusage daily   --json > "$repo_root/reports/${stamp}-daily.json"
ccusage monthly --json > "$repo_root/reports/${stamp}-monthly.json"

echo "Wrote reports/${stamp}-daily.json and reports/${stamp}-monthly.json"
