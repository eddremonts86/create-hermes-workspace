#!/usr/bin/env bash
# sync-from-upstream.sh
#
# Refresh the 14 superpowers skill ports from obra/superpowers (upstream).
#
# SAFE: re-applies the Hermes frontmatter extension + port-notice prefix
#       after pulling new content. Does NOT clobber the namespace setup.
#
# Usage:
#   ~/.hermes/skills/superpowers/scripts/sync-from-upstream.sh
#
# Requirements: git, python3.

set -euo pipefail

UPSTREAM_REPO="https://github.com/obra/superpowers.git"
DEST="${HOME}/.hermes/skills/superpowers"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "==> Cloning upstream to $WORK"
git clone --depth 1 "$UPSTREAM_REPO" "$WORK/src"

if [ ! -d "$DEST" ]; then
  echo "ERROR: $DEST does not exist. Run the porting script first or install manually."
  exit 1
fi

echo "==> Removing old per-skill ports (keeping $DEST/SKILL.md index and scripts/)"
for skill_dir in "$DEST"/*/; do
  name="$(basename "$skill_dir")"
  if [ "$name" = "scripts" ]; then continue; fi
  # Only remove dirs that exist upstream as skills (don't blow away unrelated dirs)
  if [ -d "$WORK/src/skills/$name" ]; then
    rm -rf "$skill_dir"
  fi
done

echo "==> Copying fresh skills from upstream"
for skill_dir in "$WORK/src/skills/"*/; do
  name="$(basename "$skill_dir")"
  mkdir -p "$DEST/$name"
  # Copy everything (SKILL.md, references/, scripts/, assets/) preserving structure
  cp -r "$skill_dir"/* "$DEST/$name/"
  # Remove the upstream's own update script if present (it would clobber our work)
  rm -f "$DEST/$name/scripts/update-from-upstream.sh" 2>/dev/null || true
done

echo "==> Re-applying Hermes frontmatter extension + port notice"
python3 <<'PYEOF'
import re
from pathlib import Path

DEST = Path.home() / ".hermes" / "skills" / "superpowers"

EXTRA_LINES = [
    'version: "5.1.0"',
    'author: "Jesse Vincent (obra)"',
    'license: MIT',
    'platforms: [linux, macos]',
    'namespace: superpowers',
    'source: "https://github.com/obra/superpowers"',
    'metadata:',
    '  hermes:',
    '    tags: [superpowers, methodology, workflow]',
    '    homepage: "https://github.com/obra/superpowers"',
]

def split_frontmatter(text):
    if not text.startswith('---'):
        return None, text
    end = text.find('\n---', 3)
    if end == -1:
        return None, text
    return text[:end + 4], text[end + 4:]

def parse_keys(fm_block):
    keys = set()
    for line in fm_block.splitlines():
        if line and not line.startswith(' ') and not line.startswith('-') and line != '---':
            m = re.match(r'^([A-Za-z_][A-Za-z0-9_-]*):', line)
            if m:
                keys.add(m.group(1))
    return keys

n = 0
for skill_dir in sorted(DEST.iterdir()):
    if not skill_dir.is_dir() or skill_dir.name == 'scripts':
        continue
    p = skill_dir / "SKILL.md"
    if not p.exists():
        continue
    text = p.read_text()
    fm_block, body = split_frontmatter(text)
    if fm_block is None:
        continue
    existing = parse_keys(fm_block)
    close_pos = fm_block.rfind('---', 3)
    fm_inner = fm_block[3:close_pos].rstrip()
    lines_to_add = [l for l in EXTRA_LINES if l.split(':', 1)[0].strip() not in existing]
    new_fm = "---\n" + fm_inner + ("\n" + "\n".join(lines_to_add) if lines_to_add else "") + "\n---"
    # If body doesn't already have our port notice, add it
    notice_marker = "**Port of `"
    if notice_marker not in body:
        notice = (
            f"> **Port of `{skill_dir.name}` from "
            f"[obra/superpowers](https://github.com/obra/superpowers) v5.1.0.** "
            f"Original by Jesse Vincent. Adapted to Hermes skill format.\n\n"
        )
        body = notice + body.lstrip('\n')
    p.write_text(new_fm + body)
    n += 1
    print(f"  ✓ {skill_dir.name}")
print(f"\n{n} skills refreshed.")
PYEOF

echo ""
echo "==> Done. To make Hermes pick up the new skills in a running session:"
echo "    /reload-skills"
echo "    (or restart the gateway / CLI)"
