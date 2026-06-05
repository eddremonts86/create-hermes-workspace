# Bash pitfalls that bite layer-5 (pre-commit hooks, wrappers, audits)

Quick reference for the bash gotchas that silently break enforcement scripts. Each pitfall has a real example from a session that found and fixed the bug. Read this **before** writing any layer-5c script; check your script against the verification commands **before** declaring it works.

---

## Pitfall 1 — `grep -v "^\+\+\+"` is an ERE disaster

**Symptom:** A pre-commit guard that should block `console.log()` or `AKIA...XXXX` in the diff silently lets it through. The script reports "No secret patterns found" / "No debug code patterns found" on input that obviously matches.

**Root cause:** `\+` in a regex is **ERE syntax** meaning "one or more of the previous char." So `grep -v "^\+\+\+"` is interpreted as "filter out any line containing `+`+ — i.e. any line with two or more consecutive `+`s" — NOT "filter out the diff header `+++ b/file`."

Test it:

```bash
echo '+aws_key = "AKIAIO...XXXX"' | grep -v "^\+\+\+"
# Output: NOTHING. The line is filtered (because it contains "++" inside).
# But the line is a legitimate `+` added line that SHOULD have been scanned.

echo '+++ b/file.py' | grep -v "^\+\+\+"
# Output: NOTHING. Good (header is filtered as intended).
# But the previous test shows the filter is over-aggressive.
```

**Fix:** use `grep -vF` (literal string) for ASCII art delimiters like `+++`:

```bash
# WRONG — silently over-filters
matches=$(git diff --cached -U0 | grep -E '^\+' | grep -Ee "$pattern" | grep -v '^\+\+\+' || true)

# RIGHT — filters only the literal "+++" header
matches=$(git diff --cached -U0 | grep -E '^\+' | grep -Ee "$pattern" | grep -vF '+++' || true)
```

**The general rule:** any time you want to filter a literal sequence of `+`, `?`, `*`, `(`, `)`, `|`, `{`, `}` — use `grep -F` (fixed string) or escape every metachar with `\\`. ERE is the default for `grep -E` and you can be silently over-matching.

**Verification command for layer-5c guards:**

```bash
# Should FAIL (block commit, exit 1) — staged secret with valid format
echo 'aws_key = "AKIA1234567890ABCDEFG"' > /tmp/secret.py
git add /tmp/secret.py
.git/hooks/pre-commit-superpowers; echo "exit=$?"   # expected: exit 1

# Should WARN (exit 2) — staged debug code
echo 'console.log("x")' > /tmp/dbg.ts
git add /tmp/dbg.ts
.git/hooks/pre-commit-superpowers; echo "exit=$?"   # expected: exit 2

# Should PASS (exit 0) — staged clean file
echo "ok" > /tmp/clean.txt
git add /tmp/clean.txt
.git/hooks/pre-commit-superpowers; echo "exit=$?"   # expected: exit 0
```

If any of these exit codes is wrong, the guard is broken. Don't trust the script's printed "All pre-commit guards passed" — that print is what the bug was hiding behind.

---

## Pitfall 2 — `set -e` + grep pipeline inside a loop

**Symptom:** Inside a `for pattern in "${patterns[@]}"` loop, the first iteration works but subsequent ones report "no match" for patterns that DO match.

**Root cause:** `set -e` (errexit) treats a non-zero exit from any command as a fatal error. `grep` returns non-zero when it finds nothing. Inside a `$(...)` command substitution, this can interact badly with `pipefail`.

**The standard workaround that the existing guard uses:**

```bash
for pattern in "${patterns[@]}"; do
  set +e +o pipefail              # disable errexit+pipefail for this scope
  matches=$(... grep pipeline ... || true)   # the `|| true` neutralizes the last grep
  set -e -o pipefail              # re-enable
  if [ -n "$matches" ]; then
    fail "..."
  fi
done
```

This works — but the `|| true` only covers the LAST command in the pipeline. If an earlier `grep` has `set -o pipefail` re-enabled by the surrounding scope, the whole pipeline can still fail and zero out `matches` for the wrong reason.

**Safer pattern:** capture exit code explicitly and use a single `||` outside the subshell:

```bash
for pattern in "${patterns[@]}"; do
  set +e
  matches=$(git diff --cached -U0 | grep -E '^\+' | grep -Ee "$pattern" | grep -vF '+++')
  grep_rc=$?
  set -e
  # matches may be empty even if the pattern matched, due to how the pipe collapsed;
  # use the diff size + a second independent check if this matters
  if [ -n "$matches" ]; then
    fail "..."
  fi
done
```

Or, more readably, do the secret/debug scan in **Python** rather than bash — bash pipelines of greps are the most common silent-failure surface in layer-5 scripts.

---

## Pitfall 3 — `sp-commit` (or any wrapper) is bypassed when PATH doesn't include it

**Symptom:** Wrapper script exists at `~/.local/bin/sp-commit`, is executable, but `git commit` is still callable directly and the model uses it.

**Root cause:** The wrapper only works if it's in the model's effective `PATH`. Many agent runtimes (Hermes included) don't source `~/.bashrc` for non-interactive shells; they get a minimal PATH that doesn't include `~/.local/bin/`.

**Fix:** explicitly export PATH in the shell that the agent uses. For Hermes, the home dir is `/opt/data/home` (per `HERMES_HOME=/opt/data` and `HOME=/opt/data/home`); the agent's PATH includes `/usr/local/bin:/usr/bin:/bin` and that's it. So:

```bash
# Either (a) add to .bashrc AND .profile AND /etc/profile.d/
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.profile

# Or (b) put the wrapper in a dir the agent already has in PATH
cp sp-commit /usr/local/bin/sp-commit

# Or (c) full-path the wrapper in AGENTS.md so the model is told the absolute path
# AGENTS.md: "Use /opt/data/home/.local/bin/sp-commit, never bare `git commit`."
```

**Verification:** after install, run `which sp-commit` from inside the same shell the model uses. If it returns the wrapper, you're good. If it returns nothing or the real `git`, the wrapper is dead weight and the model will keep calling `git commit` directly.

---

## Pitfall 4 — `cron job` tool vs system crontab

**Symptom:** You `crontab -e` a weekly audit job, but it never runs (or runs without output).

**Root cause:** The Hermes `cronjob` tool (`action='create'`) is **not** the same as system crontab. They're separate schedulers with separate state. If the install ships with one, use it; don't double up.

**For Hermes specifically:** use the `cronjob` tool, not `crontab`. The tool delivers output to the user's home channel (configurable with `deliver=`). System `crontab` runs as a different user (often `root`) and writes to a different mailbox the user doesn't see.

**Verification:** after creating a `cronjob`, run `action='list'` to confirm it's there. Then run `action='run'` to force a tick and observe the output. Don't trust "scheduled" until you've seen it execute.

---

## Pitfall 5 — Husky hook gets bypassed by `--no-verify`

**Symptom:** A bad commit lands despite the pre-commit guard being installed.

**Root cause:** `git commit --no-verify` skips pre-commit hooks. The model (or the user) can type this and bypass the gate silently.

**This is not a bug, it's a design decision.** The gate is enforceable for the standard path; bypass is the user's escape hatch. To make bypasses visible:

- Add a post-commit hook that runs `git log --oneline` and flags any `--no-verify` commits in the output.
- Or: configure the agent's commit wrapper (`sp-commit` from layer 5b) to refuse `--no-verify` unless an explicit `SP_BYPASS_REASON=...` env var is set, and to log the reason to a sentinel file.

**The model-cannot-skip test:** if the model can call `git commit --no-verify` without your noticing, you have not added enforcement; you have added a *recommendation* that a sufficiently lazy model can ignore.

---

## General verification protocol for any new layer-5 script

Before declaring a layer-5 mechanism "done":

1. **Test the negative path:** does it block what it should block? (Staged `console.log`, staged fake-but-valid AWS key, oversized diff.) Capture the actual exit code, not just the printed message.
2. **Test the positive path:** does it pass what it should pass? (Staged clean file, no staged changes.)
3. **Test the bypass path:** can the model bypass it? (`--no-verify`, `SP_COMMIT_SKIP=1`, direct path to the real command.) If yes, the gate is advisory; document that.
4. **Test the silent-failure surface:** if the script depends on `PATH`, test from a non-interactive shell. If it depends on a directory existing, test after deleting the directory. If it depends on a pattern, test with a real input that matches the pattern (not a fake that "looks right" to a human but doesn't match the regex).
5. **Read the printed output skeptically.** "All pre-commit guards passed" is the script claiming it checked things; the actual gate is the exit code, not the print.
