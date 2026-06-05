---

name: superpowers-verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
version: "5.1.0"
author: "Jesse Vincent (obra)"
license: MIT
platforms: [linux, macos]
namespace: superpowers
source: "https://github.com/obra/superpowers"
metadata:
  hermes:
    tags: [superpowers, methodology, workflow]
    homepage: "https://github.com/obra/superpowers"
---

## ⚡ HERMES ENFORCEMENT (additive to upstream)

**Trigger:** Right before you write "done", "listo", "funciona", "✓", "completed", or otherwise signal that a task is finished. Also before every `git commit`, every PR description, every "here's what I built" message.

**The rule: CLAIM NOTHING YOU HAVE NOT OBSERVED.**

**Verification steps (in order, all required):**

1. **Re-read the task.** What was the user actually asking for? (Not what you built — what they asked for.) Are those two the same?
2. **Re-read the spec/plan if one exists.** Did you build what the spec said, or did you substitute your judgment?
3. **Run the tests.** Not "I think it works" — `npm test`, `pnpm test`, `pytest`, `curl http://localhost:3000`, `git status`, whatever proves it. **Run the command. Read the output. Quote the relevant line.**
4. **Check edge cases.** Empty inputs, null, off-by-one, large inputs, concurrent access, error paths. Did you test them, or assume?
5. **Check the integration points.** Does your change break something else? Did you touch unrelated code? Are the imports right? Does the type system pass?
6. **Self-verify with the user's success criteria.** If they said "loads in under 200ms", did you measure? If they said "supports 1000 users", did you load test?

**What you must say (or not say) when you finish:**

- ✅ "Done. `npm test` passes 47/47. `curl localhost:3000/api/x` returns `{ok: true}`."
- ❌ "Should be working." / "I think this is fine." / "Done!" (with no evidence)
- ❌ "It works on my machine" (irrelevant — your machine is not the user's)

**Anti-rationalization:**

| Excuse | Reality |
|---|---|
| "I just wrote it, of course it works" | You have the most confirmation bias right after writing. Verify anyway. |
| "I tested it in my head" | Mental tests miss what runs miss. Run it. |
| "The user is busy, just say done" | The user will discover it's broken. They will be MORE busy. Be honest. |
| "It's a small change" | Small changes break things. Run the tests. |
| "I'm confident" | Confidence ≠ evidence. Quote the test output. |
| "I'll fix issues in the next round" | The next round won't happen if you claim it's done. Fix it now. |

**Failure mode this prevents:** Shipping a "finished" feature that's broken. The user's trust is the most expensive thing to lose.
> **Port of `verification-before-completion` from [obra/superpowers](https://github.com/obra/superpowers) v5.1.0.** Original by Jesse Vincent. Adapted to Hermes skill format.

# Verification Before Completion

## Overview

Claiming work is complete without verification is dishonesty, not efficiency.

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |

## Red Flags - STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"
- Tired and wanting work over
- **ANY wording implying success without having run verification**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |
| "Test ran on a fake, but the fake looks real" | A test on a malformed fixture (a fake key that doesn't satisfy the detector's regex, a fake JWT that doesn't parse) does not verify the detector. Validate the fixture matches the schema the system under test expects, before running the test. See `superpowers-test-driven-development` references/fixture-data-discipline.md. |

## Key Patterns

**Tests:**
```
✅ [Run test command] [See: 34/34 pass] "All tests pass"
❌ "Should pass now" / "Looks correct"
```

**Regression tests (TDD Red-Green):**
```
✅ Write → Run (pass) → Revert fix → Run (MUST FAIL) → Restore → Run (pass)
❌ "I've written a regression test" (without red-green verification)
```

**Build:**
```
✅ [Run build] [See: exit 0] "Build passes"
❌ "Linter passed" (linter doesn't check compilation)
```

**Requirements:**
```
✅ Re-read plan → Create checklist → Verify each → Report gaps or completion
❌ "Tests pass, phase complete"
```

**Agent delegation:**
```
✅ Agent reports success → Check VCS diff → Verify changes → Report actual state
❌ Trust agent report
```

## Why This Matters

From 24 failure memories:
- your human partner said "I don't believe you" - trust broken
- Undefined functions shipped - would crash
- Missing requirements shipped - incomplete features
- Time wasted on false completion → redirect → rework
- Violates: "Honesty is a core value. If you lie, you'll be replaced."

## When To Apply

**ALWAYS before:**
- ANY variation of success/completion claims
- ANY expression of satisfaction
- ANY positive statement about work state
- Committing, PR creation, task completion
- Moving to next task
- Delegating to agents

**Rule applies to:**
- Exact phrases
- Paraphrases and synonyms
- Implications of success
- ANY communication suggesting completion/correctness

## The Bottom Line

**No shortcuts for verification.**

Run the command. Read the output. THEN claim the result.

This is non-negotiable.

## E2E verification output template

When a deliverable is a **multi-file feature with several acceptance
criteria** (e.g. "the spec lists 7 things, did all 7 pass?"), produce
a numbered checklist as the final E2E report:

```
═══════════════════════════════════════════════════════════
  VERIFICACIÓN E2E — <feature name>
═══════════════════════════════════════════════════════════

--- 1. <criterion 1> ---
✓ <command run> | <key output line>

--- 2. <criterion 2> ---
✓ <command run> | <key output line>

...

═══════════════════════════════════════════════════════════
```

**Why numbered, not bulleted:** the user can scan and say "show me #5"
without rereading the whole report. The numbering also forces you to
enumerate every criterion (spec compliance), not just the easy ones.

**Each line must show:** the command that proves the criterion, and a
quoted output line. Not "tests pass" — `15 passed, 0 failed` quoted
from `test-foo.sh`.

**Final line under the separator:** a one-sentence summary of overall
status. If any criterion failed, that line must say so and list the
failing #s.
