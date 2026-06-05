#!/usr/bin/env bash
# install-precommit-guard.sh
#
# Install the superpowers pre-commit guard into a git worktree.
#
# Usage:
#   ~/.hermes/skills/superpowers/scripts/install-precommit-guard.sh <path-to-worktree>
#
# Or from inside the worktree, no args (uses pwd):
#   ~/.hermes/skills/superpowers/scripts/install-precommit-guard.sh
#
# What it does:
#   1. Copies superpowers-precommit-guard.sh into <worktree>/.husky/pre-commit-superpowers
#   2. Appends a call to it from <worktree>/.husky/pre-commit
#   3. Makes the script executable
#   4. Does NOT remove or modify existing husky hooks (it appends, doesn't replace)

set -euo pipefail

GUARD_SRC=""
for candidate in "$HOME/.hermes/skills/superpowers/scripts/superpowers-precommit-guard.sh" \
                  "/opt/data/skills/superpowers/scripts/superpowers-precommit-guard.sh" \
                  "$(dirname "$(readlink -f "$0")")/superpowers-precommit-guard.sh"; do
  if [ -f "$candidate" ]; then
    GUARD_SRC="$candidate"
    break
  fi
done
if [ -z "$GUARD_SRC" ]; then
  echo "ERROR: Could not find superpowers-precommit-guard.sh" >&2
  exit 1
fi
GUARD_NAME="pre-commit-superpowers"

if [ ! -f "$GUARD_SRC" ]; then
  echo "ERROR: Guard script not found at $GUARD_SRC" >&2
  exit 1
fi

# Determine target
target="${1:-$PWD}"
if [ ! -d "$target" ]; then
  echo "ERROR: Target directory does not exist: $target" >&2
  exit 1
fi
if ! git -C "$target" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: $target is not a git worktree." >&2
  exit 1
fi

husky_dir="$target/.husky"
if [ ! -d "$husky_dir" ]; then
  echo "ERROR: $target has no .husky/ directory. Is this a project with husky? (or run 'npx husky init' first)" >&2
  exit 1
fi

# Copy guard
target_guard="$husky_dir/$GUARD_NAME"
cp "$GUARD_SRC" "$target_guard"
chmod +x "$target_guard"
echo "✓ Copied guard to $target_guard"

# Append to pre-commit (don't replace)
pre_commit="$husky_dir/pre-commit"
if [ ! -f "$pre_commit" ]; then
  echo "#!/usr/bin/env sh" > "$pre_commit"
  chmod +x "$pre_commit"
  echo "✓ Created $pre_commit"
fi

if grep -qF "$GUARD_NAME" "$pre_commit"; then
  echo "! $pre_commit already references $GUARD_NAME — skipping append."
else
  cat >> "$pre_commit" <<EOF

# superpowers-requesting-code-review guard
$GUARD_NAME
EOF
  echo "✓ Appended guard invocation to $pre_commit"
fi

echo ""
echo "Done. The superpowers pre-commit guard is now active in $target."
echo "To uninstall: remove the lines referring to $GUARD_NAME from $pre_commit"
echo "and delete $target_guard."
