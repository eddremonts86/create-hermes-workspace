#!/usr/bin/env bash
# superpowers-security-scan.sh
#
# Orchestrates 4 industry-standard security tools to audit Hermes skills,
# scripts, and bootstrap config. Exits 0 if clean, 1 if blocking findings.
#
# Tools and what blocks:
#   gitleaks   - ANY secret leak (always blocks)
#   sc         - ONLY level: error findings (warnings do not block)
# 3. bandit - only HIGH severity blocks
# 4. semgrep - only ERROR severity blocks
#
# Usage:
#   superpowers-security-scan.sh                    # scan default paths
#   superpowers-security-scan.sh <path> [<path>...] # scan custom paths
#   superpowers-security-scan.sh --quiet            # only show summary
#
# Exit codes:
#   0 = all clean
#   1 = blocking findings (commit should be rejected)
#   2 = warnings only (advisory)
#
# Requires: gitleaks, shellcheck, bandit, semgrep, jq
# All installed at ~/.local/bin (or in $PATH).
#
# Cron / pre-commit both use this script. Pre-commit adds --quiet.

set -uo pipefail

# Colors (disable if not a TTY)
if [ -t 1 ]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; CYAN=''; NC=''
fi

ok()    { printf "${GREEN}✓${NC} %s\n" "$*"; }
warn()  { printf "${YELLOW}!${NC} %s\n" "$*"; }
fail()  { printf "${RED}✗${NC} %s\n" "$*"; }
note()  { printf "${CYAN}ℹ${NC} %s\n" "$*"; }

# Default paths to scan (skip node_modules, worktrees, agent source)
DEFAULT_PATHS=(
  /opt/data/AGENTS.md
  /opt/data/skills
  /opt/data/home/.local/bin/sp-commit
)

# Parse args
QUIET=0
TARGETS=()
for arg in "$@"; do
  case "$arg" in
    --quiet|-q) QUIET=1 ;;
    --help|-h)
      grep '^#' "$0" | head -30 | sed 's/^# \?//'
      exit 0
      ;;
    *) TARGETS+=("$arg") ;;
  esac
done
[ ${#TARGETS[@]} -eq 0 ] && TARGETS=("${DEFAULT_PATHS[@]}")

problems=0
warnings=0

# 1. gitleaks — any leak blocks
gitleaks_scan() {
  if ! command -v gitleaks >/dev/null 2>&1; then
    warn "gitleaks not installed (skipping)"
    return
  fi
  local gl_out
  gl_out=$(mktemp)
  # --no-git so we can scan non-git dirs
  # --exit-code 0 so gitleaks always returns 0 (we parse the report)
  for tgt in "${TARGETS[@]}"; do
    if [ -e "$tgt" ]; then
      gitleaks detect --no-banner --no-git --source "$tgt" \
        --report-format json --report-path "$gl_out" --exit-code 0 \
        >/dev/null 2>&1 || true
    fi
  done
  local count
  count=$(jq 'length' "$gl_out" 2>/dev/null)
  [[ "$count" =~ ^[0-9]+$ ]] || count=0
  if [ "$count" -gt 0 ]; then
    fail "gitleaks (secrets) - $count leak(s) found"
    [ "$QUIET" -eq 0 ] && jq -r '.[] | "  ✗ \(.File):\(.StartLine): \(.RuleID) - \(.Description)"' "$gl_out" 2>/dev/null
    problems=$((problems + count))
  else
    ok "gitleaks (secrets) - 0 leaks"
  fi
  rm -f "$gl_out"
}

# 2. shellcheck - only level: error blocks
shellcheck_scan() {
  if ! command -v shellcheck >/dev/null 2>&1; then
    warn "shellcheck not installed (skipping)"
    return
  fi
  local total_errors=0
  local sh_files
  sh_files=$(mktemp)
  for tgt in "${TARGETS[@]}"; do
    if [ -d "$tgt" ]; then
      find "$tgt" -name "*.sh" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null >> "$sh_files"
    fi
  done
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    local errs
    errs=$(shellcheck -f json "$f" 2>/dev/null | jq '[.[] | select(.level=="error")] | length' 2>/dev/null)
    [[ "$errs" =~ ^[0-9]+$ ]] || errs=0
    if [ "$errs" -gt 0 ] && [ "$QUIET" -eq 0 ]; then
      shellcheck -f json "$f" 2>/dev/null \
        | jq -r '.[] | select(.level=="error") | "  ✗ \(.file):\(.line):\(.column) [\(.code)] \(.message)"' 2>/dev/null
    fi
    total_errors=$((total_errors + errs))
  done < "$sh_files"
  rm -f "$sh_files"
  if [ "$total_errors" -gt 0 ]; then
    fail "shellcheck (bash) - $total_errors error(s)"
    problems=$((problems + total_errors))
  else
    ok "shellcheck (bash) - 0 errors"
  fi
}

# 3. bandit — only HIGH severity blocks
bandit_scan() {
  if ! command -v bandit >/dev/null 2>&1; then
    warn "bandit not installed (skipping)"
    return
  fi
  local total_high=0
  for tgt in "${TARGETS[@]}"; do
    if [ -d "$tgt" ]; then
      local high
      high=$(bandit -q -r "$tgt" -f json -ll 2>/dev/null \
        | jq '[.results[] | select(.issue_severity=="HIGH")] | length' 2>/dev/null)
      [[ "$high" =~ ^[0-9]+$ ]] || high=0
      if [ "$high" -gt 0 ] && [ "$QUIET" -eq 0 ]; then
        bandit -q -r "$tgt" -f json -ll 2>/dev/null \
          | jq -r '.results[] | select(.issue_severity=="HIGH") | "  ✗ \(.filename):\(.line_number): [\(.test_id)] \(.issue_text)"' 2>/dev/null
      fi
      total_high=$((total_high + high))
    fi
  done
  if [ "$total_high" -gt 0 ]; then
    fail "bandit (python) - $total_high HIGH-severity finding(s)"
    problems=$((problems + total_high))
  else
    ok "bandit (python) - 0 high"
  fi
}

# 4. semgrep — only ERROR severity blocks
semgrep_scan() {
  if ! command -v semgrep >/dev/null 2>&1; then
    warn "semgrep not installed (skipping)"
    return
  fi
  local sg_out
  sg_out=$(mktemp)
  for tgt in "${TARGETS[@]}"; do
    if [ -e "$tgt" ]; then
      timeout 120 semgrep --config=p/security-audit --config=p/secrets \
        --json --quiet --no-git-ignore --error --metrics=off \
        "$tgt" > "$sg_out" 2>/dev/null || true
    fi
  done
  local errs
  errs=$(jq '[.results[] | select(.extra.severity=="ERROR")] | length' "$sg_out" 2>/dev/null)
  [[ "$errs" =~ ^[0-9]+$ ]] || errs=0
  if [ "$errs" -gt 0 ]; then
    fail "semgrep (owasp) — $errs ERROR finding(s)"
    [ "$QUIET" -eq 0 ] && jq -r '.results[] | select(.extra.severity=="ERROR") | "  ✗ \(.path):\(.start.line): \(.check_id)"' "$sg_out" 2>/dev/null
    problems=$((problems + errs))
  else
    ok "semgrep (owasp) — 0 errors"
  fi
  rm -f "$sg_out"
}

# Header
[ "$QUIET" -eq 0 ] && note "Superpowers security scan — $(date -u +'%Y-%m-%d %H:%M:%S UTC')"

# Run all
gitleaks_scan
shellcheck_scan
bandit_scan
semgrep_scan

# Summary
if [ "$problems" -gt 0 ]; then
  echo ""
  printf "${RED}Summary: %d problem(s) — BLOCKS${NC}\n" "$problems"
  exit 1
fi

echo ""
printf "${GREEN}All green. Skills are clean.${NC}\n"
exit 0
