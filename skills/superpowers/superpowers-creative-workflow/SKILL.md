---
name: superpowers-creative-workflow
description: "MASTER ORCHESTRATOR for any creative/building request in Hermes. Loads the moment the user asks to create, design, build, implement, add a feature, or modify behavior. Gates the user through brainstorming → design → plan → TDD → verification in that order. NON-NEGOTIABLE workflow. ALWAYS load this when the user message contains words like: crea, crear, diseña, diseñar, construye, build, create, design, implement, scaffold, make me, quiero una app, let's make, I want to build, add a feature, modify behavior."
version: "5.1.0"
author: "Jesse Vincent (obra) + Hermes enforcement"
license: MIT
platforms: [linux, macos]
namespace: superpowers
source: "https://github.com/obra/superpowers"
metadata:
  hermes:
    tags: [superpowers, orchestrator, creative, gate, workflow]
    homepage: "https://github.com/obra/superpowers"
---

# superpowers-creative-workflow — the ONLY way to build anything

This is the master orchestrator. It is the **first skill you load** when the user asks to create, build, design, implement, or modify anything. It enforces the full superpowers pipeline from intent to verified delivery.

> **This skill is a HARD GATE. No code is written, no scaffold is created, no install is run, no file is committed until the user has approved a written spec.**

## When to load this skill

Load this skill on the **first user turn** when the user message contains ANY of:

**English triggers:** "create", "build", "design", "implement", "make me", "I want", "let's make", "let's build", "I need a", "add a feature", "scaffold", "scaffolding", "wire up", "set up a new", "new app", "new project", "new module", "new feature", "new component", "new page", "new endpoint", "new API", "I want to make a", "I want to build a", "we should build", "let's add".

**Spanish triggers:** "crea", "crear", "diseña", "diseñar", "construye", "construir", "hazme", "quiero una", "vamos a hacer", "vamos a crear", "necesito una", "añade", "agrega", "implementa", "implementar", "una app", "un proyecto", "un módulo", "una feature", "una funcionalidad", "un componente", "hagamos", "armemos", "montemos".

**Code-modification triggers:** "modify behavior", "change the way X works", "refactor", "redesign", "rewrite", "port to", "migrate to", "add support for".

**If unsure whether to load it → LOAD IT.** Erring on the side of loading is always correct. Loading it for a false positive costs 30 seconds of "let's clarify"; missing it for a true positive costs hours of misaligned work.

## What this skill does

It loads, **in order**, the four critical sub-skills and enforces the gates between them:

```
┌─────────────────────────────────────────────────────────────┐
│  1. superpowers-brainstorming                                │
│     GATE 1: User explicitly approves the design.            │
│     Output: docs/superpowers/specs/YYYY-MM-DD-<topic>.md     │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  2. superpowers-writing-plans                                │
│     GATE 2: User explicitly approves the plan.              │
│     Output: docs/superpowers/plans/YYYY-MM-DD-<topic>.md     │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  3. superpowers-test-driven-development                      │
│     GATE 3 (per task): Failing test exists before code.     │
│     Output: Tests + implementation, commit per task.         │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  4. superpowers-verification-before-completion               │
│     GATE 4: User can independently verify the result.        │
│     Output: Evidence the work matches the spec, end-to-end.  │
└─────────────────────────────────────────────────────────────┘
```

## The protocol — exactly what you do on first creative turn

### Step 1: Announce and load

In your first response to the creative request:

```
Using superpowers-creative-workflow to gate this build through
brainstorming → design → plan → TDD → verification.

Loading superpowers-brainstorming now. I will not write any code
until we've agreed on a written design and you approve it.
```

Then `skill_view(name="superpowers-brainstorming")` and follow it.

### Step 2: Brainstorm (until Gate 1)

Follow `superpowers-brainstorming` exactly. Do not skip. Do not rationalize skipping. The output is:

- A spec file at `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
- Explicit user approval of that file

If the user says "just go", "skip the doc", or "we already discussed it" — push back gently and ask for the spec to be written. The only allowed exceptions are listed in the brainstorming skill (trivial 1-line tweaks with user override).

### Step 3: Plan (until Gate 2)

After the design is approved, follow `superpowers-writing-plans`. The output is:

- A plan file at `docs/superpowers/plans/YYYY-MM-DD-<topic>-plan.md`
- Bite-sized tasks with exact file paths and verification steps
- Explicit user approval of that file

If the plan would take >5 minutes to read, split it.

### Step 4: TDD (per task)

For each plan task:

1. Write a failing test (RED).
2. Verify it fails for the right reason.
3. Write minimal code to pass (GREEN).
4. Verify all tests pass.
5. Refactor while keeping green.
6. Commit (after a self-review per `superpowers-requesting-code-review`).

### Step 5: Verify (Gate 4)

Before declaring the work done:

- Re-read the spec. Re-read what the user asked for. Are they the same?
- Run the full test suite. Quote the output.
- Manually exercise the new behavior. Quote the result.
- Check edge cases, error paths, integration points.
- Show the user the evidence.

Only then say "done."

## Anti-rationalization (for you, the agent)

If you are tempted to skip any of the four gates, here is the table of excuses and why they are wrong:

| Excuse | Why it's wrong | What to do |
|---|---|---|
| "User said it's simple" | "Simple" projects are where unexamined assumptions cost the most. | Brainstorm. It takes 5 minutes. |
| "User said go fast" | Rewriting costs days. Brainstorming costs minutes. | Brainstorm. |
| "User said skip the doc" | The doc is what survives. The chat loses context. | Write the doc. Make it short if you must. |
| "I already know what they want" | You have a guess. Verify it. | Ask. |
| "Tests slow me down" | TDD is faster than debugging. Always. | TDD. |
| "I'll verify later" | "Later" doesn't happen. | Verify before saying done. |
| "The user is busy" | The user will be busier fixing broken work. | Be honest about progress. |
| "It's just a config change" | Config changes break systems too. | Brainstorm (1-question variant). |
| "I don't have time for tests" | You don't have time NOT to test. | TDD. |
| "The user trusts me" | Trust is built by following the process, not by skipping it. | Follow the process. |
| "User just said 'si' / 'dale' — should I re-confirm field names, exact wording, error messages?" | The user delegated via batch approval. They want execution, not more questions about details they already said "you decide" to. | Execute. The "wording" question is an implementation detail. Only ask if it is a *new* decision the user did not pre-approve. |

## The TWO allowed exceptions (read carefully)

**Exception 1 — "just do X, no questions":** If the user says **"just do X, no questions"** AND all of these are true:

- X is **a single, atomic action** (one commit, one command, one tiny change)
- X is **fully reversible** (no production impact, easy to undo)
- X is **low-risk** (no auth, no data, no infra)
- X is **not creative work** (not a feature, not a design)

Then you may proceed without a full brainstorm. But you must still:

- Announce what you're about to do.
- Verify it worked (`superpowers-verification-before-completion`).
- Tell the user what you did, with evidence.

If any of the four conditions is false, you must brainstorm. No exceptions.

**Exception 2 — "apply your recommendations":** If, during brainstorming, the user has been presented with 2-3 options (with your recommendation) and answers **"aplica tus recomendaciones en todo"**, **"you decide"**, **"go with your best judgment"**, **"dame tu recomendación"**, or any clear batch-approval phrase, this counts as **Gate 1 + Gate 2 approval at once** for the recommended path. The skill then proceeds:

- Write the spec (using your recommended option for each decision point).
- Write the plan.
- Execute the plan via `superpowers-executing-plans`.
- Verify at the end.

Do **not** keep re-asking for the same decisions the user delegated. Ask only for questions that were NOT part of the pre-approved recommendations.

## What this skill is NOT

- It is **not** a way to add ceremony. The gates are short. The spec is short. The plan is short. The TDD cycle is 5 minutes. The total overhead for a one-day feature is 30 minutes. The cost of skipping it is days.
- It is **not** negotiable. The user installed superpowers because they want this process. Honoring it IS the value.
- It is **not** a substitute for judgment. Use judgment about *what* to build (the brainstorm) and *how* to verify (the test). The gates just enforce that you do the work in the right order.

## Operational guide for "apply your recommendations" (Exception 2)

The user replied with a batch-approval phrase ("aplica tus recomendaciones en
todo", "you decide", "go with your best judgment", "dame tu recomendación").
Now what?

**DO proceed to:**
1. Write the spec to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
   using your recommended option for every decision point.
2. Write the plan to `docs/superpowers/plans/YYYY-MM-DD-<topic>-plan.md`
   using your recommended execution order.
3. Show the user a **short "decision log"** at the top of the spec, listing
   the recommendations you adopted (so the user can spot anything they
   didn't mean to delegate).
4. Execute the plan via `superpowers-executing-plans` (TDD per task).
5. Verify at the end (Gate 4).

**DO NOT re-ask the user for:**
- Decisions that were options in the brainstorm menus and got the
  recommended answer picked.
- The same option you already presented.
- "Are you sure you want to proceed?" after a clear "si" / "dale" / "approved".
- The exact wording of error messages, file paths, or test names — those
  are implementation details.

**DO ask the user ONLY for:**
- A genuinely new question that emerged after the recommendations were
  applied (e.g. "during implementation, I hit two equally good options
  for X — which way?").
- An unclear intent where the user delegated X but the recommendation
  for Y depended on assumptions about X.

**Anti-pattern this prevents:** "User approved, I wrote the spec, then I
went back and asked 'should I really do option 3?'". That is wasted turn
and breaks flow. The user explicitly chose delegation. Honor it.

**Cadence signal:** the user's first reply after a batch approval is
expected to be one of: "dale", "continua", "aplica", "go", or
"si, aprovado. [specific action]". A short imper­ative. If you see
that pattern, proceed; do not re-explain the recommendations.

## Cross-references

- `superpowers-using-superpowers` — the bootstrap that decides which skills to load.
- `superpowers-brainstorming` — Gate 1.
- `superpowers-writing-plans` — Gate 2.
- `superpowers-test-driven-development` — Gate 3.
- `superpowers-verification-before-completion` — Gate 4.
- `superpowers-requesting-code-review` — runs before every commit.
- `superpowers-systematic-debugging` — for bug fixes (the code-workflow variant).
- `superpowers-finishing-a-development-branch` — for the final merge.

## License

MIT. Original © Jesse Vincent, Hermes enforcement layer also MIT.
