---
title: "Bash TDD patterns — lessons from superpowers scripts"
tags: [bash, tdd, jq, validation, scripts]
applies_to: bash scripts, shellcheck-clean, set -u safe
---

# Bash TDD patterns (learned the hard way)

These are reusable patterns for **writing scripts with TDD discipline
in bash**, distilled from 3 rounds of building `superpowers-log-event.sh`,
`superpowers-stats`, `superpowers-purge.sh`, and others. Not the same as
"how to bash" — these are the patterns where naive code breaks, found
during actual TDD red/green cycles.

---

## Pattern 1 — RED first with a fixture-based verifier

The classic TDD red step in bash:

```bash
# tests/whatever/test-foo.sh
SCRIPT="/opt/data/.../foo.sh"
if [ ! -x "$SCRIPT" ]; then
  err "Script not found: $SCRIPT"   # RED fails because script doesn't exist
  exit 1
fi
# ... assertions
```

**Why this is real TDD, not "test after":** running the verifier
*before* writing the script confirms the test fails for the right
reason (script missing). If your test passes when the script is empty,
your test is testing the wrong thing.

**Pitfall:** writing tests that *describe* the implementation
("creates a file at /opt/data/var/...") instead of *behavior*
("appends a valid JSON line to a JSONL log"). Behavior tests survive
refactors; description tests don't.

---

## Pattern 2 — `jq -rs` slurp, NOT `[inputs]`

`[inputs]` (or `[.[] | ...]` over a stream) **silently drops the
first element of the stream**. This is a known jq gotcha. Symptom:
your table is missing the first row; you spend 20 minutes wondering
why the JSONL file is correct but the table is off-by-one.

**Wrong (drops first event):**
```bash
jq -r '[inputs] | .[] | ...' < events.jsonl
```

**Right (slurp into a real array):**
```bash
jq -rs '. as $events | ($events | map(.gate) | ...)' < events.jsonl
```

`-s` (slurp) reads the entire input as a single array. `-r` (raw output)
strips the JSON quotes from string outputs. Together: deterministic,
handles JSONL correctly.

**Test the slurp behavior explicitly.** A 3-event JSONL must produce
3 rows in the table. If you only test with 1 event, the bug is
invisible.

---

## Pattern 3 — `set -u` + numeric comparison without `|| echo 0`

When you do `set -u` and a command inside `$()` returns an empty
string, downstream arithmetic blows up. The naive fix
`$(cmd || echo 0)` looks right but `cmd` may print to stderr that
gets re-included in the variable.

**Wrong:**
```bash
errs=$(shellcheck -f json "$f" | jq '[.[] | select(.level=="error")] | length' || echo 0)
total=$((total + errs))   # CRASH if errs is "" (set -u) or contains stderr noise
```

**Right:**
```bash
errs=$(shellcheck -f json "$f" 2>/dev/null | jq '[.[] | select(.level=="error")] | length' 2>/dev/null)
[[ "$errs" =~ ^[0-9]+$ ]] || errs=0
total=$((total + errs))
```

The regex check is the key: it validates the output is a number
*before* doing arithmetic. If you skip it, you get a
`syntax error: operand expected` deep in a script and lose 15 minutes
finding it.

**Test the validation explicitly:** feed a non-JSON file
(shellcheck-failing, jq-failing) and assert the count comes out as `0`,
not crash.

---

## Pattern 4 — TDD verifier structure that survives refactor

A verifier that holds up across iterations looks like this:

```bash
# 1. Counters and color helpers at the top
pass=0; fail=0
ok()  { printf '  \033[0;32m✓\033[0m %s\n' "$*"; pass=$((pass+1)); }
err() { printf '  \033[0;31m✗\033[0m %s\n' "$*"; fail=$((fail+1)); }

# 2. Sanity check: script exists (RED for new scripts)
if [ ! -x "$SCRIPT" ]; then
  err "Script not found: $SCRIPT"
  echo "Result: 0 passed, 1 failed"
  exit 1
fi
ok "Script exists and is executable"

# 3. Backup any real data
backup=$(mktemp); [ -f "$REAL" ] && cp "$REAL" "$backup"
rm -f "$REAL"

# 4. Run scenarios, assert behaviors (not implementations)

# 5. Restore real data
[ -f "$backup" ] && mv "$backup" "$REAL" || rm -f "$REAL"

# 6. Final result + exit code
echo "Result: $pass passed, $fail failed"
[ "$fail" -ne 0 ] && exit 1 || exit 0
```

**Why the backup/restore:** TDD verifiers touch real data files
(`/opt/data/var/gate-events.jsonl`). Without backup/restore, the test
pollutes the real log. Worse, a bug in the script could delete
production data.

**Why `exit 0` only when `fail == 0`:** a verifier that "passes" with
7 OK and 2 ERR confuses CI. Make the exit code the source of truth.

---

## Pattern 5 — Shellcheck: avoid em-dashes in comments

`shellcheck` interprets `# shellcheck` (note the space) as a
**directive** and tries to parse the rest of the line as options. An
em-dash (`—`) or a colon (`:`) after `shellcheck` confuses the parser:

```bash
# shellcheck — ONLY level: error findings (warnings don't block)
# ↑↑ shellcheck thinks "ONLY level: error findings" is a directive value
#    and fails with "shellcheck directive error" on the next run.
```

**Fix:** use plain ASCII or rephrase:

```bash
# Tools and what blocks:
#   gitleaks   - ANY secret leak (always blocks)
#   sc         - ONLY level: error findings (warnings do not block)
#   bandit     - ONLY issue_severity: HIGH
#   semgrep    - ONLY severity: ERROR
```

**Test it:** run `shellcheck -f json` on your script and assert the
output is `[]` (no findings). A self-test catches the em-dash bug
before the user does.

---

## Pattern 6 — `[ "$x" -gt 0 ]` vs `(( x > 0 ))` with `set -u`

`set -u` plus `(( x > 0 ))` blows up if `x` is unset or empty,
because `(( ))` evaluates to a non-zero exit code and triggers
`set -e`. Use `[ "$x" -gt 0 ]` instead — it's string-based, doesn't
trigger `set -e` on empty, and the intent is clearer.

```bash
set -euo pipefail
count=0
count=$(jq 'length' "$file")
(( count > 0 )) && echo "has rows"   # CRASH: (( 0 > 0 )) exits 1
[ "$count" -gt 0 ] && echo "has rows"   # OK
```

**Test it:** after a script that reads JSON, assert the downstream
branch was reached when the count is 0. This catches `set -e`
crashes that "work" when count is non-zero.

---

## Anti-pattern: bash TDD with mocks

Resist the urge to mock the file system, environment, or `jq` in bash
tests. Bash tests are **integration tests by nature** — the script,
the FS, the tools, and the JSONL all interact. Mocking any of them
gives you a test that passes on a fake world.

**Right way to test "what if the log file is missing?":** delete the
file, run the script, assert the right thing happens (no-op, exit 0,
or "log file not found" message — whichever is in the spec).

**Wrong way:** set `LOG_FILE=/tmp/fake` in a test runner and assert
the script writes to `/tmp/fake`. Now your test passes when the
script is broken in production because the real `LOG_FILE` differs.
