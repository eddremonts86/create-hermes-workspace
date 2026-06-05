#!/usr/bin/env bash
# scripts/publish.sh — re-publish @edd_remonts/create-hermes-workspace to npm.
#
# Reads the publish token from (in order):
#   1. $NPM_TOKEN environment variable
#   2. $HOME/.hermes-secrets/npm-token.txt
#   3. $HOME/.hermes-secrets/npmrc (must contain //registry.npmjs.org/:_authToken=...)
#
# Bumps the patch version, publishes, and reports the new version.
# Safe to re-run — `npm version patch` is idempotent within a release.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 1. Find the npm package directory ────────────────────────────────────────
# publish.sh lives in the *workspace* repo, but it publishes the *npm package*
# repo (a sibling). Resolve by walking up until we find a package.json with
# the right name.
find_pkg_dir() {
  local start="$SCRIPT_DIR"
  while [ "$start" != "/" ]; do
    if [ -f "$start/package.json" ]; then
      if grep -q '"@edd_remonts/create-hermes-workspace"' "$start/package.json" 2>/dev/null; then
        echo "$start"
        return 0
      fi
    fi
    start="$(dirname "$start")"
  done
  return 1
}

PKG_DIR="$(find_pkg_dir || true)"
if [ -z "$PKG_DIR" ]; then
  echo "ERROR: could not locate the npm package directory (looking for package.json containing '@edd_remonts/create-hermes-workspace')."
  echo "  publish.sh expects to be inside either the workspace repo OR the npm package repo."
  exit 1
fi

echo "→  Package directory: $PKG_DIR"
cd "$PKG_DIR"

# ── 2. Resolve the token ─────────────────────────────────────────────────────
resolve_token() {
  if [ -n "${NPM_TOKEN:-}" ]; then
    echo "NPM_TOKEN env"
    return 0
  fi
  if [ -f "$HOME/.hermes-secrets/npm-token.txt" ]; then
    echo "$HOME/.hermes-secrets/npm-token.txt"
    return 0
  fi
  if [ -f "$HOME/.hermes-secrets/npmrc" ]; then
    echo "$HOME/.hermes-secrets/npmrc"
    return 0
  fi
  return 1
}

if ! TOKEN_SOURCE="$(resolve_token)"; then
  echo "ERROR: could not find NPM_TOKEN."
  echo ""
  echo "Set it in one of these places:"
  echo "  1. Environment variable:  export NPM_TOKEN=***"
  echo "  2. File:                  printf 'NPM_TOKEN=*** ' > \$HOME/.hermes-secrets/npm-token.txt"
  echo ""
  echo "Get a publish token at: https://www.npmjs.com/settings/\$(whoami)/tokens"
  echo "Use the 'Automation' type with read+publish scope."
  exit 1
fi
echo "→  Using token from: $TOKEN_SOURCE"

# ── 3. Run tests (TDD gate) ─────────────────────────────────────────────────
echo "→  Running tests…"
if ! npm test --silent 2>&1 | tail -20; then
  echo "ERROR: tests failed. Aborting publish."
  exit 1
fi

# ── 4. Bump version + publish ────────────────────────────────────────────────
echo "→  Bumping patch version…"
NEW_VERSION="$(npm version patch 2>&1 | tail -1 | tr -d 'v\n')"
echo "→  New version: v$NEW_VERSION"

echo "→  Publishing to npm…"
if [ "$TOKEN_SOURCE" = "$HOME/.hermes-secrets/npmrc" ]; then
  NPM_CONFIG_USERCONFIG="$TOKEN_SOURCE" npm publish --access public
elif [ "$TOKEN_SOURCE" = "$HOME/.hermes-secrets/npm-token.txt" ]; then
  NPM_TOKEN="$(cat "$TOKEN_SOURCE")" npm publish --access public
else
  npm publish --access public
fi

echo ""
echo "✅  Published @edd_remonts/create-hermes-workspace@$NEW_VERSION"
echo "    https://www.npmjs.com/package/@edd_remonts/create-hermes-workspace"
