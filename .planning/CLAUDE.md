# Project Context for Claude Code

This project uses a markdown wiki at .planning/ as its single source of truth.

## Before any non-trivial work

1. Read .planning/index.md to understand existing state.
2. Read .planning/log.md to see recent activity.
3. Check .planning/handoffs/ for the most recent snapshot if one exists — another tool may have left state for you.

## Stack ownership (avoid skill conflicts)

- Superpowers + prior-art-survey owns: brainstorming, planning, building (think → plan → build).
- gstack contributes: front-end scoping (/office-hours, /plan-ceo-review), fidelity polish (/qa, /design-*, /cso), handoff docs (/document-release).
- Custom skills contribute: prior-art-survey, second-opinion, stakeholder-pack, poc-wiki-init, handoff-snapshot.

## Wiki maintenance

When you produce notable output (a decision, a comparison, an analysis), file it back into the wiki as a new page and update index.md. The wiki compounds rather than just accumulates.

When approaching context limits or about to switch tools, run handoff-snapshot.
