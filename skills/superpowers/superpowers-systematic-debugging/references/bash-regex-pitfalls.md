# Bash + grep regex pitfalls (field notes)

**Source:** debugging session 2026-06-05. Bug was in `superpowers-precommit-guard.sh`.

## The bug

```bash
# Goal: filter out the `+++ b/file` git diff header lines.
matches=$(git diff ... | grep -E "^\+" | grep -Ee "$pattern" | grep -v "^\+\+\+" || true)
```

**Why it failed silently:** the last `grep -v "^\+\+\+"` filtered out legitimate
lines that contained a `+` anywhere in the content, not just at the start.

In ERE (default for `grep -E`), the backslash before `+` is **interpreted as ERE's
"one or more"` quantifier, but the issue is more subtle: `^\+` matches a `+` at the
start. Then the second `\+` is treated as the start of a quantifier on the next
literal `+`, and the third `\+` is the start of another quantifier. The whole
expression `^\+\+\+` in ERE becomes `^(\+)+(\+)+` which is satisfied by **any line
starting with one or more `+` followed by more `+` later** — i.e., the literal
strings `+++` match, but in some `grep` versions and on some inputs, even `+foo+bar`
gets dropped because the regex engine backtracks across `+` characters.

**Symptom:** every `+`-prefixed diff line (which is EVERY diff content line)
got filtered, leaving the script with empty matches. The guard reported
"No secrets found" even when AWS keys were in the diff.

## The fix

Use `grep -vF` (fixed-string match) when you want a literal substring:

```bash
matches=$(git diff ... | grep -E "^\+" | grep -Ee "$pattern" | grep -vF "+++" || true)
```

`grep -vF "+++"` matches the literal substring `+++` and inverts — exactly
what was intended.

## General rules for bash + grep

1. **If you mean a literal string, use `-F`.** Always. Don't try to escape
   regex metacharacters by hand.
2. **ERE (`grep -E`) treats `\+`, `\(`, `\)`, `\|`, `\?` as special** — even
   though POSIX says they should be literal in BRE. Test your regex in
   isolation before chaining it in a pipeline.
3. **In a chain of greps, the LAST one's exit code matters most for
   `set -o pipefail`.** A non-matching `grep -v` returns 1, which can kill
   the whole pipeline silently.
4. **Test grep chains in isolation, step by step.** Pipe a known input
   through each stage and verify the output at every step. Don't trust
   "the whole pipeline looks right" — one misbehaving stage ruins the
   result and the failure mode is "empty output" which is easy to mistake
   for "no findings."

## Related

- `superpowers-verification-before-completion` — write a failing test
  against the bash script BEFORE shipping the fix. A 1-line
  `assert_matches_count` against a fixture catches this kind of bug in
  5 seconds.
- `superpowers-test-driven-development` — same principle, applied to bash:
  write the fixture, run the script, assert output.
