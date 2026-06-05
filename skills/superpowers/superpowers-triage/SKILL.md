---
name: superpowers-triage
description: "ULTRA-FAST 1-step intent classification. Load this skill on the first user turn of a session, BEFORE superpowers-skill-routing, to classify the message in one pass. Loads the right orchestrator (creative-workflow, code-workflow, or none) without ceremony. Use when you want the agent to be snappy and not over-classify. Less ceremony than superpowers-skill-routing; same routing logic, single output."
version: "5.1.0"
author: "Jesse Vincent (obra) + Hermes enforcement"
license: MIT
platforms: [linux, macos]
namespace: superpowers
source: "https://github.com/obra/superpowers"
metadata:
  hermes:
    tags: [superpowers, triage, fast, intent, classification]
    homepage: "https://github.com/obra/superpowers"
---

# superpowers-triage — the 1-step intent classifier

> **Use this when you want speed. It does ONE thing: classify the user's
> intent and tell you which skill to load next. Nothing else.**

## The single decision

Read the user's message. Ask yourself: **is the user describing something
to BUILD/CREATE, something to FIX/CHANGE in existing code, or are they
asking a question?**

| If the message is... | Output this announcement and load this skill |
|---|---|
| Describing something to BUILD / CREATE / DESIGN | `"Using superpowers-creative-workflow."` then `skill_view(name="superpowers-creative-workflow")` |
| Describing something to FIX / CHANGE / MODIFY in existing code | `"Using superpowers-code-workflow."` then `skill_view(name="superpowers-code-workflow")` |
| Asking the agent to COMMIT / PUSH / SHIP / PR | `"Using superpowers-requesting-code-review."` then `skill_view(name="superpowers-requesting-code-review")` |
| Responding to code review / PR feedback | `"Using superpowers-receiving-code-review."` then `skill_view(name="superpowers-receiving-code-review")` |
| Pure Q&A / explanation / lookup | `"Skipping superpowers — pure Q&A."` then just answer |
| Unclear which one | Ask ONE clarifying question: "Is this creating something new, fixing something existing, or pure Q&A?" |

That's it. No decision tree, no multi-step. One input, one output.

## Keyword signal library (fast path)

If you want to skip even the one-pass classification, scan the message
for these keywords and pick the first match.

**CREATIVE (build/create/design):**
- English: create, build, design, implement, make, scaffold, new, add a
  feature, let's make, I want, I need
- Spanish: crea, crear, diseña, diseñar, construye, construir, hazme,
  quiero, vamos, hagamos, añade, agrega, implementa, implementar,
  nueva, nuevo, armemos, montemos

**CODE (fix/change/modify):**
- English: fix, refactor, debug, broken, doesn't work, error, change,
  modify, update, migrate, port, upgrade, improve, clean up
- Spanish: arregla, arreglar, depurar, depura, no funciona, está roto,
  está mal, cambia, cambiar, modifica, modificar, actualiza, migrar,
  portar, mejora, limpiar, refactorizar

**COMMIT/SHIP:**
- commit, push, ship, merge, open the PR, "ready to merge"

**REVIEW:**
- "review comments", "PR feedback", "address review", "code review
  said"

**Q&A (skip):**
- what is, how does, explain, list, show, tell me, describe, look up,
- qué es, cómo funciona, explica, lista, muestra, dime, describe,
  busca

If multiple categories match (rare), prefer the **most specific**:
> review > commit > code > creative > Q&A

If still ambiguous, ask the one clarifying question.

## Output format (mandatory)

Your first response to a classified creative/code/commit/review message
**MUST start** with one of these exact phrases (so the user can see the
classification happened):

- `Using superpowers-creative-workflow to [purpose].`
- `Using superpowers-code-workflow to [purpose].`
- `Using superpowers-requesting-code-review before the commit.`
- `Using superpowers-receiving-code-review to address feedback.`
- `Skipping superpowers — pure Q&A.`

Where `[purpose]` is a 5-15 word summary of what you're about to do.

## Examples (with expected first-line output)

| User message | First line of agent response |
|---|---|
| "crea una app de tareas" | `Using superpowers-creative-workflow to build a task-tracking app.` |
| "build me a chatbot" | `Using superpowers-creative-workflow to build a chatbot.` |
| "arregla el bug del login" | `Using superpowers-code-workflow to debug the login bug.` |
| "fix the off-by-one error in parser.ts" | `Using superpowers-code-workflow to fix the parser.ts off-by-one bug.` |
| "refactor this function" | `Using superpowers-code-workflow to refactor the function.` |
| "commit this" | `Using superpowers-requesting-code-review before the commit.` |
| "open the PR" | `Using superpowers-requesting-code-review before opening the PR.` |
| "PR comments addressed" | `Using superpowers-receiving-code-review to address the PR feedback.` |
| "¿qué es TDD?" | `Skipping superpowers — pure Q&A.` |
| "lista los archivos" | `Skipping superpowers — pure Q&A.` |
| "I want to add OAuth support" | `Using superpowers-creative-workflow to add OAuth support.` |
| "make the dashboard faster" | `Using superpowers-code-workflow to improve dashboard performance.` |

## When the classification is "ask one clarifying question"

The triage may tell you to ask the user a clarifying question (e.g. "is
this creating, fixing, or Q&A?", or "what is 'sey' supposed to mean?").
When that happens, **the question itself must follow the same cadence as
`superpowers-brainstorming`**:

- **Multiple choice menu**, 3-4 mutually exclusive options + a recommended one.
- **Mark the recommendation in the question text** (e.g. "Recommend: option 3").
- The user can reply "dale con tu recomendación" / "aplica tus recomendaciones"
  / "go with your best judgment" — that is a valid answer that picks all
  recommended options in one reply.
- This format was explicitly praised ("esto es super bueno") and the user
  responds in seconds, not minutes. Open-ended free-text questions slow
  the loop by 5-10x.

If the message is truly ambiguous AND no menu of 3-4 options is possible
(rarer than you'd think), open-ended is fine — but try the menu first.

## When NOT to use this skill

- If the user has already given you an approved spec or plan, skip triage
  and go directly to the relevant sub-skill (e.g., `superpowers-writing-plans`).
- If you're a subagent dispatched with an explicit task, skip triage.
- If the user message is part of an ongoing multi-turn workflow you've
  already classified (e.g., you're in the middle of brainstorming), skip
  triage.

## Cross-references

- `superpowers-skill-routing` — slower, more thorough routing with the
  full table. Use triage for snappiness; use routing for completeness.
- `superpowers-creative-workflow` — the orchestrator this skill routes TO.
- `superpowers-code-workflow` — the other orchestrator this skill routes TO.
- `superpowers-brainstorming` — the question cadence (menus 3-4 + recommendation) that triage's "ask one clarifying question" step must follow.

## License

MIT.
