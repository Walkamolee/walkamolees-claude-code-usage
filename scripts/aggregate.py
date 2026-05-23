#!/usr/bin/env python3
"""Aggregate the latest monthly snapshot per machine into a cross-machine summary.

Reads reports/<host>/*-monthly.json (one per machine), takes the most recent
file per host, and prints a markdown summary with grand totals, per-machine
breakdown, and per-model breakdown.
"""
import glob
import json
import os
import sys
from collections import defaultdict

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPORTS_DIR = os.path.join(REPO_ROOT, "reports")


def main() -> int:
    if not os.path.isdir(REPORTS_DIR):
        print(f"reports/ not found at {REPORTS_DIR}", file=sys.stderr)
        return 1

    per_host = {}
    grand = defaultdict(float)
    model_totals = defaultdict(lambda: defaultdict(float))

    for host in sorted(os.listdir(REPORTS_DIR)):
        host_dir = os.path.join(REPORTS_DIR, host)
        if not os.path.isdir(host_dir):
            continue
        monthly = sorted(glob.glob(os.path.join(host_dir, "*-monthly.json")))
        if not monthly:
            continue
        latest = monthly[-1]
        with open(latest, encoding="utf-8") as f:
            data = json.load(f)
        snapshot_date = os.path.basename(latest)[:10]
        totals = data.get("totals", {})
        months = data.get("monthly", [])
        per_host[host] = (snapshot_date, totals, months)
        for k, v in totals.items():
            if isinstance(v, (int, float)):
                grand[k] += v
        for m in months:
            for mb in m.get("modelBreakdowns", []):
                for k in ("inputTokens", "outputTokens", "cacheCreationTokens", "cacheReadTokens", "cost"):
                    model_totals[mb["modelName"]][k] += mb.get(k, 0)

    if not per_host:
        print("No reports found under reports/", file=sys.stderr)
        return 1

    def i(n): return f"{int(n):,}"
    def m(n): return f"${n:,.2f}"

    out = []
    out.append("# Claude Code usage - cross-machine")
    out.append("")
    out.append("## Grand total (lifetime, latest snapshot per machine)")
    out.append("")
    out.append("| Metric | Value |")
    out.append("|---|---:|")
    out.append(f"| Input tokens | {i(grand['inputTokens'])} |")
    out.append(f"| Output tokens | {i(grand['outputTokens'])} |")
    out.append(f"| Cache create | {i(grand['cacheCreationTokens'])} |")
    out.append(f"| Cache read | {i(grand['cacheReadTokens'])} |")
    out.append(f"| **Total tokens** | **{i(grand['totalTokens'])}** |")
    out.append(f"| **API-equivalent cost** | **{m(grand['totalCost'])}** |")
    out.append("")
    out.append("## Per machine")
    out.append("")
    out.append("| Host | Snapshot | Months | Total tokens | Cost |")
    out.append("|---|---|---|---:|---:|")
    for host, (snap, t, months) in per_host.items():
        span = f"{months[0]['month']} - {months[-1]['month']}" if months else "-"
        out.append(
            f"| {host} | {snap} | {len(months)} ({span}) | "
            f"{i(t.get('totalTokens', 0))} | {m(t.get('totalCost', 0))} |"
        )
    out.append("")
    out.append("## By model")
    out.append("")
    out.append("| Model | Cost | Tokens |")
    out.append("|---|---:|---:|")
    for model, mb in sorted(model_totals.items(), key=lambda x: -x[1]["cost"]):
        tot = mb["inputTokens"] + mb["outputTokens"] + mb["cacheCreationTokens"] + mb["cacheReadTokens"]
        out.append(f"| {model} | {m(mb['cost'])} | {i(tot)} |")

    print("\n".join(out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
