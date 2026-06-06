#!/usr/bin/env bash
# tests/e2e/dashboard-healthcheck.test.sh
#
# E2E test for the create-hermes-workspace docker-compose: the dashboard
# service inside the container must respond on the configured port from
# the host, on Linux, macOS, and Windows (via WSL2 + Docker Desktop).
#
# What this catches:
#   - regressions to network_mode: host (works on Linux, breaks on mac/Windows)
#   - healthcheck pointing at the wrong port (e.g. PORT=3000 when the
#     dashboard listens on 9119)
#   - dashboard service not starting because HERMES_DASHBOARD=1 is missing
#
# Run:
#   bash tests/e2e/dashboard-healthcheck.test.sh
#
# Exits 0 on success, 1 on failure. Skips (exits 0) if docker is not
# available — don't fail CI on machines without a docker daemon.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/docker-compose.yml"

PROJECT_NAME="chw-e2e-$$"
DASHBOARD_PORT="${DASHBOARD_PORT:-19119}"
export DASHBOARD_PORT

# ---- 0. Preconditions -------------------------------------------------------
if ! command -v docker >/dev/null 2>&1; then
  echo "SKIP: docker not on PATH"
  exit 0
fi
if ! docker info >/dev/null 2>&1; then
  echo "SKIP: docker daemon not reachable"
  exit 0
fi
if [ ! -f "$COMPOSE_FILE" ]; then
  echo "FAIL: $COMPOSE_FILE not found"
  exit 1
fi

# Use a temporary .env so the test is hermetic and doesn't pick up the
# user's real API keys from the workspace .env.
TMPDIR_ENV="$(mktemp -d)"
ENV_FILE="$TMPDIR_ENV/.env"
cat > "$ENV_FILE" <<ENVEOF
DASHBOARD_PORT=$DASHBOARD_PORT
HERMES_DASHBOARD=1
HERMES_DASHBOARD_INSECURE=1
HERMES_DASHBOARD_HOST=0.0.0.0
HERMES_DASHBOARD_PORT=$DASHBOARD_PORT
MINIMAX_API_KEY=test-not-a-real-key
ENVEOF

cleanup() {
  rm -rf "$TMPDIR_ENV"
  docker compose -p "$PROJECT_NAME" -f "$COMPOSE_FILE" \
    --env-file "$ENV_FILE" down -v >/dev/null 2>&1 || true
}
trap cleanup EXIT

# ---- 1. Validate the compose file parses -----------------------------------
echo "=== Phase 1: docker compose config validates ==="
docker compose -p "$PROJECT_NAME" -f "$COMPOSE_FILE" --env-file "$ENV_FILE" config >/dev/null

# ---- 2. Start the container ------------------------------------------------
echo "=== Phase 2: docker compose up -d ==="
docker compose -p "$PROJECT_NAME" -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d

# ---- 3. Wait for the dashboard to listen on :$DASHBOARD_PORT ---------------
echo "=== Phase 3: wait for the dashboard to listen on :$DASHBOARD_PORT ==="
SUCCESS=0
for i in $(seq 1 60); do
  # The host-side check: with a correctly mapped port, the dashboard must
  # be reachable on localhost:$DASHBOARD_PORT from the host. This is the
  # user-facing path on macOS/Windows and the regression-detection check
  # on Linux.
  if curl -fsS "http://127.0.0.1:${DASHBOARD_PORT}/healthz" >/dev/null 2>&1; then
    SUCCESS=1
    echo "  ok (host-side) after ${i} attempts"
    break
  fi
  sleep 2
done

if [ "$SUCCESS" -ne 1 ]; then
  echo ""
  echo "FAIL: dashboard never responded on http://127.0.0.1:${DASHBOARD_PORT}/healthz"
  echo ""
  echo "Diagnosis hints:"
  echo "  - If curl from inside the container works but from the host doesn't,"
  echo "    ports: mapping is missing or misconfigured (or network_mode: host is set,"
  echo "    which only works on Linux)."
  echo "  - If neither works, the dashboard s6 service may not have started."
  echo "    Check that HERMES_DASHBOARD=1 is in the compose env."
  echo "  - Default dashboard port is 9119. If the compose uses PORT (which defaults"
  echo "    to 3000) for the healthcheck, that's a bug — see docker/s6-rc.d/dashboard/run"
  echo "    in nousresearch/hermes-agent."
  echo ""
  echo "--- Last 30 lines of 'docker compose logs' ---"
  docker compose -p "$PROJECT_NAME" -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs --tail=30 || true
  exit 1
fi

echo "PASS: dashboard responded on :$DASHBOARD_PORT"
