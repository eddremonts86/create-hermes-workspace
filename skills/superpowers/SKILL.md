---
name: superpowers
description: "Meta-skill index for the 14 superpowers skills ported from obra/superpowers v5.1.0. Load this to see what's available, then load the individual skill you need."
version: "5.1.0"
author: "Jesse Vincent (obra)"
license: MIT
platforms: [linux, macos]
namespace: superpowers
source: "https://github.com/obra/superpowers"
metadata:
  hermes:
    tags: [superpowers, methodology, index, workflow]
    homepage: "https://github.com/obra/superpowers"
---

# Superpowers — full enforcement system on Hermes

This is a **port of [obra/superpowers](https://github.com/obra/superpowers) v5.1.0** to the Hermes skill format, extended with a **4-layer enforcement system** that makes the workflow world-class: not just installed, but consistently triggered, gated, and verified across every session.

The original lives at <https://github.com/obra/superpowers> by Jesse Vincent. It is published in the Anthropic Claude Code plugin marketplace as `superpowers@claude-plugins-official`. In Hermes, the skills are individual skills under the `superpowers-<name>` namespace, so each one loads on demand with `skill_view(name="superpowers-<name>")`.

## The 18 skills

The system has three layers: **routing**, **orchestrators**, and **enforced sub-skills**. Always load the routing skill first, then the orchestrator that matches the user's intent, then the specific sub-skill the orchestrator names.

### Routing (load on every session start)

| Skill | When to load it |
|---|---|
| `superpowers-skill-routing` | **Bootstrap.** Compact 1-page table that maps user intent → orchestrator. Load this first on every session. |
| `superpowers-triage` | **ULTRA-FAST 1-step classifier.** Use instead of `superpowers-skill-routing` when you want speed over completeness. Single decision, single skill load. |

### Orchestrators (load after the routing table)

| Skill | When to load it |
|---|---|
| `superpowers-creative-workflow` | **Master gate for any build/creation request.** User said "crea", "build", "design", "implement", "add a feature", "modify behavior", "scaffold", "let's make", etc. Chains: brainstorming → writing-plans → TDD → verification. |
| `superpowers-code-workflow` | **Master gate for any fix/modification request.** User said "fix", "arregla", "refactor", "debug", "X doesn't work", "migrate", "port", etc. Routes to debugging flow or modification flow. |

### Sub-skills — creative chain (loaded by `superpowers-creative-workflow`)

| Skill | When to load it |
|---|---|
| `superpowers-using-superpowers` | Loaded by routing. Establishes how to discover and use skills. |
| `superpowers-brainstorming` | **Gate 1.** Before any creative work. Explores intent, requirements, design. Outputs a written spec at `docs/superpowers/specs/`. |
| `superpowers-writing-plans` | **Gate 2.** After brainstorming is approved. Bite-sized plan with exact file paths and verification steps. Outputs at `docs/superpowers/plans/`. |
| `superpowers-executing-plans` | When executing an approved plan step by step. |
| `superpowers-test-driven-development` | **Gate 3 (per task).** Failing test before production code. Red/green/refactor. |
| `superpowers-verification-before-completion` | **Gate 4.** Re-run tests, exercise the result, quote the evidence before claiming "done". |
| `superpowers-requesting-code-review` | **Gate 5 (per commit).** Self-review of the diff before `git commit`. |
| `superpowers-finishing-a-development-branch` | Final merge / PR / archive step. |

### Sub-skills — code chain (loaded by `superpowers-code-workflow`)

| Skill | When to load it |
|---|---|
| `superpowers-systematic-debugging` | **Gate A (debugging flow).** 4-phase root-cause analysis before any fix. |
| `superpowers-receiving-code-review` | When responding to PR feedback. |
| `superpowers-dispatching-parallel-agents` | For 2+ truly independent parallel workstreams. |
| `superpowers-subagent-driven-development` | For ordered multi-agent work over a plan. |
| `superpowers-using-git-worktrees` | When using worktrees for isolation. |
| `superpowers-writing-skills` | When creating a new skill (Hermes or otherwise). |

## The 4-layer enforcement system

This is what makes the install more than just a copy. The pattern is reusable for ANY skill collection, not just superpowers — see the `hermes-skill-enforcement` skill for the general methodology.

**Layer 1 — Bootstrap AGENTS.md** (in `/opt/data/AGENTS.md`): a small markdown file at the cwd root that the Hermes prompt builder auto-injects into every session. Contains the routing rules, the gate list, the "announce then act" protocol. ~6KB. Verified to load by calling `build_context_files_prompt(cwd=...)` and confirming the content appears in the system prompt.

**Layer 2 — Routing skill** (`superpowers-skill-routing`): a compact 1-page decision table that maps any user intent to the right orchestrator. Has 3-second decision rules. Loaded on session start.

**Layer 3 — Orchestrator skills** (`superpowers-creative-workflow`, `superpowers-code-workflow`): each one enforces the full chain (brainstorm → plan → TDD → verify). Contains the HARD-GATE statement, the anti-rationalization table, the failure mode it prevents, and the one allowed exception. Always loads in the user's first turn for matching intent.

**Layer 4 — Reinforced sub-skills**: every critical sub-skill gets a `## ⚡ HERMES ENFORCEMENT` block prepended, with its own absolute rule, anti-rationalization table, and failure mode. The upstream skill is preserved; the enforcement is additive.

All four layers work together. Removing any one of them creates a failure mode the others don't cover:
- Remove Layer 1 → skills exist but the model never knows to load them.
- Remove Layer 2 → the model has to discover the orchestrators from descriptions alone, and the 3-second decision rule is gone.
- Remove Layer 3 → no master gate; the model can pick any sub-skill and skip the rest.
- Remove Layer 4 → the sub-skills exist but their rules are not absolute; the model can rationalize skipping them.

## Core philosophy (from `using-superpowers`)

- **Skills override default system behavior**, but **user instructions always win** (CLAUDE.md, AGENTS.md, direct requests).
- **If a skill might apply (even 1% chance), you must invoke it.** Not negotiable.
- **"Simple" projects still need a design.** No project is too small to skip brainstorming.
- **TDD is not optional.** Red, green, refactor.
- **Verify before completion.** Run it. Don't assume it works.
- **This install was the user's explicit request for "world-class quality".** Skipping the gates is failing the user.

## How to invoke a superpowers skill

In a session, load any individual skill with:

```python
skill_view(name="superpowers-skill-routing")          # bootstrap
skill_view(name="superpowers-creative-workflow")      # orchestrator
skill_view(name="superpowers-brainstorming")          # gate 1
skill_view(name="superpowers-test-driven-development") # gate 3
```

Or load the `superpowers` index (this skill) to see the full landscape.

## Overlap with existing Hermes skills

Some skills overlap with skills already installed in this workspace. When both exist, prefer **the existing Hermes skill** for routine work and load the **superpowers version** when you want the methodology baked into the workflow:

| Superpowers skill | Existing Hermes skill |
|---|---|
| `superpowers-writing-plans` | `plan` |
| `superpowers-test-driven-development` | `test-driven-development` |
| `superpowers-systematic-debugging` | `systematic-debugging` |
| `superpowers-requesting-code-review` | `requesting-code-review` |

The two are complementary, not duplicates — superpowers versions are heavier on ceremony and explicit gates.

## Updating from upstream

The skills are stored in `~/.hermes/skills/superpowers/<name>/`. To refresh from upstream, run:

```bash
~/.hermes/skills/superpowers/scripts/sync-from-upstream.sh
```

(Only run that script — the safe one — not the upstream's own update script, which would clobber the porting work and the enforcement blocks.)

**What the sync script preserves across updates:**
- All 14 sub-skill content (refreshed from upstream)
- Extended Hermes frontmatter on every skill
- The 4 orchestrators/routing (routing, triage, creative-workflow, code-workflow) — all Hermes-specific, not in upstream
- The 11 `## ⚡ HERMES ENFORCEMENT` blocks (re-applied after content refresh)

## License

MIT. Original © Jesse Vincent, port and enforcement layer © 2026 Hermes Agent / the user.

