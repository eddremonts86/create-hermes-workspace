---
name: hermes-skill-enforcement
description: "Use when a collection of skills needs to be enforced consistently across every Hermes session — not just installed but triggered, gated, and verified. Codifies the 4-layer enforcement pattern (bootstrap AGENTS.md + routing skill + orchestrators + reinforced sub-skills) extracted from the obra/superpowers 'world-class quality' install. Apply this when the user wants a methodology that the model cannot rationalize skipping, not just a set of skills on disk."
version: "1.1.0"
author: "Hermes Agent (extracted from superpowers enforcement install, 2026-06-05)"
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [skills, enforcement, methodology, gates, quality, system-design]
    related_skills: [adopting-upstream-skills, superpowers, hermes-agent, hermes-agent-skill-authoring]
---

# Enforcing a skill collection across every Hermes session

A class of work that comes up when a user says "make this methodology consistent" or "I want world-class quality on every build." The mistake is to think the work is "install the skills and trust the model." The model **will** rationalize skipping them, especially under time pressure, especially with vague instructions. The fix is to design the install so the model **cannot** skip them without the user noticing.

This skill codifies the **4-layer enforcement pattern** that emerged from the superpowers enforcement install (obra/superpowers v5.1.0 → Hermes, June 2026). It is the general pattern; the superpowers install is the worked example.

## When to load this skill

Load when **any** of these fire:

- User wants a methodology to apply to every session, not just the ones where they remember to ask.
- User complains that the model "sometimes" follows the methodology, "usually" skips steps, or is inconsistent.
- User says "I want world-class quality", "I want gates", "I want it enforced", "I want the same process every time."
- You're installing a new skill collection and want to do it right the first time.
- You're reviewing an existing skill install and notice the model can opt out of it.
- You're adding enforcement that lives OUTSIDE the model (cron audits, wrapper scripts, pre-commit hooks) — see "Beyond the 4 layers" below.

Do **not** load this skill for: writing a single skill from scratch (use `hermes-agent-skill-authoring`); porting a third-party plugin (use `adopting-upstream-skills`); troubleshooting why a specific skill isn't loading (check the SKILL.md frontmatter first).

## The 4 layers (and what removing each one breaks)

```
┌──────────────────────────────────────────────────────────────────┐
│ Layer 1 — Bootstrap AGENTS.md                                     │
│  Auto-injected into system prompt at session start.               │
│  Contains: routing rules, gate list, announce-then-act protocol.  │
│  REMOVE THIS → skills exist but the model never knows to load.   │
└──────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────┐
│ Layer 2 — Routing skill                                           │
│  Loaded by the model on first turn.                              │
│  Contains: 1-page decision table mapping intent → orchestrator.   │
│  REMOVE THIS → model has to discover orchestrators from          │
│  descriptions alone; 3-second decision rule is gone.             │
└──────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────┐
│ Layer 3 — Orchestrator skills (one per intent family)            │
│  Each enforces the full chain for its domain.                    │
│  Contains: HARD-GATE statement, anti-rationalization table,      │
│  failure mode, one allowed exception.                            │
│  REMOVE THIS → no master gate; model can pick any sub-skill      │
│  and skip the rest.                                               │
└──────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────┐
│ Layer 4 — Reinforced sub-skills                                   │
│  Every critical sub-skill gets an additive enforcement block.    │
│  Contains: absolute rule, anti-rationalization table, failure    │
│  mode, trigger keywords (ES + EN).                                │
│  REMOVE THIS → sub-skills exist but rules are not absolute;       │
│  model can rationalize skipping them.                             │
└──────────────────────────────────────────────────────────────────┘
```

All four layers are required. The system has been verified by removing each layer in turn and observing the failure mode.

## Beyond the 4 layers — environmental/outside-the-model enforcement

The 4 layers are about **what the model decides to do**. There is a second class of enforcement that lives **outside the model's decision loop** — code the model never gets a chance to rationalize past because it runs in a different process, on a schedule, or in a hook. When the 4 layers aren't enough (or aren't available — e.g. you can't modify the agent runtime to add pre-tool-use hooks), add one or more of these:

| # | Mechanism | Lives in | Stops the model from... |
|---|---|---|---|
| 5a | **Scheduled audit job** | Cron / scheduled task | Letting drift / silent breakage go unnoticed. A script runs weekly/monthly, verifies the install is intact, and reports problems to a channel the user sees. |
| 5b | **Wrapper script + PATH gate** | `~/.local/bin/<name>` (or similar) | Calling the un-wrapped command directly. The wrapper prints a checklist and asks for confirmation; the model is told in AGENTS.md "you MUST use `<name>`, never the raw command." |
| 5c | **VCS pre-commit hook** | `.husky/pre-commit` (or `.git/hooks/pre-commit`) | Committing code that fails the gate. Runs on every commit attempt, before the commit lands. The model cannot skip it without `--no-verify` (and that creates an audit trail). |
| 5d | **Pre-tool-use hook** (if the agent supports it) | Agent runtime | Calling certain tools without prerequisites met. Most powerful but requires the agent to expose a hook API; if it doesn't, fall back to 5b/5c. |

**When to reach for layer 5:** when you've observed the model actually skipping one of the 4 layers in practice (not just in theory), AND the skip has real consequences (bad commits landing, skill corruption going unnoticed, security regressions). Don't add layer-5 enforcement speculatively — each mechanism adds maintenance cost and friction the user has to live with.

**Wrapper pattern (5b) recipe** — used to add a `sp-commit` gate on top of an existing `git commit`:

1. Write a small bash script at `~/.local/bin/<name>` (e.g. `sp-commit`).
2. The script: validates preconditions, prints a self-review checklist, asks for `y/N` confirmation interactively, then `exec`s the real command on `y` or `exit 1`s on `N`.
3. In non-TTY mode, refuse to run unless an explicit bypass env var is set (e.g. `SP_COMMIT_SKIP=1`). This catches CI/agent contexts that would otherwise silently bypass.
4. Add a new HARD GATE row to AGENTS.md: "Use `<name>`, never the raw command. Reason: ..."
5. Add a "Anti-rationalization" mini-table to that gate (3-4 rows of excuses + rebuttals).
6. Add the wrapper to PATH via `~/.bashrc` (`export PATH="$HOME/.local/bin:$PATH"`).

The wrapper pattern works because: (a) the model reads AGENTS.md on session start, (b) the model is told to call `sp-commit` by name, (c) `sp-commit` is in the model's effective PATH, (d) `sp-commit` itself enforces the gate. The model has no "let me just call git directly" escape hatch that's cheaper than reading AGENTS.md and complying.

**Pre-commit hook pattern (5c) recipe** — used to enforce secret-scan, debug-code scan, and diff-size limits on every commit:

1. Write a bash script that runs the gates (see `superpowers/scripts/superpowers-precommit-guard.sh` for a worked example).
2. Have the script exit `0` (green), `1` (block the commit), or `2` (warning — see below).
3. In the worktree: install the hook via husky (`install-precommit-guard.sh <worktree>`) or symlink directly to `.git/hooks/pre-commit`.
4. For "warnings" (e.g. diff is large but not necessarily wrong), use exit code 2 — git treats any non-zero from pre-commit as a failure, so the script must decide: hard block (1) or just a printed warning + proceed (0 after printing).
5. **Test the gate with a known-bad input before trusting it.** See "bash-pitfalls" reference — the ERE `\+` trap silently breaks grep-based secret scanners. One missed escape and you've shipped a security theater.

**The model-cannot-skip check** for layer 5: ask "could a sufficiently motivated model bypass this by typing a different command?" If yes (e.g. `git commit --no-verify` bypasses the hook), the gate is *advisory* not *enforced*. Layer 5c only works if the user (not the model) is the one who decides when to bypass. If the model can self-bypass, you have not added enforcement; you have added ceremony.

**When layer 5 is the right answer vs. strengthening layer 3-4:**

- The methodology is being **applied** but **outcome is wrong** (model reviews its own code, but reviews are shallow; model runs tests, but tests are weak) → strengthen layer 4 (anti-rationalization, deeper checks).
- The methodology is **not being applied at all** (model commits without reviewing; model "forgets" to update AGENTS.md) → layer 5 (commit hook forces the review, cron forces the AGENTS.md check).
- The methodology is **inconsistent across machines or sessions** (works on user's laptop, breaks on the agent runtime) → layer 5b (PATH-installed wrapper is environment-portable; AGENTS.md is auto-injected).

## Verification — what to test before declaring the system enforced

Layer 1 — `build_context_files_prompt(cwd=...)` returns the AGENTS.md content in its output. Not blocked by the scanner.

Layer 2 — `skill_view(name="<routing>")` returns the routing table. `skills_list` shows the routing skill with its full description (not truncated).

Layer 3 — each orchestrator loads via `skill_view(name="<orchestrator>")` and shows: trigger keywords, chain diagram, protocol, anti-rationalization table, allowed exception, cross-references.

Layer 4 — each reinforced sub-skill loads via `skill_view(name="<sub-skill>")` and shows the enforcement block at the top of the body.

Layer 5a — the cron job actually runs on schedule (don't trust "scheduled" without observing a real run; many schedulers silently no-op on first attempt).

Layer 5b — the wrapper is in the model's effective PATH (`which <name>` returns the wrapper, not the real command). Test the wrapper's "bypass refusal" path: `echo "n" | <name> -m "..."` should fail; `<name>=...` should succeed; the real `<name>` should still be callable by its full path or alias.

Layer 5c — the hook actually fires (`git commit` triggers it). Test the gate with a known-bad input (e.g. staged `console.log` for debug gates, a fake-but-valid-format `AKIA...XXXX` AWS key for secret gates). Test the bypass (`git commit --no-verify`) and confirm it works but is logged/visible.

**Behavioral test** (the one that actually proves the system works):

Build a set of 10-20 test messages covering each intent family. For each, run the routing logic and confirm the correct orchestrator is selected. A simple Python script with keyword matching is enough; you don't need to run the actual model. If the routing table is accurate, the model will use it correctly.

```python
def route(msg):
    m = msg.lower()
    if any(t in m for t in code_triggers):
        return "code-workflow"
    if any(t in m for t in creative_triggers):
        return "creative-workflow"
    return "no-methodology"

# Run on the test set, assert 100% classification
```

## Common pitfalls (the ones that break the system)

- **Skipping Layer 1.** "The skill descriptions should be enough." They're not. The model loads skills reactively; without an explicit bootstrap, the system only engages when the model happens to scan and match. Bootstrap is what makes it deterministic.
- **Routing skill too long.** If Layer 2 is 15KB, the model skims it and misses the decision rule. Keep it to 3-5KB. Move detail to Layer 3 (orchestrators).
- **Anti-rationalization tables too short.** Five rows is not enough. The model has a long list of justifications; you need at least 8-10 in the orchestrator. Add more over time as you see new excuses in the wild.
- **Enforcement blocks as decals.** If the enforcement block sits at the end of the skill instead of the top, the model reads the soft upstream content first and the absolute rule last. The model defaults to the first content it processes. Put enforcement at the top, right after the frontmatter.
- **No verification step.** If you install the system and don't run the routing test set, you're shipping blind. The routing table is the contract between user intent and the system; if the contract is wrong, nothing else matters.
- **Forgetting the language.** The user is bilingual (or trilingual). The orchestrator triggers should include keywords in every language the user works in. A Spanish user saying "arregla el bug" should hit the code-workflow, not fall through to Q&A.
- **Sync script clobbers the enforcement blocks.** When refreshing the sub-skills from upstream, the sync script must re-apply the enforcement blocks (using a marker check for idempotency). If it doesn't, the next upstream release will erase your world-class quality and ship the soft upstream defaults.
- **Reaching for layer 5 before layer 1-4 are solid.** Don't add cron audits and wrapper scripts until the model's own decisions are already gated. Enforcement outside the model is a supplement, not a substitute, for in-skill enforcement.
- **Wrapper with no AGENTS.md entry.** A wrapper in `~/.local/bin/` that the AGENTS.md never mentions is just dead code — the model doesn't know to use it. Every layer-5 mechanism must be referenced from Layer 1.
- **Pre-commit hook with a known-broken gate.** A hook that lets secrets through is worse than no hook: it gives false confidence. Always test the hook with a known-bad input before trusting it. The bash ERE gotcha (see `references/bash-pitfalls.md`) silently breaks grep-based secret scanners; one missed escape and you've shipped a security theater.
- **Treating "model approved" as a commit gate.** A model that says "looks good, ship it" is not a gate. A gate is something that fails the commit (or wrapper call) on objective criteria, regardless of what the model thinks. Layer 5 enforces objective criteria; the model is not in the loop.
- **Inventing enforcement that duplicates what already exists.** Before writing a layer-5 mechanism, **inventory the existing install** (`ls <install-dir>/scripts/`, `cat AGENTS.md`, etc.). The superpowers install shipped with `superpowers-self-check.sh`, `superpowers-precommit-guard.sh`, and `install-precommit-guard.sh` already on disk from a previous session; writing new versions from scratch wasted time and created drift. (See `references/audit-existing-install.md` for the inventory checklist.)
- **Adding friction without adding safety.** Layer 5 is justified by observed skipping, not by spec. If the model never skips the gate in practice, a wrapper or hook is dead weight. Measure first; enforce second.

## Worked example

The superpowers enforcement install (obra/superpowers v5.1.0 → Hermes, June 2026) is the canonical worked example of this pattern. It produced:

- Layer 1: `/opt/data/AGENTS.md` (6.3KB, auto-injected, verified)
- Layer 2: `superpowers-skill-routing` (5.3KB, routing table)
- Layer 3: `superpowers-creative-workflow` (10KB) and `superpowers-code-workflow` (9.7KB)
- Layer 4: 11 reinforced sub-skills, each with a `## ⚡ HERMES ENFORCEMENT` block
- Layer 5a: cron job `superpowers-weekly-audit` (weekly, runs `superpowers-self-check.sh`)
- Layer 5b: `~/.local/bin/sp-commit` wrapper around `git commit` (with self-review checklist + interactive confirm)
- Layer 5c: `.husky/pre-commit-superpowers` (with secret scan, debug scan, diff-size limit)

Routing test set: 16/16 messages classified correctly (9 creative, 7 non-creative).
Layer-5c test: staged `AKIAA1B2C3D4E5F6G7H8J9` correctly blocks; staged `console.log()` correctly warns; clean commit proceeds.

A bug in the original layer-5c script (`grep -v "^\+\+\+"` interpreting `\+` as ERE) was discovered and fixed during the test cycle — see `references/bash-pitfalls.md` for the pattern. **Always test layer-5 gates with a known-bad input.**

## A second worked example: AI-Lab Yonder integration (June 2026)

Three weeks after the superpowers install, the same user asked to integrate
`AI-Lab-Yonder/ai-lab-agent-skills` (25 skills) for company projects. This
exercised a different shape of the enforcement pattern: **selective import
with namespace-prefixed skills and routing disambiguation**.

- **Layer 1 (extended):** AGENTS.md grew a Gate 7 row for AI-Lab routing
  ("audit / hunt bugs / review PR / postmortem / autoresearch / docs /
  multi-agent → load `ailab-*`, NOT the `superpowers-*` equivalent").
- **Layer 2 (extended):** `superpowers-skill-routing` got 8 new rows
  disambiguating `ailab-*` from `superpowers-*` for each AI-Lab intent.
- **Layer 4 (new namespace):** 8 `ailab-*` skills imported, each with
  `metadata.hermes.upstream_skill` set to the original AI-Lab name (for
  traceability) and a `namespace: ailab` declaration.
- **Layer 4 (new umbrella):** `ailab/SKILL.md` index with the routing
  disambiguation table — the artifact the LLM actually consults when
  intent is ambiguous between two similar skills.
- **Layer 5a (extended):** `superpowers-self-check.sh` grew an "AI-Lab
  skills" section that counts the 8 expected `ailab-*` skills and
  reports them in the weekly audit.
- **TDD layer (new):** two new tests —
  `tests/ailab/verify-skills.sh` (8-skill frontmatter check + collision
  check) and `tests/ailab/routing-test.sh` (20 routing test cases). The
  routing test is the load-bearing artifact: 8 unique intents + 4
  ambiguous + 4 superpowers-only + 4 Q&A.

**The class-level lesson:** when adding a new skill collection to an
existing install, the disambiguation problem is bigger than the import
problem. The import is mechanical; the routing is the part that determines
whether the model picks the right skill on the first try. Always build a
routing test set with ambiguous cases, and always document every skip
(17 in this case) so the user doesn't re-derive the rationale later.

**Full design spec:** `docs/superpowers/specs/2026-06-05-ailab-skills-integration-design.md`.
**Skip/keep matrix and transform script:** see `adopting-upstream-skills`
skill, `references/selective-import-ailab-case-study.md`.

## Sync artifact

**Sync script template** (for re-applying the enforcement blocks after upstream refresh): see `templates/sync-enforcement-blocks.py`. The script is idempotent (marker check) and supports dry-run, so it is safe to wire into the same sync-from-upstream.sh that refreshes the sub-skill content.

## Cross-references

- For the specific worked example of installing superpowers, see the `superpowers` index skill.
- For porting a third-party plugin as a starting point, see `adopting-upstream-skills`.
- For authoring a single skill from scratch, see `hermes-agent-skill-authoring`.
- For the AGENTS.md and prompt-injection rules that gate Layer 1, see the `hermes-agent` skill, `references/prompt-builder-environment-hints.md`.
- For bash gotchas that bite layer-5c (pre-commit hooks) in particular, see `references/bash-pitfalls.md`.
- For the "inventory before you build" checklist that prevented re-implementing existing scripts, see `references/audit-existing-install.md`.
