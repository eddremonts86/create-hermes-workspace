# Superpowers for Hermes — Installation & Configuration

This directory contains the **full superpowers methodology** ported from
[obra/superpowers](https://github.com/obra/superpowers) v5.1.0, configured
for use inside Hermes Agent with **world-class quality gates** — including
4 self-enforcement mechanisms that the LLM cannot easily skip.

> **The user installed superpowers because they want every creative or
> code-modification request to go through the full pipeline: brainstorm →
> plan → TDD → verification. Skipping the gates is failing the user.**

## What's in here

### 18 superpowers skills + 8 AI-Lab skills = 26 orchestrated skills

The 18 superpowers are the **workflow/methodology** layer. The 8 AI-Lab are
**complementary task skills** for company projects. Both are loaded through
`superpowers-skill-routing` with disambiguation.

#### 4 orchestrators (NEW — written for Hermes)

| Skill | Purpose |
|---|---|
| `superpowers-skill-routing` | **Load on every session start.** Compact 1-page routing table. |
| `superpowers-triage` | **ULTRA-FAST 1-step classifier.** Drop-in replacement for routing when you want speed. |
| `superpowers-creative-workflow` | **Master gate for any build/creation request.** Chains brainstorm → plan → TDD → verify. |
| `superpowers-code-workflow` | **Master gate for any fix/modification request.** Routes to debug or modify flow. |

#### 14 original superpowers skills (ported from obra/superpowers v5.1.0)

| Skill | Purpose |
|---|---|
| `superpowers-using-superpowers` | Bootstrap for skill discovery (loaded by routing). |
| `superpowers-brainstorming` | Gate 1: written design before any code. |
| `superpowers-writing-plans` | Gate 2: bite-sized plan with file paths and verification. |
| `superpowers-executing-plans` | Step-by-step execution of an approved plan. |
| `superpowers-test-driven-development` | Gate 3: failing test before production code. |
| `superpowers-systematic-debugging` | 4-phase root-cause debugging. |
| `superpowers-verification-before-completion` | Gate 4: evidence before "done". |
| `superpowers-requesting-code-review` | Gate 5: self-review before commit. |
| `superpowers-receiving-code-review` | How to respond to PR feedback. |
| `superpowers-dispatching-parallel-agents` | For independent parallel work. |
| `superpowers-subagent-driven-development` | For ordered multi-agent work. |
| `superpowers-using-git-worktrees` | Worktree conventions. |
| `superpowers-writing-skills` | Authoring new skills. |
| `superpowers-finishing-a-development-branch` | Merge / PR / archive the work. |

#### 8 AI-Lab skills (imported from `AI-Lab-Yonder/ai-lab-agent-skills`, chosen for company projects)

| Skill | Use when |
|---|---|
| `ailab-spa-day` | "audit my skills" / interactive audit of contradictions |
| `ailab-adversarial-bug-hunt` | "hunt for bugs" / 3-agent adversarial pipeline |
| `ailab-pre-merge-review` | "review before merge" / multi-phase pipeline |
| `ailab-code-reviewer` | "review this PR" / 5-category exhaustive checklist |
| `ailab-postmortem` | "capture this lesson" / gotchas.md protocol per skill |
| `ailab-autoresearch` | "optimize this skill" / auto-eval loops (Karpathy-style) |
| `ailab-docs-generator` | "generate docs from code" |
| `ailab-multi-agent-orchestrator` | "coordinate agents" / multi-agent coordination |

**Why only 8 of 25?** The other 17 are redundant with the 14 superpowers
above or with the edd-app-template default stack. Importing them would create
5+ skills saying "I'll debug this for you" and confuse the LLM's routing.
See `docs/superpowers/specs/2026-06-05-ailab-skills-integration-design.md`
for the full skip-keep matrix.

See `/opt/data/skills/ailab/SKILL.md` for the routing disambiguation table
(when to use `ailab-*` vs `superpowers-*`).

### 2 enforcement layers

#### Layer 1: HARD GATEs in each critical skill

Each of the 11 critical skills has a `## ⚡ HERMES ENFORCEMENT (additive to upstream)` block
that contains:

- The full routing/trigger instructions
- A **non-negotiable rule** stated in absolute terms
- An **anti-rationalization table** (10+ rows) covering every excuse
- A **failure mode** description

These blocks are written to be impossible to rationalize past. If the
model loads the skill, the gates are loaded with it.

#### Layer 2: Global AGENTS.md

`/opt/data/AGENTS.md` is automatically injected into the system prompt of
every Hermes session (CLI, Telegram, Discord, etc.) whose cwd is under
`/opt/data/`. It contains:

- The 4 mandatory skill loading rules
- The **6** hard gates (with "cannot be skipped because" justification)
- The "announce then act" protocol
- The "self-correct visibly" rule
- The full skill discovery table
- The `sp-commit` non-negotiable commit rule

### 5 self-enforcement mechanisms (the LLM cannot easily skip them)

These were added across 2 passes (June 2026) to close every escape hatch
the model could otherwise rationalize.

| # | Mechanism | File | What it stops |
|---|---|---|---|
| 1 | **Weekly audit cron job** | `cron job: superpowers-weekly-audit` | Drift / silent breakage of AGENTS.md or skills. Runs every Monday 09:00 via Hermes `cronjob` tool. |
| 2 | **`sp-commit` wrapper** | `~/.local/bin/sp-commit` + AGENTS.md Gate 6 | Direct `git commit` bypassing the self-review checklist. Hard rule: never use `git commit` in a worktree, use `sp-commit`. |
| 3 | **`superpowers-triage` skill** | `superpowers-triage/SKILL.md` | Over-classification ceremony on simple messages. Single-pass intent detection. |
| 4 | **Husky pre-commit guard** | `.husky/pre-commit-superpowers` (installed via `install-precommit-guard.sh`) | Bad commits landing: secrets, debug code, oversized diffs. Runs BEFORE every commit. |
| 5 | **Security audit** (gitleaks+shellcheck+bandit+semgrep) | `superpowers-security-scan.sh` | Leaked secrets, bash injection, python vulns, OWASP patterns. Pre-commit blocks when skills/scripts touched; weekly cron reports (Monday 10:00). |

All four work together. Removing any one leaves a gap the others don't cover.

## How it works in practice

### A creative request

```
User: "crea una app de tareas"
```

1. AGENTS.md loads, injects the 4 rules.
2. Model reads AGENTS.md Rule 1: "On first user turn, load superpowers-skill-routing."
3. Model loads `superpowers-skill-routing`, sees "Build/create/design → superpowers-creative-workflow."
4. Model loads `superpowers-creative-workflow`.
5. Model announces: "Using superpowers-creative-workflow to gate this build through brainstorming → design → plan → TDD → verification."
6. Model loads `superpowers-brainstorming`, starts asking one question at a time.
7. After design approval → loads `superpowers-writing-plans`.
8. After plan approval → loads `superpowers-test-driven-development`.
9. After each task → loads `superpowers-requesting-code-review` before commit.
10. After all tasks → loads `superpowers-verification-before-completion`.
11. After merge → loads `superpowers-finishing-a-development-branch`.

### A bug fix request

```
User: "arregla el bug del login"
```

1. AGENTS.md → load `superpowers-skill-routing`.
2. Routing → load `superpowers-code-workflow` (fix keywords).
3. Code-workflow → route to Flow A (debugging) → load `superpowers-systematic-debugging`.
4. Root cause found, regression test written → load `superpowers-test-driven-development`.
5. Fix applied, tests pass → load `superpowers-verification-before-completion`.
6. Evidence shown → load `superpowers-requesting-code-review` for the commit.

### A pure Q&A (no gates)

```
User: "¿qué es el TDD?"
```

1. AGENTS.md → load `superpowers-skill-routing`.
2. Routing → no skill (Q&A).
3. Model announces: "Skipping superpowers — pure Q&A."
4. Model answers.

## Verification

The routing was tested with 16 examples (9 creative, 7 non-creative), all
correctly classified. The AGENTS.md injection was verified to load
without being blocked by the prompt-injection scanner.

## Files in this directory

```
superpowers/
├── SKILL.md                                          # Index of all 18 skills
├── INSTALLATION.md                                   # This file
├── AGENTS.md (mirror at /opt/data/AGENTS.md)         # Bootstrap rules
├── scripts/
│   ├── sync-from-upstream.sh                         # Refresh from obra/superpowers
│   ├── superpowers-self-check.sh                     # Weekly audit (cron)
│   ├── superpowers-precommit-guard.sh                # Husky pre-commit hook
│   ├── superpowers-security-scan.sh                  # Security audit (cron + pre-commit)
│   ├── superpowers-log-event.sh                      # Append a gate event to JSONL
│   ├── superpowers-stats                             # Query gate-events JSONL (summary|recent|skipped)
│   ├── superpowers-purge.sh                          # Monthly: remove events >30d
│   └── install-precommit-guard.sh                    # Installer for the hook
├── superpowers-skill-routing/                         # Bootstrap routing table
├── superpowers-triage/                                # Ultra-fast 1-step classifier
├── superpowers-creative-workflow/                     # Creative orchestrator
├── superpowers-code-workflow/                         # Code orchestrator
├── superpowers-using-superpowers/                     # Skill discovery
├── superpowers-brainstorming/                         # Gate 1
├── superpowers-writing-plans/                         # Gate 2
├── superpowers-executing-plans/                       # Plan execution
├── superpowers-test-driven-development/               # Gate 3
├── superpowers-systematic-debugging/                  # Debugging
├── superpowers-verification-before-completion/        # Gate 4
├── superpowers-requesting-code-review/                # Gate 5
├── superpowers-receiving-code-review/                 # PR feedback
├── superpowers-dispatching-parallel-agents/           # Parallel work
├── superpowers-subagent-driven-development/          # Ordered work
├── superpowers-using-git-worktrees/                   # Worktrees
├── superpowers-writing-skills/                        # Author skills
└── superpowers-finishing-a-development-branch/        # Merge/PR

../ailab/                                             # Sibling namespace (separate dir)
├── SKILL.md                                           # ailab namespace index
├── ailab-spa-day/                                     # Interactive audit
├── ailab-adversarial-bug-hunt/                        # 3-agent adversarial
├── ailab-pre-merge-review/                            # Multi-phase pre-merge
├── ailab-code-reviewer/                               # 5-category review
├── ailab-postmortem/                                  # gotchas.md protocol
├── ailab-autoresearch/                                # Skill auto-optimization
├── ailab-docs-generator/                              # Docs from code
└── ailab-multi-agent-orchestrator/                    # Multi-agent coordination

/var/gate-events.jsonl                                 # Gate metrics log (auto-created)
```

## Updating from upstream

```bash
~/.hermes/skills/superpowers/scripts/sync-from-upstream.sh
```

This:
1. Clones the latest `obra/superpowers` to a temp dir.
2. Replaces the 14 per-skill subdirs.
3. Re-applies the Hermes frontmatter extension + port notice.
4. Preserves the 4 orchestrators (which are Hermes-specific).
5. Re-applies the 11 `## ⚡ HERMES ENFORCEMENT` blocks (additive to upstream).

## Gate metrics (gate-skipping visibility)

The system instruments the 7 superpowers gates (per `AGENTS.md`) and writes
every application or skip to a JSONL log. This makes the enforcement layer
**auditable**, not just aspirational.

### Location
`/opt/data/var/gate-events.jsonl` — append-only, one JSON event per line.

### Event schema
```json
{
  "ts": "2026-06-05T10:42:31Z",
  "session_id": "20260605_111332_9a9e13",
  "gate": "sp-commit-wrapper",
  "gate_num": 5,
  "action": "applied" | "confirmed" | "aborted" | "loaded" | "missing" | "skipped" | "attempted",
  "skill": "superpowers-skill-routing",
  "duration_ms": 1234,
  "metadata": { "first_arg": "-m" }
}
```

### Which gates are tracked

| # | Gate | How it logs |
|---|---|---|
| 1 | Bootstrap routing | `self-check.sh` weekly: `applied` if `AGENTS.md` exists |
| 2 | HARD GATEs list | `self-check.sh` weekly: `applied` if all 18 skills present |
| 3 | Announce-then-act | `self-check.sh` weekly: greps AGENTS.md for "announce" |
| 4 | Rule 2 (gates) | `self-check.sh` weekly: greps AGENTS.md for "Rule 2" |
| 5 | `sp-commit` wrapper | `sp-commit` real-time: `applied` when invoked |
| 6 | sp-commit confirm | `sp-commit` real-time: `confirmed` / `aborted` / `skipped` (with SP_COMMIT_SKIP=1) |
| 7 | ailab routing | `self-check.sh` weekly: greps routing SKILL.md for "ailab" |

### How to query

```bash
# Summary table: counts per gate, all actions
/opt/data/skills/superpowers/scripts/superpowers-stats summary

# Last 20 events, newest first
/opt/data/skills/superpowers/scripts/superpowers-stats recent

# Only events that are "skipped" or "attempted" (signal of gate-skipping)
/opt/data/skills/superpowers/scripts/superpowers-stats skipped
```

All three commands output markdown tables, pipeable to `head`, `grep`, `less`.

### Retention

- **30 days** by default. The monthly cron (`superpowers-monthly-purge`,
  1st of each month at 04:00) runs `superpowers-purge.sh 30`.
- Manual purge: `bash /opt/data/skills/superpowers/scripts/superpowers-purge.sh [N]`
- The purge event itself is logged (`gate-events-purge` action=`applied`).

### Privacy guarantees

Events contain **only**:
- ISO timestamp, session_id, gate name, action enum, optional skill name, optional duration
- Generic metadata (e.g., `args_count`, `first_arg` truncated to 80 chars)

Events **never** contain:
- File contents, file diffs, code snippets
- Absolute paths outside `/opt/data`
- LLM messages, prompts, responses
- Secrets of any kind

## Post-install setup checklist

After cloning or syncing, run these once per machine:

```bash
# 1. Verify install health
bash ~/.hermes/skills/superpowers/scripts/superpowers-self-check.sh

# 2. Install sp-commit wrapper (the commit gate)
mkdir -p ~/.local/bin
cp ~/.hermes/skills/superpowers/scripts/sp-commit ~/.local/bin/  # (see AGENTS.md)
chmod +x ~/.local/bin/sp-commit
# Add `export PATH="$HOME/.local/bin:$PATH"` to ~/.bashrc

# 3. Install husky guard in any worktree
cd ~/worktree/<your-project>
~/.hermes/skills/superpowers/scripts/install-precommit-guard.sh .

# 4. Create the weekly audit cron jobs (via Hermes cronjob tool)
#    self-check  schedule: "0 9 * * 1"   Prompt: run superpowers-self-check.sh
#    security    schedule: "0 10 * * 1"  Prompt: run superpowers-security-scan.sh

# 5. Install security tools (optional but recommended for the security audit)
#    gitleaks (binary):  see https://github.com/gitleaks/gitleaks/releases
#    shellcheck (binary): see https://github.com/koalaman/shellcheck/releases
#    bandit (uv):        uv tool install bandit
#    semgrep (uv):       uv tool install semgrep
#    jq (binary):        see https://github.com/jqlang/jq/releases
#    All go in ~/.local/bin which is already in PATH (step 2).
#    Verify with:
bash ~/.local/bin/../tests/security/verify-tools.sh 2>/dev/null \
  || bash /opt/data/tests/security/verify-tools.sh
```

All 5 steps are idempotent and safe to re-run.

## What the security audit catches

| Tool | Severity that blocks | What it detects |
|---|---|---|
| gitleaks | any leak | API keys, tokens, passwords, AWS/GitHub/Slack/Stripe/etc. |
| shellcheck | level=error | Bash bugs: word splitting, command injection, quoting issues |
| bandit | issue_severity=HIGH | Python vulns: B602 shell=True, B605 start process, hardcoded creds |
| semgrep | severity=ERROR | OWASP Top 10 patterns in JS/TS/Python/Bash |

False positives are tolerable. False negatives are dangerous. Default to blocking.

## License

MIT. Original © Jesse Vincent, port + enforcement layer © 2026 Hermes Agent / the user.
