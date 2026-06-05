---
name: superpowers-code-workflow
description: "MASTER ORCHESTRATOR for any code change to an existing system. Loads the moment the user asks to fix, refactor, debug, change behavior, add to, or modify existing code. Gates the user through systematic-debugging (if bug) or brainstorming (if change) → TDD → verification. ALWAYS load this when the user message contains words like: fix, arregla, refactor, debug, depura, the X is broken, X doesn't work, change Y, modify Z, update the existing, migrate, port, upgrade."
version: "5.1.0"
author: "Jesse Vincent (obra) + Hermes enforcement"
license: MIT
platforms: [linux, macos]
namespace: superpowers
source: "https://github.com/obra/superpowers"
metadata:
  hermes:
    tags: [superpowers, orchestrator, code, debug, fix, gate, workflow]
    homepage: "https://github.com/obra/superpowers"
---

# superpowers-code-workflow — the ONLY way to change existing code

This is the orchestrator for **modifications to existing code**. It is the first skill you load when the user asks to fix, refactor, debug, change behavior, or modify something that already exists.

> **This skill is a HARD GATE. No code change is applied to existing code without a failing test that reproduces the issue or proves the new behavior.**

## When to load this skill

Load this skill on the first user turn when the user message contains ANY of:

**English triggers:** "fix", "refactor", "debug", "the X is broken", "X doesn't work", "X is wrong", "change Y", "modify Z", "update the existing", "migrate", "port to", "upgrade", "investigate", "investigate why", "trace the bug", "find the cause", "make Y faster", "make Y better", "improve", "clean up", "tidy up".

**Spanish triggers:** "arregla", "arreglar", "depurar", "depura", "investiga", "investigar", "encuentra el bug", "no funciona", "está roto", "está mal", "cambia", "cambiar", "modifica", "modificar", "actualiza", "migrar", "portar", "mejora", "limpiar", "refactorizar".

**Error-output triggers:** "I'm getting error X", "traceback", "exception", "TypeError", "undefined is not", "cannot read", "stack trace", "log shows".

## Two sub-flows inside this skill

This orchestrator routes to one of two sub-flows based on the user's intent:

### Flow A — Bug / error / doesn't-work (debugging)

```
┌─────────────────────────────────────────────────────────────┐
│  1. superpowers-systematic-debugging (4 phases)             │
│     Phase 1: Root cause analysis. NO FIX YET.               │
│     Phase 2: Pattern matching.                              │
│     Phase 3: Hypothesis testing.                            │
│     Phase 4: Fix + regression test.                         │
│                                                              │
│     GATE: User signs off on the root cause before fix.      │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  2. superpowers-test-driven-development                      │
│     Failing regression test first → fix → passing tests.    │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  3. superpowers-verification-before-completion               │
│     Re-run full suite. Manually exercise the fix.            │
└─────────────────────────────────────────────────────────────┘
```

### Flow B — Behavior change / refactor (modification)

```
┌─────────────────────────────────────────────────────────────┐
│  1. superpowers-brainstorming (lighter)                       │
│     Confirm scope: what exactly changes? What's preserved?   │
│     Output: 1-paragraph spec committed to git.               │
│     GATE: User signs off.                                    │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  2. superpowers-test-driven-development                      │
│     Characterization tests for current behavior (RED) →      │
│     Make them pass after refactor (GREEN).                   │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  3. superpowers-verification-before-completion               │
└─────────────────────────────────────────────────────────────┘
```

## Routing: how to choose A vs B

| User signal | Flow |
|---|---|
| "doesn't work", "broken", "error", "crash", "bug", "wrong output" | A (debugging) |
| "refactor", "clean up", "improve performance", "modernize" | B (modification) |
| "add X to the existing Y" | B (it's a behavior change) |
| "change the way X behaves" | B |
| "investigate why" | A (start with debug, may move to B if root cause is "missing feature") |
| Unclear | Ask: "Is X currently broken, or do you want to change what it does?" |

## The protocol — first turn

### Step 1: Announce and route

```
Using superpowers-code-workflow. Routing this to [Flow A: debugging | Flow B: modification].
Loading [superpowers-systematic-debugging | superpowers-brainstorming] now.
```

### Step 2: Run the chosen sub-flow

Follow the chosen sub-skill exactly. Do not skip phases. Do not propose a fix before establishing the root cause (Flow A) or before getting the spec approved (Flow B).

### Step 3: Test-driven fix

For Flow A:
- Write a regression test that reproduces the bug. It MUST fail without the fix.
- Apply the fix.
- The test MUST pass.
- All other tests MUST still pass.

For Flow B:
- Write characterization tests for the CURRENT behavior (they should pass).
- Apply the refactor.
- All characterization tests MUST still pass.
- Update tests if the behavior is intentionally changing (and explain why in the commit message).

### Step 4: Verify

Before declaring done, follow `superpowers-verification-before-completion`:
- Re-read what the user asked for.
- Run the full test suite.
- Manually exercise the changed behavior.
- Show the user the evidence (test output, command output, screenshot, etc.).

## Anti-rationalization

| Excuse | Why it's wrong | What to do |
|---|---|---|
| "I know what the bug is" | You have a guess. Guesses without verification create new bugs. | Verify root cause first. |
| "Just one-line fix" | One-line fixes need a regression test. Always. | TDD the fix. |
| "Tests for legacy code are too hard" | Hard to test = hard to maintain. Add the test anyway. | TDD the fix. |
| "Refactor without changing tests" | Tests after refactor pass immediately, prove nothing. | Characterization tests first. |
| "User is in a hurry" | Re-introduced bugs cost 10x the original time. | TDD. |
| "It's working now, just ship it" | "Working" without a test is "worked once." | Add the test. |
| "The fix is obvious" | Obvious fixes that break production are a cliché. | Verify the fix doesn't break other tests. |
| "I can't reproduce the bug" | If you can't reproduce it, you can't fix it. | Ask the user for more info. Don't guess. |

## What this skill is NOT

- It is **not** permission to skip verification. The bug is not fixed until the test passes AND the full suite passes AND the user can independently verify.
- It is **not** a substitute for understanding the existing code. Read the code, read the tests, read the docs. Then propose a fix.
- It is **not** permission to add scope. The user asked to fix X. Fix X. If you see Y also broken, mention it; don't fix it without permission.

## Cross-references

- `superpowers-using-superpowers` — bootstrap that calls this skill.
- `superpowers-systematic-debugging` — Flow A gate.
- `superpowers-brainstorming` — Flow B gate.
- `superpowers-test-driven-development` — the fix implementation in both flows.
- `superpowers-verification-before-completion` — Gate 4.
- `superpowers-requesting-code-review` — runs before every commit.

## License

MIT. Original © Jesse Vincent, Hermes enforcement layer also MIT.
