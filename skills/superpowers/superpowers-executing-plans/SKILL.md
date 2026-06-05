---
name: superpowers-executing-plans
description: "Use when you have a written implementation plan to execute in a separate session with review checkpoints"
version: "5.1.1"
author: "Jesse Vincent (obra) + Hermes enforcement"
license: MIT
platforms: [linux, macos]
namespace: superpowers
source: "https://github.com/obra/superpowers"
metadata:
  hermes:
    tags: [superpowers, methodology, workflow]
    homepage: "https://github.com/obra/superpowers"
---
> **Port of `executing-plans` from [obra/superpowers](https://github.com/obra/superpowers) v5.1.0.** Original by Jesse Vincent. Adapted to Hermes skill format.

# Executing Plans

## Overview

Load plan, review critically, execute all tasks, report when complete.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

**Note:** Tell your human partner that Superpowers works much better with access to subagents. The quality of its work will be significantly higher if run on a platform with subagent support (such as Claude Code or Codex). If subagents are available, use superpowers:subagent-driven-development instead of this skill.

## The Process

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Create TodoWrite and proceed

### Step 1.5 (Hermes) — Inventory the current state before Task 1

If the plan modifies an **existing system** (rather than building a greenfield project), the first thing you do is **inventory what already exists** before touching anything. This prevents two common failures:

- Re-implementing a script/feature that was already shipped by an earlier session, the upstream port, or the user's earlier work.
- Modifying a file that is *not* the canonical version (e.g. `.husky/pre-commit-superpowers` is a copy of `/opt/data/skills/.../scripts/superpowers-precommit-guard.sh` — edit the source, not the copy, and re-install).

Concretely, before Task 1, run an audit:

```bash
# 1. List the install / config directories
ls -la <install>/scripts/ ~/.local/bin/ <worktree>/.husky/ 2>/dev/null

# 2. For each existing executable, read its header
head -20 <script>.sh

# 3. Check for any existing config / bootstrap files
cat AGENTS.md .agents/* SOUL.md 2>/dev/null | head -50

# 4. Diff any in-worktree copies against the canonical source
diff <source> <worktree-copy>
```

If the audit surfaces an existing mechanism that does what the plan's Task N was going to build: **stop and report.** The plan needs to be updated to "reuse + fix" instead of "build from scratch." This is almost always faster and produces less drift.

If the audit surfaces an existing file that the plan will modify: confirm the worktree copy is in sync with the source. If not, plan to **regenerate the copy** from source after the change, not edit the copy in place.

This step is **Hermes-specific** (added 2026-06-05 after a session that re-implemented an existing guard and discovered it from the diff in step 4). For greenfield plans, skip it.

### Step 2: Execute Tasks

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed

### Step 3: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**

- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly
- The Step 1.5 audit surfaces an existing mechanism that supersedes a planned task

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**

- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking
- The Step 1.5 audit changes the plan's scope (e.g. you found an existing mechanism that needs fixing instead of a new one that needs building)

**Don't force through blockers** - stop and ask.

## Remember

- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent
- For existing-system work, inventory the current state (Step 1.5) before Task 1

## Integration

**Required workflow skills:**

- **superpowers:using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing)
- **superpowers:writing-plans** - Creates the plan this skill executes
- **superpowers:finishing-a-development-branch** - Complete development after all tasks
- **hermes-skill-enforcement** - For plans that add enforcement mechanisms (layer 5) on top of an existing system
