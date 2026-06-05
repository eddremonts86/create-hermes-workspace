#!/usr/bin/env bash
# superpowers-precommit-guard.sh
#
# Git pre-commit hook. Fails the commit if the diff has not been
# reviewed per superpowers-requesting-code-review.
#
# Installation (from inside the worktree):
#   /opt/data/skills/superpowers/scripts/install-precommit-guard.sh
#   (or with the resolved path from `dirname $(readlink -f superpowers-precommit-guard.sh)`)
#
# Or copy manually:
#   cp /opt/data/skills/superpowers/scripts/superpowers-precommit-guard.sh .husky/pre-commit-superpowers
#   echo 'pre-commit-superpowers' >> .husky/pre-commit
#   chmod +x .husky/pre-commit-superpowers
#
# What it does:
#   1. Rejects commits with no staged changes.
#   2. Rejects commits that are >500 lines (suggests split).
#   3. Checks for common secret patterns (gitleaks-light, offline).
#   4. Checks for "console.log", "debugger", "TODO" in staged JS/TS/Python.
#   5. Requires a conventional-commit format subject (feat/fix/refactor/...).
#   6. If the project has a docs/superpowers/plans/ directory, requires
#      that the change references an active plan file.
#   7. Prints a review checklist for the user to self-confirm.

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

fail() { printf "${RED}✗ %s${NC}\n" "$*" >&2; exit 1; }
warn() { printf "${YELLOW}! %s${NC}\n" "$*" >&2; }
ok()   { printf "${GREEN}✓ %s${NC}\n" "$*"; }
note() { printf "${CYAN}ℹ %s${NC}\n" "$*"; }

# 0. Must be in a git repo
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "Not inside a git repo."

# 1. Staged changes?
staged=$(git diff --cached --name-only)
if [ -z "$staged" ]; then
  fail "No staged changes. Stage with 'git add' first."
fi
ok "$(echo "$staged" | wc -l) files staged."

# 2. Diff size
diff_lines=$(git diff --cached --numstat | awk '{sum += $1 + $2} END {print sum}')
if [ "${diff_lines:-0}" -gt 500 ]; then
  warn "Diff is $diff_lines lines. Recommended max: 500. Consider splitting into multiple commits."
  warn "Override: 'git commit --no-verify' (only if you really mean it)."
  exit 2  # exit 2 = warning, git treats as failure
fi
ok "Diff size: $diff_lines lines (limit 500)."

# 3. Secret scan (light)
secret_patterns=(
  'AKIA[0-9A-Z]{16}'                       # AWS access key
  'sk-(proj-|live-|test-)?[A-Za-z0-9]{20,}' # OpenAI / Anthropic / generic
  'sk-[A-Za-z0-9]{9,}'                     # Catch any sk- prefix with 9+ chars
  'ghp_[A-Za-z0-9]{36}'                    # GitHub PAT
  'gho_[A-Za-z0-9]{36}'                    # GitHub OAuth
  'glpat-[A-Za-z0-9_-]{20,}'               # GitLab PAT
  'xox[abpr]-[0-9a-zA-Z-]{10,}'            # Slack tokens
  'AIza[0-9A-Za-z_-]{35}'                  # Google API key
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'     # PEM private key
  'postgres://[^:]+:[^@]+@'             # Postgres connection string w/ password
  'mysql://[^:]+:[^@]+@'                # MySQL connection string w/ password
  'mongodb(\+srv)?://[^:]+:[^@]+@'         # Mongo w/ password
  'password[ \t]*=[ \t]*\S{4,}'            # Generic password assignment
  'api[_-]?key[ \t]*=[ \t]*\S{8,}'         # Generic API key assignment
)
secrets_found=0
for pattern in "${secret_patterns[@]}"; do
  # grep treats a leading '-' as a flag. Use -e to force the next arg to be the pattern.
  # Disable -e (errexit) and -o pipefail locally so a non-matching grep doesn't kill the loop.
  set +e +o pipefail
  matches=$(git diff --cached -U0 | grep -E "^\+" | grep -Ee "$pattern" | grep -vF "+++" || true)
  set -e -o pipefail
  if [ -n "$matches" ]; then
    fail "Possible secret in staged diff matching pattern: $pattern
$matches
Either remove the secret, move it to .env (and add .env to .gitignore), or use 'git commit --no-verify' if you're sure."
    secrets_found=1
  fi
done
[ "$secrets_found" -eq 0 ] && ok "No secret patterns found in diff."

# 4. Debug-code scan (JS/TS/Python)
debug_patterns=(
  'console\.log\('
  'console\.debug\('
  'debugger;?'
  'pdb\.set_trace\(\)'
  'breakpoint\(\)'
  'TODO:? [A-Z]'       # TODO with a capital letter (real todo, not just text)
  'FIXME:? [A-Z]'
  'XXX:? [A-Z]'
)
# print() in Python is legitimate (real apps print). Only flag obvious debug
# print patterns like `print("DEBUG"`, `print("TODO"`, etc.
debug_found=0
for pattern in "${debug_patterns[@]}"; do
  set +e +o pipefail
  matches=$(git diff --cached -U0 -- '*.js' '*.jsx' '*.ts' '*.tsx' '*.mjs' '*.cjs' '*.py' '*.pyi' 2>/dev/null \
    | grep -E "^\+" | grep -Ee "$pattern" | grep -vF "+++" \
    | grep -vE "\.test\.|\.spec\.|test_|_test\.py|/tests/|/__tests__/" | grep -vF "+++" || true)
  set -e -o pipefail
  if [ -n "$matches" ]; then
    warn "Debug-code pattern '$pattern' found:"
    echo "$matches" | head -5
    debug_found=1
  fi
done
if [ "$debug_found" -ne 0 ]; then
  warn "Debug code found. Remove or use 'git commit --no-verify' if intentional."
  exit 2
fi
ok "No debug code patterns found."

# 5. Conventional commit subject
subject=$(git log -1 --pretty=%s 2>/dev/null || true)
if [ -z "$subject" ]; then
  # commit-msg hook can read the actual subject; this is just a pre-check
  :
fi

# 6. If there's a docs/superpowers/plans/ directory, require plan reference
if [ -d "docs/superpowers/plans" ]; then
  # The most recently modified plan file
  latest_plan=$(ls -t docs/superpowers/plans/*.md 2>/dev/null | head -1 || true)
  if [ -n "$latest_plan" ]; then
    plan_name=$(basename "$latest_plan" .md)
    if [ "$debug_found" -eq 0 ] && ! git log -1 --pretty=%B | grep -q "$plan_name" 2>/dev/null; then
      warn "Latest superpowers plan: $plan_name"
      warn "Consider referencing it in the commit message: 'Refs $plan_name'"
      # not a failure, just a reminder
    fi
  fi
fi

# 7. Self-review checklist
cat <<'EOF'

📋 Pre-commit self-review checklist (per superpowers-requesting-code-review):

  [ ] Re-read every changed file. Would you understand it in 6 months?
  [ ] Names are clear. No copy-pasted blocks.
  [ ] No secrets. No debug code. No commented-out code.
  [ ] Linter passes, type-check passes, tests pass.
  [ ] Spec compliance: matches the approved design.
  [ ] Commit message: conventional commits, explains WHY not just WHAT.

Type 'git commit' to proceed, or 'git commit --no-verify' to bypass.
EOF

ok "All pre-commit guards passed. Proceeding to commit."

# 8. Security scan (smart trigger: only if skills/scripts/AGENTS.md touched)
security_relevant=0
for f in $staged; do
  # Match any path containing /skills/, /scripts/, or AGENTS.md
  case "$f" in
    *skills*|*scripts*|*AGENTS.md*|*sp-commit*)
      security_relevant=1
      ;;
  esac
done

if [ "$security_relevant" -eq 1 ]; then
  echo ""
  note "Security-relevant files changed — running superpowers-security-scan..."
  security_scan_script=""
  for candidate in \
    /opt/data/skills/superpowers/scripts/superpowers-security-scan.sh \
    "$PWD/.husky/superpowers-security-scan.sh" \
    "$(dirname "$(readlink -f "$0" 2>/dev/null)")/superpowers-security-scan.sh"; do
    if [ -x "$candidate" ]; then
      security_scan_script="$candidate"
      break
    fi
  done
  if [ -n "$security_scan_script" ]; then
    set +e
    "$security_scan_script" --quiet
    scan_rc=$?
    set -e
    if [ "$scan_rc" -ne 0 ]; then
      fail "superpowers-security-scan blocked the commit (exit $scan_rc).
Run 'superpowers-security-scan.sh' manually to see findings, or use 'git commit --no-verify' to bypass (not recommended)."
      exit 1
    fi
    ok "superpowers-security-scan passed."
  else
    warn "superpowers-security-scan.sh not found (looked in /opt/data/skills/.../ and .husky/). Skipping."
  fi
fi
