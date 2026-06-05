# AGENTS.md — Agent Workflow Contract

> This file is read by the Hermes Agent on every session. It defines the
> workflow rules the agent must follow. **You can edit it** to suit your
> team's conventions, but the default below is the recommended starting
> point for solo and small-team use.

## TL;DR

- **Brainstorm** any non-trivial feature into a written design before coding.
- **Plan** the implementation as bite-sized tasks.
- **TDD** — write a failing test, then make it pass, then refactor.
- **Verify** — run the tests, exercise the result, show the evidence.

These four gates exist because skipping them costs days; following them costs minutes.

---

## Gate 1 — Brainstorm (for new features)

Before writing code for anything bigger than a 1-line tweak:

1. Use the `superpowers-brainstorming` skill. It will guide you through:
   - understanding the current project state
   - asking one question at a time
   - proposing 2-3 approaches with trade-offs and a recommendation
   - presenting the design in sections, getting approval for each
2. Once approved, write the design to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`.
3. Commit the design doc.
4. Wait for explicit user approval before moving on.

**Why:** Description ≠ aligned understanding. A 5-minute brainstorm prevents a 2-day rewrite.

---

## Gate 2 — Plan (for medium / large features)

After the design is approved:

1. Use the `superpowers-writing-plans` skill to break the work into bite-sized tasks.
2. Each task gets: exact file paths, exact verification steps, an estimated size.
3. If the plan takes more than 5 minutes to read, split it.
4. Commit the plan to `docs/superpowers/plans/`.
5. Wait for explicit user approval.

---

## Gate 3 — TDD (per task)

For every plan task:

1. **RED** — write a failing test that captures the requirement.
2. Verify it fails for the right reason.
3. **GREEN** — write the minimum code to make it pass.
4. Verify all tests pass.
5. **REFACTOR** — clean up while keeping tests green.
6. **Commit** using `sp-commit` (never `git commit` directly — see the AGENTS.md in the workspace root).

The `superpowers-test-driven-development` skill has the full discipline.

---

## Gate 4 — Verify (before claiming "done")

Before saying "done":

- Re-read the spec. Re-read what the user asked for. Are they the same?
- Run the full test suite. Quote the output.
- Manually exercise the new behavior. Quote the result.
- Check edge cases, error paths, integration points.
- Show the user the evidence.

The `superpowers-verification-before-completion` skill has the full checklist.

---

## Mandatory skill loading

These skills are **non-negotiable** and must be loaded automatically when relevant:

- `superpowers-skill-routing` — on session start, to pick the right skill.
- `superpowers-brainstorming` — before any creative work.
- `superpowers-test-driven-development` — before writing production code.
- `superpowers-verification-before-completion` — before claiming done.
- `superpowers-requesting-code-review` — before every commit.
- `superpowers-finishing-a-development-branch` — when wrapping up.

If a skill has issues, fix it with `skill_manage(action='patch')` immediately.

---

## Directory layout

```
hermes-workspace/                ← this folder (the agent's $PWD)
├── Dockerfile
├── docker-compose.yml
├── .env.example
├── .gitignore
├── AGENTS.md                    ← you are here
├── Makefile
├── README.md
├── scripts/
│   ├── bootstrap.sh             # non-Docker one-shot installer
│   └── publish.sh               # re-publish wrapper for the npm package
├── skills/                      # drop new skills here
│   ├── edd-app-template/
│   ├── superpowers/
│   ├── ailab/
│   ├── github/
│   ├── software-development/
│   └── hermes-skill-enforcement/
├── docs/                        # specs, plans, postmortems
│   └── superpowers/
│       ├── specs/
│       └── plans/
└── worktrees/                   # new app projects go here (via make new-project)
    └── <name>/
```

---

## What the agent will and won't do

**Will:**

- Read any file in the workspace.
- Run any command inside the container.
- Edit, create, and delete files.
- `git add` / `git commit` (via `sp-commit` wrapper) / `git push` on your behalf.
- Search the web, fetch documentation, install packages.
- Open PRs, file issues, post comments (with your `GITHUB_USER` configured).

**Won't (by default):**

- Send emails, post to social media, or call external paid APIs without confirmation.
- Make commits on a protected branch (`main`, `master`, `release/*`) without you running `sp-commit` interactively.
- Push to a remote you haven't configured.
- Run `rm -rf` outside the workspace.

If you want any of the "won't" behaviors to be the default, edit this file. The agent reads it on every session.

---

## Editing this file

This is your workflow contract. Common edits:

- **Add a hard rule** (e.g. "always run `pnpm lint` before committing"):
  add a new "Gate" section above with the rule and the rationale.
- **Loosen a rule** (e.g. allow direct `git commit` for trivial typos):
  edit the relevant gate's "What" section.
- **Add a new mandatory skill**:
  add it to the "Mandatory skill loading" list.

After editing, run `make up` to restart the container and the agent will pick up the new rules on its next session.
