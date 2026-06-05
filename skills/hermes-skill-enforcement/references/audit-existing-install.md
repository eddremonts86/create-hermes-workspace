# Audit an existing install before adding layer-5 enforcement

A common failure mode when adding enforcement (cron audits, wrapper scripts, pre-commit hooks): you write a new mechanism from scratch, only to discover that **the install already shipped with one** — from a previous session, a sister project, or the upstream porting script. You then have two competing mechanisms that drift apart over time.

This reference is the 5-minute checklist to run **before** writing any layer-5 code.

---

## The 5-minute audit

Run these commands from the install root (e.g. `/opt/data/skills/superpowers/` for the superpowers install) and the user's home.

### 1. Inventory the scripts directory

```bash
ls -la <install>/scripts/
```

For superpowers, this surfaces `sync-from-upstream.sh`, `superpowers-self-check.sh`, `superpowers-precommit-guard.sh`, `install-precommit-guard.sh`, etc. **Read the headers** of any executable script — they document what the script does and how to install/use it.

### 2. Check for an existing self-check or audit

```bash
find <install> -name "*check*.sh" -o -name "*audit*.sh" -o -name "*health*.sh" 2>/dev/null
```

If a self-check exists, **run it once** to confirm the install is currently healthy. This is also your baseline; layer-5a (cron audit) is just "run the existing self-check on a schedule."

### 3. Check for an existing wrapper or commit gate

```bash
ls -la ~/.local/bin/ 2>/dev/null
which sp-commit sp-test sp-build 2>/dev/null
```

If a wrapper exists, **read it** before writing a new one. The existing one might have hard-won fixes (the bash ERE gotcha, the TTY bypass refusal) that a from-scratch version will lack.

### 4. Check for an existing husky/pre-commit hook in the worktree

```bash
ls -la <worktree>/.husky/ 2>/dev/null
cat <worktree>/.husky/pre-commit 2>/dev/null
```

If a `pre-commit-superpowers` already exists in the worktree, **diff it against the latest source script** before re-installing. The worktree copy may have local fixes the source doesn't, or vice versa.

```bash
diff <install>/scripts/superpowers-precommit-guard.sh <worktree>/.husky/pre-commit-superpowers
```

### 5. Check for an existing AGENTS.md or equivalent

```bash
cat /opt/data/AGENTS.md 2>/dev/null | head -50
ls /opt/data/.agents/ /opt/data/SOUL.md 2>/dev/null
```

The bootstrap file is the contract between "what the model should do" and "what gets enforced." If one already exists, your layer-5 additions go **into it** (a new gate row, a new anti-rationalization block) — not as a parallel document.

### 6. Check for existing cron jobs (Hermes)

```bash
# Use the cronjob tool, not crontab:
# (Hermes-specific; system crontab is a different scheduler)
cronjob action=list
```

If a job with a similar name exists, **read its prompt** before adding a new one. The existing job may already do what you planned, just with different scheduling or output routing.

---

## What to do with the audit results

| If you find... | Then... |
|---|---|
| A self-check script | Reuse it. Wrap a cron job around it. Don't rewrite. |
| A wrapper script with a hard-won fix | Copy it, don't re-author. Update its references (PATH, AGENTS.md) rather than replacing its body. |
| A pre-commit hook in the worktree | Diff against source. If the worktree copy is newer or has local fixes, **promote those fixes back to the source** so future installs get them. |
| A bootstrap file (AGENTS.md / .agents / SOUL.md) | Edit it in place. Add your gate as a new row + new section, not as a parallel document. |
| An existing cron job doing similar work | Update its prompt and schedule, don't add a competing job. |
| An old version of a script in `/opt/data/...` with no consumer | Either delete it (if the new version supersedes it) or alias the new one to the old path (if anything still calls the old path). Don't leave zombies. |

---

## Worked example: the superpowers install audit (June 2026)

When adding the 4 new "world-class quality" layer-5 mechanisms (cron audit, `sp-commit` wrapper, husky guard, `triage` skill), the audit found:

1. **`superpowers-self-check.sh`** already existed at `/opt/data/skills/superpowers/scripts/`. It checked AGENTS.md size, 17 skill directories (was 17 — needed update to 18 after adding triage), executable bits on helper scripts, and upstream drift. **Verdict: reuse; wrap a cron job around it; bump the skill count to 18.**

2. **`superpowers-precommit-guard.sh` + `install-precommit-guard.sh`** already existed. The guard was solid in design (secret patterns, debug patterns, diff size, conventional commit subject, plan-file reference) but had a real bug: `grep -v '^\+\+\+"` over-filtered (ERE `\+` trap; see `bash-pitfalls.md`). **Verdict: fix the bug, then install via the existing installer.**

3. **No `sp-commit` wrapper** — the AGENTS.md only had Gate 5 (self-review before commit) but no enforcement mechanism. **Verdict: write the wrapper as a layer-5b mechanism, add Gate 6 to AGENTS.md.**

4. **No `superpowers-triage` skill in the SKILL.md index** — the skill existed at `/opt/data/skills/superpowers/superpowers-triage/SKILL.md` but wasn't referenced in the meta-index or AGENTS.md. **Verdict: add to the index and to AGENTS.md, don't rewrite the skill body.**

5. **Cron job didn't exist** — the only scheduled work was system-level (root crontab, not visible to user). **Verdict: create a `cronjob`-tool job (not system crontab) running `superpowers-self-check.sh` weekly.**

Net result: 2 of the 4 layer-5 mechanisms were **already done** (self-check, pre-commit-guard); 1 needed a bug fix; 1 needed to be created from scratch. Saved maybe an hour of redundant authoring and avoided the "two scripts that drift apart" failure mode.

---

## When to skip the audit

The audit is **not free** — it costs 5 minutes and several `cat` / `ls` calls. Skip it when:

- You're starting from a **greenfield install** (no prior sessions, no existing scripts).
- The user has explicitly told you "this is a brand new install, nothing here yet."
- You're working on a **single-file change** in a known-stable system (e.g. tweaking the `superpowers-self-check.sh` skill count, not adding a new mechanism).

Run it when in doubt. The cost of an unnecessary audit is 5 minutes; the cost of duplicating an existing mechanism is "the two drift apart and the user gets confused which one is canonical."
