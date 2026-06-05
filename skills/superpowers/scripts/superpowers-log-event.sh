#!/usr/bin/env bash
# superpowers-log-event.sh
# Append a gate event to /opt/data/var/gate-events.jsonl.
#
# Usage:
#   superpowers-log-event.sh <gate> <action> [skill] [duration_ms] [metadata_json]
#
# Examples:
#   superpowers-log-event.sh sp-commit-wrapper applied
#   superpowers-log-event.sh bootstrap-routing loaded superpowers-skill-routing 250
#   superpowers-log-event.sh test-gate applied test-skill 100 '{"k":"v"}'
#
# Privacy: NEVER include file contents, full paths outside /opt/data,
# LLM messages, or secrets in the metadata.
#
# Exit codes:
#   0 = event logged
#   1 = invalid args (missing gate/action, invalid metadata JSON, etc.)

set -uo pipefail

GATE="${1:-}"
ACTION="${2:-}"
SKILL="${3:-}"
DURATION="${4:-}"
META="${5:-{\}}"

LOG_FILE="/opt/data/var/gate-events.jsonl"
SESSION_ID="${HERMES_SESSION_ID:-unknown}"
TS=$(date -u +%FT%TZ)

# Validate gate and action
if [ -z "$GATE" ] || [ -z "$ACTION" ]; then
  printf 'superpowers-log-event: missing gate or action (got: GATE=%q ACTION=%q)\n' "$GATE" "$ACTION" >&2
  exit 1
fi

# Validate metadata is JSON
if ! echo "$META" | jq -e . >/dev/null 2>&1; then
  printf 'superpowers-log-event: invalid JSON metadata: %s\n' "$META" >&2
  exit 1
fi

# Build the event JSON via jq
event=$(jq -c -n \
  --arg ts "$TS" \
  --arg sid "$SESSION_ID" \
  --arg gate "$GATE" \
  --arg action "$ACTION" \
  --arg skill "$SKILL" \
  --arg duration "$DURATION" \
  --argjson meta "$META" \
  '{
    ts: $ts,
    session_id: $sid,
    gate: $gate,
    action: $action
  }
  + (if $skill != "" then {skill: $skill} else {} end)
  + (if $duration != "" then {duration_ms: ($duration|tonumber)} else {} end)
  + {metadata: $meta}')

# Validate own output (defensive)
if ! echo "$event" | jq -e . >/dev/null 2>&1; then
  printf 'superpowers-log-event: failed to build valid JSON\n' >&2
  exit 1
fi

# Create dir + append (append is atomic for small writes on Linux)
mkdir -p "$(dirname "$LOG_FILE")"
printf '%s\n' "$event" >> "$LOG_FILE"
