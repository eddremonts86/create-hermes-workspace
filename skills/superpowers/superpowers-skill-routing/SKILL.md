---
name: superpowers-skill-routing
description: "Compact routing table for the superpowers skill system. Load this skill ONCE per session (during bootstrap) to know which skill to invoke for any user intent. If you load nothing else, load this — it gives you the decision tree."
version: "5.1.0"
author: "Jesse Vincent (obra) + Hermes enforcement"
license: MIT
platforms: [linux, macos]
namespace: superpowers
source: "https://github.com/obra/superpowers"
metadata:
  hermes:
    tags: [superpowers, routing, lookup, decision-tree]
    homepage: "https://github.com/obra/superpowers"
---

# superpowers-skill-routing — the one-page routing table

> **Use this skill during session bootstrap. After you know the user's intent, switch to the specific sub-skill.**

## The complete routing table

| User intent | Load this skill | Why |
|---|---|---|
| "Build / create / design / scaffold a new thing" | `superpowers-creative-workflow` | Master gate. Chains brainstorm → plan → TDD → verify. |
| "Fix / debug / X is broken / doesn't work" | `superpowers-code-workflow` | Master gate for existing code. Routes to debug or modify. |
| "Refactor / clean up / improve existing code" | `superpowers-code-workflow` | Modification flow. |
| "Add a feature to existing project" | `superpowers-creative-workflow` (or `superpowers-brainstorming`) | Treated as creation. |
| "Write / add tests" | `superpowers-test-driven-development` | TDD discipline. |
| "Commit / push / open PR / ship it" | `superpowers-requesting-code-review` → `superpowers-verification-before-completion` → `superpowers-finishing-a-development-branch` | Three-step ship process. |
| "Code review feedback / PR comments" | `superpowers-receiving-code-review` | How to respond to reviews. |
| "Delegate to subagent / parallelize" | `superpowers-dispatching-parallel-agents` (independent) or `superpowers-subagent-driven-development` (ordered) | Two flavors of multi-agent. |
| "Use git worktrees" | `superpowers-using-git-worktrees` | Worktree conventions. |
| "Create a new skill" | `superpowers-writing-skills` | Skill authoring. |
| "Plan something / how should we approach X" | `superpowers-brainstorming` (if intent is creative) or `superpowers-writing-plans` (if intent is implementation) | Distinguish by asking. |
| "Execute this approved plan" | `superpowers-executing-plans` | Step-by-step execution. |
| **AI-Lab intents (8 unique skills, see `/opt/data/skills/ailab/SKILL.md`):** | | |
| "audit my skills" / "spa day" / "find contradictions" | `ailab-spa-day` | Interactive audit. NOT `superpowers-self-check` (that's automatic). |
| "hunt for bugs" / "find bugs" / "bug hunt" | `ailab-adversarial-bug-hunt` | 3-agent pipeline. NOT `superpowers-systematic-debugging` (single agent). |
| "review before merge" / "pre-merge" | `ailab-pre-merge-review` | Multi-phase pipeline. NOT `superpowers-finishing-a-development-branch`. |
| "review this PR" / "audit code" / "code review" | `ailab-code-reviewer` | 5-category checklist. NOT `superpowers-requesting-code-review` (that's for self-review of own commit). |
| "postmortem" / "capture lesson" / "I made a mistake" | `ailab-postmortem` | gotchas.md protocol. NOT `memory` (that's ad-hoc). |
| "optimize this skill" / "autoresearch" | `ailab-autoresearch` | Unique. No superpowers equivalent. |
| "generate docs from code" | `ailab-docs-generator` | Unique. No superpowers equivalent. |
| "coordinate agents" / "multi-agent" | `ailab-multi-agent-orchestrator` | Orchestration. NOT `superpowers-dispatching-parallel-agents` (that's for true parallelism). |
| Pure Q&A / explain something / look it up | **No skill required.** But announce: "Skipping superpowers — pure Q&A." | Don't gate Q&A. |
| Want snappy 1-step classification | `superpowers-triage` | Faster than this routing table. One pass, one decision. |
| "Run a known command / known task" | The specific domain skill (e.g., `github-pr-workflow` for a PR). | Domain-specific. |

## The 3-second decision rule

If the user message:

1. **Describes something to BUILD or CREATE** → `superpowers-creative-workflow`
2. **Describes something to FIX or CHANGE in existing code** → `superpowers-code-workflow`
3. **Asks a question or wants information** → no skill (just answer)
4. **Asks you to COMMIT, PUSH, or SHIP** → `superpowers-requesting-code-review`
5. **Unclear** → ask one clarifying question: "Is this creating something new, fixing something existing, or pure Q&A?"

**Snappy mode:** If you want a single-pass classification instead of the full
table, load `superpowers-triage` (one decision, one skill load). Use triage
for speed; use routing for completeness.

That's it. Three options, one decision.

## The gates you must NEVER skip (HARD GATEs)

1. **No code without a brainstorm** (for new features). Exception: trivial 1-line tweaks with explicit user override.
2. **No implementation without an approved plan** (for medium/large features).
3. **No production code without a failing test first** (TDD). Always.
4. **No "done" without verified evidence** (verification-before-completion).
5. **No commit without a self-review** (requesting-code-review) — and in workspaces with a `sp-commit` wrapper installed, **always use `sp-commit` instead of bare `git commit`** (see AGENTS.md Gate 6; mechanism documented in `hermes-skill-enforcement` layer 5b).

## Enforcing the gates when the model skips them

The 5 gates above are enforced in-skill (the model is told to follow them). For workspaces where the model has been observed skipping a gate in practice, there are **layer-5 mechanisms** that live outside the model's decision loop — cron audits, wrapper scripts, pre-commit hooks. The full pattern is in `hermes-skill-enforcement`.

## Cross-reference: the full chain

```
User says: "Build X"
   ↓
superpowers-creative-workflow (orchestrator)
   ↓
superpowers-brainstorming (Gate 1: design approval)
   ↓
superpowers-writing-plans (Gate 2: plan approval)
   ↓
superpowers-test-driven-development (per task)
   ↓
superpowers-requesting-code-review (per commit)
   ↓
superpowers-verification-before-completion (Gate 3: verified evidence)
   ↓
superpowers-finishing-a-development-branch (final merge)
```

```
User says: "Fix X"
   ↓
superpowers-code-workflow (orchestrator)
   ↓
[bug? → superpowers-systematic-debugging] | [change? → superpowers-brainstorming (light)]
   ↓
superpowers-test-driven-development (regression test first)
   ↓
superpowers-verification-before-completion
   ↓
superpowers-requesting-code-review (commit)
```

## Quick announcements (use these in responses)

When you invoke a skill, announce it briefly so the user can see what's happening:

- `Using superpowers-creative-workflow to gate this build.`
- `Using superpowers-brainstorming to explore the design.`
- `Using superpowers-test-driven-development for the implementation.`
- `Using superpowers-verification-before-completion to confirm the result.`
- `Using superpowers-systematic-debugging to find the root cause.`
- `Using superpowers-requesting-code-review before the commit.`
- `Using superpowers-finishing-a-development-branch to merge.`

If you realize mid-turn that you should have loaded a skill and didn't, say so explicitly:

> "I should have loaded `superpowers-X` before that action. I didn't. Correcting now."

## Workspace-specific workflow preferences

These preferences are checked at session bootstrap (they live in `user` memory
and may be reinforced here when they're workflow-level rather than identity-level).

### Permission posture inside the Hermes Docker container

When running inside the `nousresearch/hermes-agent` Docker image, the
container itself is the sandbox. Do not pause for approval on
`terminal`, `write_file`, `patch`, or other destructive operations
within the container. If a security scanner trips (e.g. secret
detection in a fixture file), briefly note that you noticed it and
proceed — the scanner is informational, not a stop-the-world signal.

A separate, higher-friction approval posture applies to anything
that escapes the container (push to remote, email, public posting,
opening a real PR, etc.). Those are still gated.

If you are NOT in the Docker container, default to the standard
permission posture.

## License

MIT.
