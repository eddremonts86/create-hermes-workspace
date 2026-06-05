#!/usr/bin/env bash
# superpowers-self-check.sh
#
# Cron-friendly: validate that the superpowers installation is intact and
# the AGENTS.md bootstrap is still being injected.
#
# What it checks:
#   1. /opt/data/AGENTS.md exists and is <7KB (otherwise injection might
#      be truncated; Hermes truncates at ~4-8KB for context files).
#   2. All 18 expected superpowers-* skill directories exist.
#   3. Each skill has a SKILL.md with valid frontmatter.
#   4. /opt/data/skills/superpowers/SKILL.md is present and has the index.
#   5. The sync-from-upstream.sh script is executable.
#   6. The precommit guard is executable.
#   7. Tries to clone obra/superpowers HEAD and compares commit SHAs to
#      detect when an upstream update is available.
#
# Output: a short report. Exit 0 = healthy, exit 1 = problem.
# Cron will deliver the report to the configured channel.

set -uo pipefail

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

problems=0
warnings=0

report_ok()    { printf "${GREEN}✓${NC} %s\n" "$*"; }
report_warn()  { printf "${YELLOW}!${NC} %s\n" "$*"; warnings=$((warnings + 1)); }
report_err()   { printf "${RED}✗${NC} %s\n" "$*"; problems=$((problems + 1)); }

echo "═══════════════════════════════════════════════════════════"
echo "  Superpowers self-check — $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
echo "═══════════════════════════════════════════════════════════"

# 1. AGENTS.md
echo ""
echo "→ AGENTS.md bootstrap"
agents_path="/opt/data/AGENTS.md"
if [ ! -f "$agents_path" ]; then
  report_err "AGENTS.md missing at $agents_path"
elif [ ! -s "$agents_path" ]; then
  report_err "AGENTS.md is empty"
else
  size=$(wc -c < "$agents_path")
  if [ "$size" -gt 7168 ]; then
    report_warn "AGENTS.md is $size bytes (>7KB). Hermes truncates context files. Consider splitting."
  else
    report_ok "AGENTS.md present, $size bytes"
  fi
  # Check it references the expected skills
  for required in "superpowers-skill-routing" "superpowers-creative-workflow" "HARD GATEs"; do
    if ! grep -qF "$required" "$agents_path"; then
      report_err "AGENTS.md missing required reference: $required"
    fi
  done
  report_ok "AGENTS.md contains all required references"
fi

# 2. Expected skills
echo ""
echo "→ Installed superpowers skills"
expected=(
  superpowers-skill-routing
  superpowers-triage
  superpowers-creative-workflow
  superpowers-code-workflow
  superpowers-using-superpowers
  superpowers-brainstorming
  superpowers-writing-plans
  superpowers-executing-plans
  superpowers-test-driven-development
  superpowers-systematic-debugging
  superpowers-verification-before-completion
  superpowers-requesting-code-review
  superpowers-receiving-code-review
  superpowers-dispatching-parallel-agents
  superpowers-subagent-driven-development
  superpowers-using-git-worktrees
  superpowers-writing-skills
  superpowers-finishing-a-development-branch
)
base="/opt/data/skills/superpowers"
for s in "${expected[@]}"; do
  if [ ! -d "$base/$s" ]; then
    report_err "Missing skill directory: $base/$s"
  elif [ ! -f "$base/$s/SKILL.md" ]; then
    report_err "Missing SKILL.md in $base/$s/"
  else
    # Quick frontmatter sanity check
    if ! head -5 "$base/$s/SKILL.md" | grep -q "^---$"; then
      report_err "$s/SKILL.md has no frontmatter opening"
    elif ! head -50 "$base/$s/SKILL.md" | grep -q "^name: $s$"; then
      report_warn "$s/SKILL.md name field doesn't match directory (still works, but unusual)"
    fi
  fi
done
report_ok "All 18 expected superpowers skills present (or reported missing above)"

# 2b. AI-Lab (ailab-*) skills
echo ""
echo "→ AI-Lab (ailab-*) skills (8 expected)"
ailab_base="/opt/data/skills/ailab"
ailab_expected=(
  ailab-spa-day
  ailab-adversarial-bug-hunt
  ailab-pre-merge-review
  ailab-code-reviewer
  ailab-postmortem
  ailab-autoresearch
  ailab-docs-generator
  ailab-multi-agent-orchestrator
)
if [ ! -d "$ailab_base" ]; then
  report_err "Missing $ailab_base directory (AI-Lab skills not imported)"
else
  for s in "${ailab_expected[@]}"; do
    if [ ! -d "$ailab_base/$s" ]; then
      report_err "Missing ailab skill directory: $ailab_base/$s"
    elif [ ! -f "$ailab_base/$s/SKILL.md" ]; then
      report_err "Missing SKILL.md in $ailab_base/$s/"
    else
      # Quick frontmatter sanity check
      if ! head -1 "$ailab_base/$s/SKILL.md" | grep -q "^---$"; then
        report_err "$s/SKILL.md has no frontmatter opening"
      elif ! head -10 "$ailab_base/$s/SKILL.md" | grep -q "^namespace: ailab$"; then
        report_warn "$s/SKILL.md missing 'namespace: ailab'"
      fi
    fi
  done
  report_ok "All 8 expected ailab skills present (or reported missing above)"
fi

# 3. Scripts
echo ""
echo "→ Helper scripts"
for s in sync-from-upstream.sh superpowers-precommit-guard.sh install-precommit-guard.sh superpowers-self-check.sh superpowers-security-scan.sh; do
  if [ -x "$base/scripts/$s" ]; then
    report_ok "scripts/$s is executable"
  elif [ -f "$base/scripts/$s" ]; then
    report_warn "scripts/$s exists but is NOT executable (run: chmod +x $base/scripts/$s)"
  else
    report_err "scripts/$s missing"
  fi
done

# 3b. Security tools
echo ""
echo "→ Security tools (gitleaks, shellcheck, bandit, semgrep)"
for tool in gitleaks shellcheck bandit semgrep jq; do
  if command -v "$tool" >/dev/null 2>&1; then
    if [ "$tool" = "gitleaks" ]; then
      ver=$("$tool" version 2>&1 | head -1)
    else
      ver=$("$tool" --version 2>&1 | head -1)
    fi
    report_ok "$tool: $ver"
  else
    report_warn "$tool: not installed (see INSTALLATION.md for setup)"
  fi
done

# 4. Index
echo ""
echo "→ Index file"
if [ -f "$base/SKILL.md" ]; then
  index_skills=$(grep -c "^| \`superpowers-" "$base/SKILL.md" || echo 0)
  report_ok "SKILL.md index present, mentions $index_skills skills in tables"
else
  report_err "SKILL.md index missing"
fi

# 5. Upstream drift check (only if network available, non-blocking)
echo ""
echo "→ Upstream drift check"
if command -v git >/dev/null && [ -d "$base" ]; then
  # Use a tiny temp clone to get the upstream HEAD SHA without disturbing anything
  tmpdir=$(mktemp -d)
  if git clone --depth 1 --quiet git@github.com:obra/superpowers.git "$tmpdir/upstream" 2>/dev/null; then
    upstream_sha=$(git -C "$tmpdir/upstream" rev-parse HEAD)
    upstream_ver=$(grep -m1 '"version"' "$tmpdir/upstream/.claude-plugin/plugin.json" 2>/dev/null | sed 's/.*"version": *"\([^"]*\)".*/\1/')
    report_ok "Upstream obra/superpowers HEAD: ${upstream_sha:0:9} (v${upstream_ver:-?})"
    rm -rf "$tmpdir"
  else
    report_warn "Could not reach github.com to check upstream (offline or no SSH key)"
    rm -rf "$tmpdir"
  fi
fi

# Summary
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Summary: $problems problem(s), $warnings warning(s)"
echo "═══════════════════════════════════════════════════════════"

if [ "$problems" -gt 0 ]; then
  echo ""
  echo "ACTION REQUIRED: fix the errors above. The superpowers gates may not be enforced."
fi

if [ "$warnings" -gt 0 ]; then
  echo ""
  echo "Warnings only. No action required, but consider addressing them."
fi

# === Gate metrics logging (Gate-Skipping Metrics, 2026-06-05) ===
# Runs on EXIT regardless of problems/warnings so failed checks still log
# the "missing" actions — that's the whole point of the audit.
LOG_EVENT="/opt/data/skills/superpowers/scripts/superpowers-log-event.sh"
if [ -x "$LOG_EVENT" ]; then
  # Gate 1: bootstrap routing — AGENTS.md present
  if [ -f /opt/data/AGENTS.md ]; then
    "$LOG_EVENT" "bootstrap-routing" "applied" 2>/dev/null || true
  else
    "$LOG_EVENT" "bootstrap-routing" "missing" 2>/dev/null || true
  fi

  # Gate 2: gates list — all 18 superpowers skills present
  if [ "$problems" -eq 0 ] && [ "$warnings" -eq 0 ]; then
    "$LOG_EVENT" "gates-list" "applied" 2>/dev/null || true
  else
    "$LOG_EVENT" "gates-list" "missing" 2>/dev/null || true
  fi

  # Gate 3: announce-then-act — grep AGENTS.md for "announce"
  if [ -f /opt/data/AGENTS.md ] && grep -q "announce" /opt/data/AGENTS.md; then
    "$LOG_EVENT" "announce-then-act" "applied" 2>/dev/null || true
  else
    "$LOG_EVENT" "announce-then-act" "missing" 2>/dev/null || true
  fi

  # Gate 4: rule-2-gates — grep AGENTS.md for "Rule 2"
  if [ -f /opt/data/AGENTS.md ] && grep -q "Rule 2" /opt/data/AGENTS.md; then
    "$LOG_EVENT" "rule-2-gates" "applied" 2>/dev/null || true
  else
    "$LOG_EVENT" "rule-2-gates" "missing" 2>/dev/null || true
  fi

  # Gate 7: ailab-routing — grep superpowers-skill-routing for "ailab"
  if grep -q "ailab" /opt/data/skills/superpowers/superpowers-skill-routing/SKILL.md 2>/dev/null; then
    "$LOG_EVENT" "ailab-routing" "applied" 2>/dev/null || true
  else
    "$LOG_EVENT" "ailab-routing" "missing" 2>/dev/null || true
  fi
fi

if [ "$problems" -gt 0 ]; then
  exit 1
fi
exit 0
