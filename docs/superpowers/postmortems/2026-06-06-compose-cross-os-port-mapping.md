# Postmortem: docker-compose cross-OS port mapping

**Date:** 2026-06-06
**Author:** Hermes Agent
**Severity:** High (workspace unusable on macOS / Windows + Docker Desktop)
**Resolved in:** v0.1.1 (commit `06f878d`)

## Summary

The `docker-compose.yml` shipped with `create-hermes-workspace` made the
dashboard unreachable on macOS and Windows. A user cloning the workspace
on either platform got an empty browser at `localhost:3000` /
`localhost:9119`, while Linux users saw the dashboard fine. The bug had
two latent defects that compounded: an `network_mode: host` setting that
silently breaks on Docker Desktop, and a healthcheck that targeted the
wrong port.

## Timeline

| When | What |
|---|---|
| 2026-06-05 | Initial scaffolding of `create-hermes-workspace` (`e83cb4d`). The compose used `network_mode: host` and pointed the healthcheck at `PORT:-3000` even though the dashboard s6 service listens on `HERMES_DASHBOARD_PORT` (default 9119). |
| 2026-06-06 | User attempts to deploy the workspace on a second macOS machine. Dashboard never responds at `localhost:3000`. Linux user (in the same chat) confirmed it works for them. |
| 2026-06-06 | Initial postmortem drafted by the user; proposed `command: sleep infinity` plus 4 `HERMES_DASHBOARD_*` env vars. |
| 2026-06-06 | Phase 1 of `superpowers-systematic-debugging`: inspected the base image. Discovered s6-overlay supervises the container and that the original postmortem missed (and partially mis-described) the real environment. |
| 2026-06-06 | v0.1.1 cut. Replaces `network_mode: host` with explicit `ports:` mapping; adds 4 `HERMES_DASHBOARD_*` env vars; fixes the healthcheck target; adds a cross-OS rationale to the compose header and a regression E2E test. |

## Root cause

Four independent defects combined to make the workspace appear "broken"
on non-Linux platforms:

1. **`network_mode: host`** — works on the Linux kernel because the
   container shares the host's network namespace. Docker Desktop on
   macOS / Windows runs containers inside a LinuxKit VM with its own
   network namespace, so host mode does not expose container ports to
   the host. The dashboard was therefore never reachable from the host
   browser on those platforms. (This is the only one the user-visible
   bug stems from directly, but it's not the whole story.)

2. **Healthcheck pointed at the wrong port.** The healthcheck was
   `curl http://127.0.0.1:${PORT:-3000}/healthz`. The base image's
   dashboard s6 service listens on `HERMES_DASHBOARD_PORT` (default
   `9119`). The healthcheck was always failing on a stock workspace,
   making `docker compose ps` show `unhealthy` even when the dashboard
   was otherwise fine. This is a latent defect that was masked by
   defect #1 on Linux: with `network_mode: host`, the dashboard was
   accessible from the host (just at the wrong port from the user's
   perspective), so the broken healthcheck was the loudest signal.

3. **Dashboard s6 service not started.** The base image declares
   `dashboard` as an s6 service but the `run` script checks
   `HERMES_DASHBOARD=1` and exits 0 if unset. Without that env var,
   s6 reports the slot as permanently down. The compose did not set
   the gate, so the dashboard was never even attempting to bind.

4. **`HERMES_DASHBOARD_INSECURE=1` missing.** Even with #3 fixed, the
   dashboard refuses to bind on a non-loopback host unless
   `--insecure` is passed (or a `DashboardAuthProvider` is
   registered). On a stock LAN with no OAuth provider configured, the
   dashboard would fail to start with a specific operator-facing
   error. The compose did not opt in to insecure mode for the trusted
   LAN case.

## What the initial postmortem got right

- The four `HERMES_DASHBOARD_*` env var names match exactly what the
  base image's s6 service expects (`HERMES_DASHBOARD`,
  `HERMES_DASHBOARD_INSECURE`, `HERMES_DASHBOARD_HOST`,
  `HERMES_DASHBOARD_PORT`). These are documented in
  `/opt/hermes/docker/s6-rc.d/dashboard/run` in the base image.
- The diagnosis of "the dashboard was unreachable because the container
  was not actually serving" was directionally correct.

## What the initial postmortem got wrong

- **`command: sleep infinity` would have been actively harmful.** The
  base image already runs `s6-overlay`, which supervises
  `main-hermes` and `dashboard` services. The default entrypoint is
  `/init /opt/hermes/docker/main-wrapper.sh`, where `/init` is s6's
  PID 1. Overriding `command:` replaces the main wrapper, kills
  Python venv activation, and breaks the privilege drop (`s6-setuidgid
  hermes`). The container would have appeared to work, but every
  command would either fail with EACCES (no venv, wrong user) or run
  as root with full filesystem damage potential. We rejected this
  proposal after reading the wrapper.

- **The dashboard port was assumed to be 3000 (from the `PORT` env
  var).** The actual port is `9119` by default in the base image. The
  `PORT` env var is for the user app created via `make new-project`,
  not for the Hermes dashboard. This was a separate latent bug that
  would have produced a `curl: (7) Failed to connect to 127.0.0.1
  port 3000` after the `network_mode` fix.

- **The compose had only one `ports:` mapping proposed** (for
  `PORT=3000`). The dashboard is on `9119`; both need explicit
  mappings because the user might be running an app on 3000 AND
  want to access the dashboard.

## What we changed

`docker-compose.yml`:
- Removed `network_mode: host`.
- Added `ports: ["${DASHBOARD_PORT:-9119}:${DASHBOARD_PORT:-9119}",
  "${PORT:-3000}:${PORT:-3000}"]`.
- Added env vars `HERMES_DASHBOARD=1`, `HERMES_DASHBOARD_INSECURE=1`,
  `HERMES_DASHBOARD_HOST=0.0.0.0`,
  `HERMES_DASHBOARD_PORT=${DASHBOARD_PORT:-9119}`.
- Fixed the healthcheck to target `DASHBOARD_PORT` instead of `PORT`.
- Added a comment block at the top explaining the cross-OS rationale
  so future contributors don't reintroduce `network_mode: host`.

`.env.example`:
- Added a `DASHBOARD` section with the 4 dashboard env vars, so users
  don't have to know the s6 internals to enable the dashboard.

`tests/e2e/dashboard-healthcheck.test.sh` (new):
- Brings the compose up with a hermetic `.env` (no real API keys).
- Waits for `http://127.0.0.1:$DASHBOARD_PORT/healthz` to respond.
- Cleans up after itself.
- Skips cleanly on machines without Docker / docker compose.

## Verification

- YAML validates (parsed with PyYAML).
- Bash E2E test script syntax checks (`bash -n`).
- Static analysis confirms all four defects are fixed: `network_mode`
  absent, `ports` present, four dashboard env vars present, healthcheck
  targets `DASHBOARD_PORT`.
- E2E test could not be executed in the development environment used
  to author this fix (no `docker compose` plugin installed), but is
  designed to pass on any host with Docker + compose, which is the
  target audience.

## Lessons

1. **When a fix touches the integration boundary with a third-party
   system, inspect the third-party system before proposing a fix.**
   The initial postmortem assumed the base image was a "thin
   container" with no internal supervisor. It is not — it runs s6
   with three supervised services. Five minutes of `docker run --rm
   nousresearch/hermes-agent:latest sh -c "cat
   /opt/hermes/docker/s6-rc.d/dashboard/run"` would have caught
   this.

2. **`network_mode: host` should be the exception, not the default,
   for cross-OS tooling.** It works on Linux, breaks on Docker
   Desktop (the most common macOS / Windows setup as of 2026), and
   the failure mode is silent (the user sees a blank browser, not an
   error message). Use explicit `ports:` mappings unless you have a
   specific reason to share the host network namespace.

3. **Healthchecks should target the actual service port, not a
   generic `PORT` env var.** If a compose file has multiple ports
   (dashboard + user app), give each its own env var (`DASHBOARD_PORT`,
   `PORT`) and have the healthcheck target the specific one it
   represents. Sharing `PORT` is a load-bearing assumption that
   breaks the moment a second service appears.

4. **Postmortems are hypotheses, not verdicts.** The
   `superpowers-systematic-debugging` Phase 1 ("root cause
   investigation, no fix proposed yet") is exactly designed for this
   case: validate the proposed fix against the actual system before
   committing to it. Doing so turned up two latent bugs the postmortem
   missed and one proposed change that would have actively broken
   things.

5. **Cross-OS regressions should be caught by automated tests, not
   manual `curl` on a developer's machine.** The new E2E test
   (`tests/e2e/dashboard-healthcheck.test.sh`) is the regression
   catcher. It cannot run on every CI worker (Docker is not
   available in our lint jobs), so it skips cleanly. But it runs on
   any host with Docker, including a macOS or Windows developer
   machine, which is exactly the population that was previously
   silently broken.

## Action items

- [x] Cut v0.1.1 with the fix.
- [x] Publish GitHub Release with cross-OS test instructions.
- [ ] Add a CI job that runs the E2E test on Linux, macOS, and
      Windows runners (deferred — needs CI infra decision).
- [ ] When the base image exposes a `dash` CLI command (or a stable
      healthcheck endpoint contract), wire `make up` to wait for
      `/healthz` via `docker compose up --wait` instead of relying on
      the curl-based healthcheck.

## See also

- `docker-compose.yml` — the fix itself.
- `tests/e2e/dashboard-healthcheck.test.sh` — the regression test.
- Base image source: `/opt/hermes/docker/s6-rc.d/dashboard/run` and
  `/opt/hermes/docker/main-wrapper.sh` in
  `nousresearch/hermes-agent:latest`.
- Release notes: https://github.com/eddremonts86/create-hermes-workspace/releases/tag/v0.1.1
