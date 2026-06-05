---

name: superpowers-requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
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

**Trigger:** Before every `git commit`, every `git push`, every PR description, every "here's the diff" message. Code review happens BEFORE merge, not after.

**The rule: NO CODE IS COMMITTED WITHOUT A REVIEW PASS.**

**Review checklist (run on your OWN diff before claiming it's ready):**

1. **Re-read every changed file** with fresh eyes. Would you understand it in 6 months? Are names clear? Is there duplication?
2. **Security scan.** Hardcoded secrets? `eval()`? Unsanitized input? SQL injection? Open redirects? Auth bypasses? (Run `gitleaks detect` or equivalent.)
3. **Quality gates.** Linter passes? Type check passes? Tests pass? Coverage didn't drop?
4. **Spec compliance.** Does the code match what was approved in the spec/plan? Any deviation needs explicit justification.
5. **Diff size sanity.** >500 lines changed? Probably too much for one commit. Split it.
6. **Commit message.** Conventional commits? Explains WHY, not just WHAT? Linked to the issue/plan?

**The review-of-self output you must show the user before committing:**
- Summary of what changed (1-2 sentences)
- Test results (paste the relevant lines, not "tests pass")
- Linter/type results
- Any deviations from the spec (with justification)
- Known limitations (be honest, not exhaustive)

**Failure mode this prevents:** Committing a regression and finding it in production. Or committing secrets. Or committing something that doesn't compile.
> **Port of `requesting-code-review` from [obra/superpowers](https://github.com/obra/superpowers) v5.1.0.** Original by Jesse Vincent. Adapted to Hermes skill format.

# Requesting Code Review

Dispatch a code reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session's history. This keeps the reviewer focused on the work product, not your thought process, and preserves your own context for continued work.

**Core principle:** Review early, review often.

## When to Request Review

**Mandatory:**
- After each task in subagent-driven development
- After completing major feature
- Before merge to main

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

## How to Request

**1. Get git SHAs:**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

**2. Dispatch code reviewer subagent:**

Use Task tool with `general-purpose` type, fill template at `code-reviewer.md`

**Placeholders:**
- `{DESCRIPTION}` - Brief summary of what you built
- `{PLAN_OR_REQUIREMENTS}` - What it should do
- `{BASE_SHA}` - Starting commit
- `{HEAD_SHA}` - Ending commit

**3. Act on feedback:**
- Fix Critical issues immediately
- Fix Important issues before proceeding
- Note Minor issues for later
- Push back if reviewer is wrong (with reasoning)

## Example

```
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch code reviewer subagent]
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
  PLAN_OR_REQUIREMENTS: Task 2 from docs/superpowers/plans/deployment-plan.md
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: Ready to proceed

You: [Fix progress indicators]
[Continue to Task 3]
```

## Integration with Workflows

**Subagent-Driven Development:**
- Review after EACH task
- Catch issues before they compound
- Fix before moving to next task

**Executing Plans:**
- Review after each task or at natural checkpoints
- Get feedback, apply, continue

**Ad-Hoc Development:**
- Review before merge
- Review when stuck

## Red Flags

**Never:**
- Skip review because "it's simple"
- Ignore Critical issues
- Proceed with unfixed Important issues
- Argue with valid technical feedback

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

See template at: requesting-code-review/code-reviewer.md
