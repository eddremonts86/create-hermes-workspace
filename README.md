# create-hermes-workspace

[![npm version](https://img.shields.io/npm/v/@edd_remonts/create-hermes-workspace.svg)](https://www.npmjs.com/package/@edd_remonts/create-hermes-workspace)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Docker](https://img.shields.io/badge/docker-required-blue.svg)](https://www.docker.com)
[![Node ≥ 18](https://img.shields.io/badge/node-%E2%89%A518-brightgreen.svg)](https://nodejs.org)
[![Base image: hermes-agent](https://img.shields.io/badge/base-nousresearch%2Fhermes--agent-purple.svg)](https://github.com/nousresearch/hermes-agent)
[![last commit](https://img.shields.io/github/last-commit/eddremonts86/create-hermes-workspace.svg)](https://github.com/eddremonts86/create-hermes-workspace/commits/main)

> One-command bootstrap for a full [Hermes Agent](https://github.com/nousresearch/hermes-agent) workspace. Clones, configures, and starts the container in under 60 seconds.

## Contents

- [What is this?](#what-is-this)
- [5-second quickstart](#5-second-quickstart)
- [What you get](#what-you-get)
- [How the workspace works](#how-the-workspace-works)
- [How do I create my first app?](#how-do-i-create-my-first-app)
- [Configuration](#configuration)
- [Prerequisites](#prerequisites)
- [Detailed install](#detailed-install)
- [Updating](#updating)
- [Uninstall](#uninstall)
- [FAQ](#faq)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgements](#acknowledgements)

---

## What is this?

This repo is the **canonical scaffold for a Hermes Agent workspace** — the dev environment you run on your machine to talk to a powerful AI agent that has access to your files, shell, browser, and a curated set of skills. Think of it as "an opinionated home for an AI coworker."

The companion npm package — [`@edd_remonts/create-hermes-workspace`](https://www.npmjs.com/package/@edd_remonts/create-hermes-workspace) — clones this repo into a folder of your choice and prints "what to do next."

If you've ever wished for `npx create-react-app` but for an AI-first dev environment: this is that.

---

## 5-second quickstart

```bash
# 1. Get the code
npx @edd_remonts/create-hermes-workspace my-workspace
cd my-workspace

# 2. Fill in your AI provider keys (at minimum: one of MINIMAX_API_KEY, OPENAI_API_KEY, ANTHROPIC_API_KEY)
$EDITOR .env

# 3. Start the container
docker compose up -d

# 4. Open a shell inside
docker compose exec hermes bash

# 5. Talk to the agent
hermes chat
```

That's it. You now have a fully working AI agent with skills, project scaffolding, and a reproducible config.

---

## What you get

```
my-workspace/
├── Dockerfile                      # FROM nousresearch/hermes-agent:latest
├── docker-compose.yml              # host network, /opt/data volume
├── .env.example                    # annotated, only the keys you must set
├── .gitignore                      # Node + Docker + secrets exclusions
├── AGENTS.md                       # the agent's workflow rules
├── Makefile                        # up / shell / new-project / reset
├── README.md                       # ← you are here
├── scripts/
│   ├── bootstrap.sh                # non-Docker one-shot installer
│   └── publish.sh                  # re-publish wrapper for the npm package
├── skills/                         # curated public-safe skills (see below)
│   ├── edd-app-template/
│   ├── superpowers/
│   ├── ailab/
│   ├── github/
│   ├── software-development/
│   └── hermes-skill-enforcement/
└── docs/                           # extra reading (links, screenshots, etc.)
```

**Total size:** ~1.5 MB of source (most of it in `skills/`). No `node_modules`, no DB, no secrets — those live in your `.env` and the running container.

---

## How the workspace works

A Hermes workspace is a **containerised dev environment with an AI agent at its core.** The agent has access to:

| Capability | How |
|------------|-----|
| **Filesystem** | The container mounts `./` (or your chosen folder) as `/opt/data`. The agent can read, write, and edit any file inside. |
| **Shell** | The agent can run any command inside the container. Useful for `git`, `pnpm`, `docker exec`, `curl`, `make`, etc. |
| **Browser** | A headless browser is available for web research, screenshots, and form-filling. |
| **Skills** | Reusable playbooks the agent loads on demand. See the next section. |
| **Memories** | Persistent notes the agent writes about you and your preferences. Lives in `memories/`. |
| **Cron jobs** | Scheduled prompts that run the agent on a timer. Lives in `cron/`. |

### The `AGENTS.md` contract

`AGENTS.md` is the rulebook the agent reads on every session. It enforces a methodology called **superpowers** — a strict four-gate workflow:

1. **Brainstorm** — no code without a written, approved design.
2. **Plan** — no implementation without a written, approved plan.
3. **TDD** — no production code without a failing test first.
4. **Verify** — no "done" without running the tests and showing evidence.

These gates exist because misalignment costs days; following them costs minutes. The agent will load the right skill automatically when you ask for any of these activities. You can override or extend the rules by editing `AGENTS.md` directly.

### Skills (what's in the box)

Six curated, public-safe skill directories ship in `skills/`:

| Skill | What it's for |
|-------|---------------|
| `edd-app-template/` | The default scaffold for new apps in this workspace. When you say "make me a new app," this is what the agent loads. |
| `superpowers/` | The full superpowers methodology (brainstorming, planning, TDD, code review, debugging, etc.). |
| `ailab/` | Integration with [AI-Lab Yonder](https://github.com/AI-Lab-Yonder) — adversarial bug hunting, docs generation, code review, postmortems, autoresearch. |
| `github/` | `gh` CLI workflows — PRs, issues, repo management, code review. |
| `software-development/` | TDD discipline, debugging methodology, code review checklists, plan / spike workflows. |
| `hermes-skill-enforcement/` | The mandatory skill-loading rules that prevent the agent from improvising. |

> **Why only six?** Personal skill directories (the ones in the author's full workspace) reference private repos, cron jobs, and gateway tokens. Sharing those by accident would be a security incident. The curated subset is the safe-and-useful 80%.

### What's NOT in the box (and how to add it)

The following are **not** in the public repo because they're personal:

- `creative/` — the author's design / art projects.
- `research/` — paper-discovery and market-data tools tied to personal workflows.
- `productivity/` — Notion, Airtable, Google Workspace scripts.
- `mlops/` — model training and serving infra.
- `figma/`, `email/`, `note-taking/`, `smart-home/`, `social-media/`, `yuanbao/` — gateway configs.

To add your own: drop a new folder into `skills/<name>/SKILL.md` following the [skill authoring guide](https://github.com/nousresearch/hermes-agent/blob/main/docs/skill-authoring.md). The agent will pick it up on the next session.

---

## How do I create my first app?

A "workspace" hosts many "apps." Each app is its own project, scaffolded from a template. The default template is the author's opinionated stack: **TanStack Start + Drizzle + shadcn/ui**.

```bash
# Inside the workspace container
docker compose exec hermes bash
make new-project NAME=my-saas-idea
# → runs `npx @edd_remonts/create-edd-app my-saas-idea --package-manager pnpm`
# → cd my-saas-idea
# → pnpm install
# → pnpm dev   # http://localhost:3000
```

The new app lives in a sibling folder to your workspace. Both are independent git repos; you commit and push each separately.

**Prefer a different stack?** Skip the template and `git init` your own folder. The workspace doesn't care.

---

## Configuration

Configuration lives in `.env` (copied from `.env.example` on first run). The full annotated list:

### Required (at least one)

| Variable | What | Where to get it |
|----------|------|-----------------|
| `MINIMAX_API_KEY` | Primary LLM provider (MiniMax). Optional but recommended. | https://api.minimax.io/ |
| `OPENAI_API_KEY` | Fallback LLM. | https://platform.openai.com/api-keys |
| `ANTHROPIC_API_KEY` | Fallback LLM. | https://console.anthropic.com/ |

The agent picks the first one that's set. Add as many fallbacks as you like.

### Container user (recommended)

| Variable | Default | What |
|----------|---------|------|
| `HERMES_UID` | `1000` | UID the container runs as (so files on the host stay owned by you). |
| `HERMES_GID` | `1000` | GID the container runs as. |

Run `id -u` and `id -g` on the host to find your values.

### GitHub integration (optional)

| Variable | What |
|----------|------|
| `GITHUB_USER` | Your GitHub username. Used by `make worktree-push` and similar targets. |

### Application (optional)

| Variable | Default | What |
|----------|---------|------|
| `APP_URL` | `http://localhost:3000` | Public base URL (auth redirects, webhooks). |
| `PORT` | `3000` | Port the agent's web UI listens on. |

### Observability (optional, all commented out by default)

| Variable | What |
|----------|------|
| `SENTRY_DSN` | Error reporting. Get one at https://sentry.io. |
| `LOG_LEVEL` | `debug` / `info` / `warn` / `error`. Default: `info`. |

### Gateway integrations (all optional, commented out)

| Variable | What |
|----------|------|
| `TELEGRAM_BOT_TOKEN` | Talk to the agent from Telegram. |
| `DISCORD_BOT_TOKEN` | Talk to the agent from Discord. |
| `SLACK_BOT_TOKEN` | Talk to the agent from Slack. |
| `MATRIX_ACCESS_TOKEN` | Talk to the agent from Matrix. |

### Things you do NOT need to set

The container's base image provides sane defaults for the long-tail of runtime flags (browser timeouts, terminal lifetimes, vision debug flags, etc.). Don't copy those from someone else's `.env` — they're image-version-specific and the defaults evolve.

---

## Prerequisites

| Tool | Min version | How to check | Install |
|------|-------------|--------------|---------|
| **Docker** | 24+ | `docker --version` | https://docs.docker.com/get-docker/ |
| **Docker Compose** | v2 (bundled with Docker Desktop) | `docker compose version` | bundled |
| **Node.js** | 18+ | `node --version` | https://nodejs.org |
| **Git** | 2.30+ | `git --version` | https://git-scm.com |
| **SSH key on GitHub** | — | `ssh -T git@github.com` | https://docs.github.com/en/authentication/connecting-to-github-with-ssh |

Test the GitHub SSH connection **before** running the CLI:

```bash
$ ssh -T git@github.com
Hi eddremonts86! You've successfully authenticated, but GitHub does not provide shell access.
```

If that says "Permission denied (publickey)", follow the [GitHub SSH setup guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh).

---

## Detailed install

### Path A — Docker (recommended)

The Docker path is what `make up` does. It's the only path that gives you reproducible builds and a clean host machine.

```bash
# 1. Clone (or use the npm CLI)
npx @edd_remonts/create-hermes-workspace my-workspace
cd my-workspace

# 2. Edit .env
$EDITOR .env
# At minimum, set ONE of:
#   MINIMAX_API_KEY=...
#   OPENAI_API_KEY=...
#   ANTHROPIC_API_KEY=...

# 3. Build & start (first run takes a few minutes; subsequent runs are seconds)
docker compose up -d

# 4. Verify
docker compose ps                # should show 'hermes' running
docker compose logs --tail 50    # should show "agent ready"

# 5. Open a shell
docker compose exec hermes bash

# 6. Talk to the agent
hermes chat
```

### Path B — Non-Docker (advanced / Termux)

If you can't or don't want to use Docker (e.g. on Android via Termux, or a server without Docker), use `scripts/bootstrap.sh`:

```bash
git clone https://github.com/eddremonts86/create-hermes-workspace my-workspace
cd my-workspace
cp .env.example .env
$EDITOR .env
./scripts/bootstrap.sh
```

The script detects your platform, installs the right Python tooling (`uv` on desktop, stdlib `venv` on Termux), and symlinks `hermes` to `~/.local/bin/`.

### Path C — Custom mount point

By default the container mounts `./` to `/opt/data`. If you want the agent to see a different folder (e.g. your entire `~/code` directory), edit `docker-compose.yml`:

```yaml
volumes:
  - /home/you/code:/opt/data
```

After changing the mount, restart with `docker compose down && docker compose up -d`.

### Troubleshooting

**"Cannot connect to the Docker daemon"** — start Docker Desktop (or `sudo systemctl start docker` on Linux).

**"port is already allocated"** — something else on the host is using the agent's port. Edit `docker-compose.yml` and change the `ports:` mapping.

**"agent ready" never appears in the logs** — run with `docker compose logs -f` to see live output. Common causes: missing API key in `.env`, invalid `HERMES_UID`/`HERMES_GID`.

**"Permission denied" when the agent writes files** — your `HERMES_UID`/`HERMES_GID` don't match the host user. Run `id` on the host, set the values in `.env`, and `docker compose down && docker compose up -d`.

**"Out of disk space"** — Docker images accumulate. Prune: `docker system prune -a --volumes`.

---

## Updating

The workspace is a git repo. Pull the latest:

```bash
git pull origin main
```

If a new container image is required (e.g. the base `nousresearch/hermes-agent` got a major version bump), rebuild:

```bash
docker compose down
docker compose build --pull
docker compose up -d
```

If something goes wrong, nuke and restart:

```bash
make reset   # equivalent to: docker compose down -v && rm -rf .env node_modules
# Then re-run the quickstart from step 2.
```

---

## Uninstall

```bash
# Inside the workspace folder
docker compose down -v
cd ..
rm -rf my-workspace
```

That's it. The image is also removed by `docker compose down --rmi all` if you want to be thorough.

---

## FAQ

**Q: I have a "Permission denied (publickey)" error during `git clone`.**
A: The npm CLI uses SSH. Set up an SSH key on GitHub: https://docs.github.com/en/authentication/connecting-to-github-with-ssh. Or clone the repo manually with HTTPS first, then re-run the CLI.

**Q: Can I run this on Windows?**
A: Yes — install [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) (Windows Subsystem for Linux) and run the CLI from inside your WSL distribution. Docker Desktop's WSL2 backend handles the container. Native PowerShell works for the `git clone` but the full path through Docker Desktop + WSL2 is the supported route.

**Q: How is this different from `@edd_remonts/create-edd-app`?**
A: They solve different problems:
- **`@edd_remonts/create-hermes-workspace` (this repo's npm twin)** → **the dev environment**: agent, skills, Dockerfile, env config. One per machine.
- **`@edd_remonts/create-edd-app`** → **a single application**: TanStack Start + Drizzle + shadcn stack. One per project.

You'll usually run `create-hermes-workspace` once per machine, then run `create-edd-app` many times inside it.

**Q: How is this different from the upstream `nousresearch/hermes-agent` Docker image?**
A: The upstream image is the **runtime** — the agent binary, the Python deps, the gateway. This repo adds the **scaffolding on top**: opinionated `AGENTS.md`, curated `skills/`, a working `Makefile`, a `.env.example` a colleague can fill in, and a clear "this is how you use a workspace" README. Think of upstream as a fresh Ubuntu install and this repo as a dotfiles repo with a setup script.

**Q: Why isn't every skill included?**
A: Some skills reference personal cron jobs, gateway tokens, and private repo URLs. Sharing those by accident would be a security incident. The curated subset (6 skills, ~1.5 MB) is the safe-and-useful 80%. If you want a specific one, open an issue and we'll consider adding it.

**Q: Can I add my own skills?**
A: Yes. Create `skills/<name>/SKILL.md` following the [skill authoring guide](https://github.com/nousresearch/hermes-agent/blob/main/docs/skill-authoring.md). The agent picks it up on the next session.

**Q: Can I publish a new version of the npm package?**
A: Yes. Inside this repo (after cloning), run `./scripts/publish.sh` (with `NPM_TOKEN` set in your environment, or in `~/.hermes-secrets/npm-token.txt`). It auto-bumps the patch version and pushes to npm.

**Q: My team wants to fork this. Is that OK?**
A: Yes — MIT licensed. Fork it, change the AGENTS.md to your conventions, swap the skills for your team's, and push. We'd appreciate a heads-up in the issues, but it's not required.

**Q: Is telemetry collected?**
A: No. The agent makes whatever network calls you ask it to (LLM APIs, web requests, etc.), but neither the workspace scaffolding nor the CLI does any phone-home.

---

## Contributing

Issues and PRs are welcome. The fastest way to get a feature in:

1. Open an issue describing what you want and why.
2. Fork this repo, make your change on a branch.
3. Open a PR. CI runs `markdownlint` and a smoke test.
4. A maintainer reviews within a few days.

For skills, the bar is "would a stranger find this useful and safe?" If yes, send the PR.

---

## License

MIT © 2026 Eduardo Inerarte. See [LICENSE](./LICENSE) for the full text.

---

## Acknowledgements

- [Nous Research](https://nousresearch.com) for the underlying [Hermes Agent](https://github.com/nousresearch/hermes-agent) — the engine that makes all this possible.
- [obra](https://github.com/obra) for the [superpowers](https://github.com/obra/superpowers) methodology that the agent enforces.
- [AI-Lab Yonder](https://github.com/AI-Lab-Yonder) for the multi-agent audit / review / postmortem skills.
- Everyone who has shared feedback, filed an issue, or sent a PR.
