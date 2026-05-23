---
name: claude-code-usage-check
description: Use when the user asks "what is my usage", "what has my usage been", "check my usage", "how much have I used / spent on claude", or wants a fresh cross-machine snapshot of Claude Code token consumption. Do NOT use for single-session cost (use /cost) or Anthropic subscription billing questions.
---

# Claude Code Usage Check

## Overview

Refreshes THIS machine's ccusage snapshot, pushes it to the `walkamolees-claude-code-usage` GitHub repo, pulls every other machine's latest snapshot, and reports a cross-machine summary.

The repo aggregates per-host snapshots from several machines. Running the skill always produces fresh totals — never stale cached numbers.

## When to use

Triggers:
- "what is my usage" / "what has my usage been"
- "check my usage" / "check my claude code usage"
- "how much have I used" / "how much have I spent on claude"
- "claude code spend" / "claude code cost so far"

When NOT to use:
- Single-session cost: tell the user to run `/cost`.
- Anthropic subscription billing: this reports API-equivalent cost, not flat-rate subscription billing.

## Steps

**1. Locate the local clone of the repo.** Try in order, use the first that exists:
- `$HOME/projects/walkamolees-claude-code-usage`
- `$HOME/walkamolees-claude-code-usage`
- On Windows under Git Bash, `$HOME` is `/c/Users/<user>`. The same paths apply.

If none exist, clone it: `gh repo clone Walkamolee/walkamolees-claude-code-usage "$HOME/projects/walkamolees-claude-code-usage"`.

**2. Snapshot + push this machine's data.**
```bash
bash <repo>/scripts/auto-push.sh
```
The script pulls --rebase, runs `ccusage daily/monthly --json` for this host's slug, commits to `reports/<hostname>/`, and retries the push up to 3 times if another machine is pushing concurrently.

If `ccusage` is missing: `npm i -g ccusage`. If `node`/`npm` are missing, tell the user.

**3. Aggregate cross-machine totals.**
```bash
python <repo>/scripts/aggregate.py
```
Outputs markdown with grand total, per-machine breakdown, and per-model breakdown. On Windows use `python` (not `python3`).

**4. Report to user.** Present the aggregate output as-is, plus a one-line note saying which machine you just refreshed (the current `hostname`).

## Quick reference

| Action | Command |
|---|---|
| Locate repo | `ls "$HOME/projects/walkamolees-claude-code-usage"` |
| Snapshot + push this machine | `bash <repo>/scripts/auto-push.sh` |
| Aggregate all machines | `python <repo>/scripts/aggregate.py` |
| Install ccusage if missing | `npm i -g ccusage` |
| Clone repo if missing | `gh repo clone Walkamolee/walkamolees-claude-code-usage` |

## Common mistakes

- **Skipping step 2.** If you only run `aggregate.py`, this machine's row will be stale (or missing if the cron hasn't run today). Always snapshot+push first.
- **Treating cost as billing.** `totalCost` is what the logged tokens *would* cost at public API rates. On a Max/Pro subscription, actual billing is flat. Say so.
- **Reporting other machines as live.** Each row is as fresh as that machine's last `auto-push.sh` run (typically a daily cron). If a host hasn't snapshotted in weeks, note that.
- **Forgetting cross-platform `python`.** On Windows the binary is `python`, not `python3`. Try both.
