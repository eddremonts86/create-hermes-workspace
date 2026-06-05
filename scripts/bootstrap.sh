#!/usr/bin/env bash
# scripts/bootstrap.sh — non-Docker one-shot installer.
#
# Use this if you can't or don't want to use Docker (e.g. on Android via
# Termux, or a constrained server). Detects your platform and installs the
# Hermes Agent runtime directly on the host.
#
# Usage:
#   ./scripts/bootstrap.sh
#
# Requirements:
#   - Python 3.11+ (3.10 on Termux)
#   - git
#   - jq (for parsing some config)
#
# On first run, copies .env.example to .env for you to edit.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# ── Colors ───────────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  C_GREEN='\033[0;32m'
  C_CYAN='\033[0;36m'
  C_YELLOW='\033[0;33m'
  C_RED='\033[0;31m'
  C_RESET='\033[0m'
else
  C_GREEN=''; C_CYAN=''; C_YELLOW=''; C_RED=''; C_RESET=''
fi

echo -e "${C_CYAN}⚕  create-hermes-workspace bootstrap${C_RESET}"
echo ""

# ── 1. Detect platform ──────────────────────────────────────────────────────
is_termux() {
  [ -n "${TERMUX_VERSION:-}" ] || [[ "${PREFIX:-}" == *"com.termux/files/usr"* ]]
}

if is_termux; then
  PLATFORM="termux"
  PYTHON_VERSION="3.10"
else
  PLATFORM="desktop"
  PYTHON_VERSION="3.11"
fi

echo -e "${C_CYAN}→${C_RESET}  Platform: ${PLATFORM} (Python ${PYTHON_VERSION})"

# ── 2. .env handling ─────────────────────────────────────────────────────────
if [ ! -f .env ]; then
  if [ -f .env.example ]; then
    cp .env.example .env
    echo -e "${C_GREEN}✓${C_RESET}  Created .env from .env.example. ${C_YELLOW}Open it and fill in your LLM keys.${C_RESET}"
  else
    echo -e "${C_RED}✗${C_RESET}  .env.example not found. Are you in the workspace root?"
    exit 1
  fi
else
  echo -e "${C_GREEN}✓${C_RESET}  .env already exists, leaving it alone."
fi

# ── 3. Install Python tooling ───────────────────────────────────────────────
if is_termux; then
  echo -e "${C_CYAN}→${C_RESET}  Termux detected — using stdlib venv + pip"
  if ! command -v python3 >/dev/null 2>&1; then
    echo -e "${C_RED}✗${C_RESET}  python3 not found. Run: pkg install python"
    exit 1
  fi
  if [ ! -d .venv ]; then
    python3 -m venv .venv
  fi
  # shellcheck disable=SC1091
  . .venv/bin/activate
  pip install --upgrade pip wheel >/dev/null
else
  echo -e "${C_CYAN}→${C_RESET}  Locating uv…"
  if command -v uv >/dev/null 2>&1; then
    UV_CMD=uv
  elif [ -x "$HOME/.local/bin/uv" ]; then
    UV_CMD="$HOME/.local/bin/uv"
  else
    echo -e "${C_YELLOW}⚠${C_RESET}  uv not found. Installing…"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    UV_CMD="$HOME/.local/bin/uv"
  fi
  echo -e "${C_GREEN}✓${C_RESET}  Using $UV_CMD"
  if [ ! -d .venv ]; then
    $UV_CMD venv --python "$PYTHON_VERSION"
  fi
  # shellcheck disable=SC1091
  . .venv/bin/activate
fi

# ── 4. Symlink the hermes CLI ───────────────────────────────────────────────
LINK_DIR="$HOME/.local/bin"
mkdir -p "$LINK_DIR"
if [ ! -e "$LINK_DIR/hermes" ]; then
  ln -sf "$(pwd)/.venv/bin/hermes" "$LINK_DIR/hermes" 2>/dev/null || \
    echo -e "${C_YELLOW}⚠${C_RESET}  Could not symlink $LINK_DIR/hermes — add $LINK_DIR to \$PATH manually."
fi
echo -e "${C_GREEN}✓${C_RESET}  Hermes CLI symlinked to $LINK_DIR/hermes"

# ── 5. Done ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${C_GREEN}✅  Bootstrap complete.${C_RESET}"
echo ""
echo "  Next steps:"
echo "    1. Edit .env and set at least one of: MINIMAX_API_KEY, OPENAI_API_KEY, ANTHROPIC_API_KEY"
echo "    2. Add $LINK_DIR to your PATH (or restart your shell)"
echo "    3. Run: hermes chat"
echo ""
echo "  To run the Docker path instead, just use 'make up' from this folder."
