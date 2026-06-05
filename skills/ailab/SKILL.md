---
name: ailab
description: "AI-Lab Yonder skill collection integrated for Hermes. 8 unique-value skills that complement (do not duplicate) superpowers. Use for: audit (spa-day), bug hunting (adversarial-bug-hunt), code review (code-reviewer, pre-merge-review), postmortems, autoresearch, docs generation, multi-agent orchestration."
version: "1.0.0"
author: "AI-Lab-Yonder (https://github.com/AI-Lab-Yonder/ai-lab-agent-skills)"
license: MIT
platforms: [linux, macos]
namespace: ailab
source: "https://github.com/AI-Lab-Yonder/ai-lab-agent-skills"
metadata:
  hermes:
    tags: [ailab, index, namespace, integration]
    homepage: "https://github.com/AI-Lab-Yonder/ai-lab-agent-skills"
    upstream_count: 25
    imported_count: 8
    skipped_count: 17
---

# AI-Lab Skills for Hermes — Index

8 skills imported from [AI-Lab-Yonder/ai-lab-agent-skills](https://github.com/AI-Lab-Yonder/ai-lab-agent-skills).
Body content is **verbatim from upstream**; only the YAML frontmatter was adapted
for Hermes (added `namespace: ailab`, `metadata.hermes.tags`, `source`, etc.).
Each skill has `metadata.hermes.upstream_skill` set to the original name.

> **Why 8 of 25?** The other 17 are redundant with our existing superpowers or
> edd-app-template setup. Importing them would create 5 skills all saying "I'll
> debug this for you" and confuse the LLM's routing. The matrix is in
> `docs/superpowers/specs/2026-06-05-ailab-skills-integration-design.md`.

## The 8 imported skills

| Skill | Use when | What it does that ours doesn't |
|---|---|---|
| `ailab-spa-day` | "audit my skills" / "spa day" | **Interactive** audit (we only have automated `superpowers-self-check`) |
| `ailab-adversarial-bug-hunt` | "hunt for bugs" / "find bugs in this code" | **3-agent adversarial pipeline** (ours is single-agent) |
| `ailab-pre-merge-review` | "review before merge" | **Multi-phase pipeline** (refactor + review + docs), diff vs base branch |
| `ailab-code-reviewer` | "review this PR" / "audit this code" | **5-category exhaustive checklist** (Security, Performance, Quality, Style, Tests) |
| `ailab-postmortem` | "capture this lesson" / "I made a mistake" | **gotchas.md protocol** per skill with BUG/ARCH/MISUNDERSTANDING classification |
| `ailab-autoresearch` | "optimize this skill" / "autoresearch" | **Auto-optimize skills** via eval loops + prompt mutation (Karpathy-style) |
| `ailab-docs-generator` | "generate docs from code" | Auto-generates READMEs, API refs, architecture docs |
| `ailab-multi-agent-orchestrator` | "coordinate agents" / "multi-agent" | Orchestrate multiple agents on complex tasks |

## Routing disambiguation (CRITICAL)

| User intent | Load this skill | NOT this one |
|---|---|---|
| "fix this bug" / "no funciona" / "arregla esto" | `superpowers-systematic-debugging` | (not ailab) |
| "hunt for bugs" / "find bugs" / "bug hunt" | `ailab-adversarial-bug-hunt` | (not superpowers) |
| "review this commit" / "before I commit" | `superpowers-requesting-code-review` | (not ailab) |
| "review this PR" / "audit this code" / "code review" | `ailab-code-reviewer` | (not superpowers-requesting-code-review) |
| "review before merge" / "pre-merge" | `ailab-pre-merge-review` | (not superpowers-finishing-a-development-branch) |
| "capture this lesson" / "I made a mistake" / "postmortem" | `ailab-postmortem` | (not memory) |
| "audit my skills" / "spa day" / "find contradictions" | `ailab-spa-day` | (not superpowers-self-check, which is automatic) |
| "optimize this skill" / "autoresearch" | `ailab-autoresearch` | (we have no equivalent) |
| "generate docs from code" | `ailab-docs-generator` | (we have no equivalent) |
| "coordinate agents" / "multi-agent" | `ailab-multi-agent-orchestrator` | (not superpowers-dispatching-parallel-agents) |

## The 17 skills we did NOT import

| AI-Lab skill | We already have |
|---|---|
| `bug-fixer` | `superpowers-systematic-debugging` |
| `test-writer`, `tdd-workflow` | `superpowers-test-driven-development` |
| `refactorer` | `superpowers-code-workflow` |
| `skill-builder`, `skill-creator` | `superpowers-writing-skills` |
| `prompt-engineer` | not needed (we use skills, not raw prompts) |
| `codex-review` | depends on Codex MCP (not Hermes) |
| `pr-merge-review` | `superpowers-finishing-a-development-branch` |
| `frontend-dev`, `fullstack-dev`, `api-builder`, `landing-page`, `auth-system`, `database-designer` | `edd-app-template` (default stack) |
| `docs-scaffold`, `resolve-docs` | covered by superpowers-brainstorming |

## How to load a skill

```python
skill_view(name="ailab-spa-day")     # interactive audit
skill_view(name="ailab-adversarial-bug-hunt")  # 3-agent bug hunt
skill_view(name="ailab-code-reviewer")  # 5-category review
```

Or just `skill_view(name="ailab")` to see this index.

## License

MIT. Original © AI-Lab-Yonder. Imported into Hermes by user request, 2026-06-05.
