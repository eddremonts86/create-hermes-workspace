# Fixture-data discipline in TDD (field notes)

**Source:** session 2026-06-05, security audit feature.

## The pattern that bit me

I was testing a gitleaks-based secret scanner. I wrote a "fake" AWS key
as a test fixture:

```bash
echo "AWS_ACCESS_KEY_ID=***" > secret-leak.sh
```

I ran the test. **gitleaks did not flag it.** I assumed the scanner was
broken. I debugged for 20 minutes — checked JSON parsing, regex filters,
gitleaks flags, exit codes, you name it. Eventually I looked at the
gitleaks rule for `aws-access-token`:

```
aws-access-token: AKIA[0-9A-Z]{16}
```

The regex requires 16 alphanumeric characters immediately after `AKIA`.
My fake key `AKIAIO...MPLE` had `IO` (2 chars), then `...` (three literal
dots, not alphanumeric), then `MPLE` (4 chars). The 16-alphanumeric run
**never existed** in my fake.

I had been testing the scanner with garbage data. Every test "failure"
was a test that proved nothing.

## The lesson

When the system under test has a **grammar or schema** (regex, parser,
validator, deserializer), your fixture data must satisfy that grammar.
A "fake" that doesn't match the grammar is **not a test** — it's noise.

**The test the user wanted**: "when a real key is in the diff, the
scanner blocks." **The test I wrote**: "when a malformed pseudo-key is
in the diff, the scanner blocks." Those are different tests, and the
second one passes for the wrong reason (or fails for the wrong reason).

## Concrete rules

1. **For regex tests, use a string that the regex actually matches.**
   Open the rule definition, copy the literal pattern, and feed a
   minimal but **schema-valid** input. `AKIA` + 16 uppercase alphanumerics
   is what gitleaks wants, not `AKIAIO...MPLE`.
2. **Verify your fixture against the rule by hand before testing the
   detector.** Run the regex in `grep -E` or `python -c 'import re;
   re.search(...)'` on your fixture and confirm a match. If grep says
   "no match," the fixture is broken — the test result is meaningless.
3. **For parser tests, use a minimal but parseable input.** An
   intentionally-malformed fixture belongs in a "negative" test, not in
   a "detector fires" test.
4. **When a test "fails," check the fixture first.** Before debugging the
   detector, verify the input satisfies the schema the detector is
   looking for. Debugging the wrong layer wastes 20 minutes.
5. **When a test "passes," check that the fixture actually exercises the
   path.** A test that passes because the fixture was malformed (and
   thus never reached the detector) is worse than no test — it gives
   false confidence.

## How to construct valid fixtures

- **Look at the rule definition first.** Copy the literal pattern.
- **Generate the fixture with code, not by hand.** A 5-line Python
  snippet that produces a key matching the regex is more reliable than
  typing one in the shell where you can typo, drop a char, or paste
  `***` because your secret manager redacted it.
- **Have the fixture self-validate.** Add a `grep -E "$pattern" $fixture
  || { echo "fixture broken"; exit 1; }` line at the top of the test
  script. If the fixture doesn't match the rule the detector uses, the
  test script aborts before running the system under test.

## Example: valid vs invalid fixture

**Bad (what I did):**
```bash
echo 'aws_key = "AKIAIO...MPLE"' > test-secret.py
# looks like a key, isn't
```

**Good (what works):**
```bash
# Generate a valid 16-char alphanumeric suffix
KEY="AKIA$(printf '%s' {A..Z}{0..9} | fold -w 1 | shuf -n 16 | tr -d '\n')"
echo "aws_key = \"$KEY\"" > test-secret.py
# verify the fixture is valid BEFORE testing the detector
grep -qE 'AKIA[0-9A-Z]{16}' test-secret.py || { echo "broken fixture"; exit 1; }
```

## Related

- `superpowers-systematic-debugging` Phase 3: hypothesis testing requires
  valid test data, otherwise you're testing your fixture, not the system.
- `superpowers-verification-before-completion`: a "passing" test with a
  malformed fixture does not verify anything.
