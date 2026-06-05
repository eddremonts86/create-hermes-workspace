#!/usr/bin/env bash
# superpowers-purge.sh
# Remove gate events older than N days from the JSONL.
#
# Usage:
#   superpowers-purge.sh [days]
#   days default: 30
#
# Logs the purge itself as a gate-events-purge event.

set -uo pipefail

DAYS="${1:-30}"
LOG_FILE="/opt/data/var/gate-events.jsonl"

if [ ! -f "$LOG_FILE" ]; then
  exit 0
fi

# Compute cutoff date in ISO 8601 UTC
# Try GNU date syntax first, fall back to BSD (macOS)
CUTOFF=$(date -u -d "$DAYS days ago" +%FT%TZ 2>/dev/null) || \
  CUTOFF=$(date -u -v-"$DAYS"d +%FT%TZ)

before=$(wc -l < "$LOG_FILE")

# Filter: keep only events with ts > cutoff
tmp=$(mktemp)
if jq -c --arg cutoff "$CUTOFF" 'select(.ts > $cutoff)' "$LOG_FILE" > "$tmp" 2>/dev/null; then
  mv "$tmp" "$LOG_FILE"
else
  rm -f "$tmp"
  printf 'superpowers-purge: jq filter failed; log not modified\n' >&2
  exit 1
fi

after=$(wc -l < "$LOG_FILE")
removed=$((before - after))

printf 'Purged %d events older than %d days (kept %d)\n' "$removed" "$DAYS" "$after"

# Log the purge itself (if log-event script is available)
if [ -x /opt/data/skills/superpowers/scripts/superpowers-log-event.sh ]; then
  /opt/data/skills/superpowers/scripts/superpowers-log-event.sh \
    "gate-events-purge" "applied" "" "" \
    "{\"days\": ${DAYS}, \"removed\": ${removed}, \"kept\": ${after}}" \
    || true  # don't fail purge if log fails
fi
