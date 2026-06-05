#!/usr/bin/env python3
"""
Re-apply the Layer-4 ⚡ HERMES ENFORCEMENT blocks to a collection of
sub-skills after refreshing the body content from upstream.

Idempotent: checks for the marker `## ⚡ HERMES ENFORCEMENT` and skips
already-reinforced skills.

Usage:
    python3 sync-enforcement-blocks.py --collection <namespace> \
        --enforcement-block-file <path-to-block.md>

The block file should be a single `## ⚡ HERMES ENFORCEMENT (additive to upstream)`
header followed by the body text. One file per sub-skill is the typical shape.
The marker check ensures the block is re-applied identically each time,
so editing the block file and re-running the script is the way to evolve
the enforcement over time.
"""
import argparse
import re
import sys
from pathlib import Path

MARKER = "## ⚡ HERMES ENFORCEMENT"


def has_marker(text: str) -> bool:
    return MARKER in text


def split_frontmatter(text: str):
    if not text.startswith('---'):
        return None, text
    end = text.find('\n---', 3)
    if end == -1:
        return None, text
    return text[:end + 4], text[end + 4:]


def apply_enforcement(skill_md: Path, block_text: str, dry_run: bool = False) -> str:
    """Returns 'applied' | 'skipped' | 'malformed'."""
    text = skill_md.read_text()
    if has_marker(text):
        return 'skipped'
    fm_block, body = split_frontmatter(text)
    if fm_block is None:
        return 'malformed'
    # Block goes right after the frontmatter closing ---, with one blank line
    # between it and the body. Body's leading whitespace is preserved.
    insert = block_text.rstrip() + "\n\n"
    new_text = fm_block + "\n" + insert + body.lstrip('\n')
    if not dry_run:
        skill_md.write_text(new_text)
    return 'applied'


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument('--collection', required=True,
                   help='Namespace directory (e.g., superpowers)')
    p.add_argument('--enforcement-dir', required=True,
                   help='Directory with one .md file per sub-skill, '
                        'filename matching the sub-skill directory name. '
                        'Each file is the ⚡ HERMES ENFORCEMENT block '
                        'for that sub-skill.')
    p.add_argument('--dry-run', action='store_true')
    args = p.parse_args()

    collection = Path(args.collection)
    block_dir = Path(args.enforcement_dir)

    if not collection.is_dir():
        print(f'ERROR: collection dir not found: {collection}', file=sys.stderr)
        return 1
    if not block_dir.is_dir():
        print(f'ERROR: enforcement dir not found: {block_dir}', file=sys.stderr)
        return 1

    applied = skipped = malformed = missing = 0
    for skill_dir in sorted(collection.iterdir()):
        if not skill_dir.is_dir():
            continue
        skill_md = skill_dir / 'SKILL.md'
        if not skill_md.exists():
            continue
        block_file = block_dir / f'{skill_dir.name}.md'
        if not block_file.exists():
            # No enforcement block for this sub-skill — that's fine, not all
            # sub-skills need one. Only the critical ones.
            missing += 1
            continue
        result = apply_enforcement(skill_md, block_file.read_text(), dry_run=args.dry_run)
        if result == 'applied':
            applied += 1
            print(f'  ✓ {skill_dir.name}')
        elif result == 'skipped':
            skipped += 1
            print(f'  → {skill_dir.name} (already reinforced)')
        else:
            malformed += 1
            print(f'  ✗ {skill_dir.name} (malformed frontmatter)', file=sys.stderr)

    print(f'\nApplied: {applied}, skipped: {skipped}, '
          f'malformed: {malformed}, no-block-defined: {missing}')
    if args.dry_run:
        print('(dry run — no files written)')
    return 0


if __name__ == '__main__':
    sys.exit(main())
