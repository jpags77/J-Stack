# Project Context

## Stack ownership (skill lane management)

Multiple skill packs are installed. Each owns a specific phase of the workflow:

- **Front-end scoping (Expand phase):** /office-hours, /plan-ceo-review (gstack)
- **Refining (Refine phase):** Superpowers brainstorming
- **Prior art (Survey phase):** prior-art-survey (custom)
- **Planning (Plan phase):** Superpowers writing-plans
- **Building (Build phase):** Superpowers subagent-driven-development, with /design-shotgun + /design-html for UI work
- **Polishing (Polish phase):** /qa, /design-review, /cso (gstack)
- **Defending (Defend phase):** second-opinion, stakeholder-pack (custom)
- **Handoff:** /document-release (gstack), handoff-snapshot (custom)

Run them in order. Do NOT use gstack's /autoplan or /plan-eng-review — they overlap Superpowers' planning lane and create conflicts.

## Wiki

This project's source of truth lives at `.planning/`. Read `.planning/index.md` before any non-trivial work. Check `.planning/handoffs/` for the most recent snapshot — another tool may have left state for you to resume from.

## Cross-tool

When usage limits hit, run `handoff-snapshot` and resume in Codex / Cursor / ChatGPT / Gemini. Each has its own schema file in `.planning/`.

## Codex role

Codex is a first-class j-stack runtime with two primary operating modes:

- **Fallback mode:** Claude Code hits usage limits or the user deliberately switches tools. Resume from `.planning/index.md`, the latest `.planning/handoffs/` snapshot, and `.planning/log.md`.
- **Review mode:** Claude invokes Codex for an independent `second-opinion` review. Inspect only the requested artifact unless the prompt asks for broader repo context, and return findings suitable for filing under `.planning/reviews/`.

In both modes, keep `.planning/` as the durable source of truth. Notable analysis, decisions, reviews, and handoff state should be written into the appropriate `.planning/` section and logged in `.planning/log.md`.

## Claude skill mapping for Codex

Claude slash commands and skills are the source names for the process. In Codex, follow the same lane semantics even when the command itself is not available:

| Claude surface | Codex behavior |
| --- | --- |
| `/office-hours`, `/plan-ceo-review` | Run EXPAND as a problem/scope challenge before design work. |
| `superpowers:brainstorming` | Refine requirements and approaches before planning or code edits. |
| `prior-art-survey` | Use the bundled prior-art skill files and web/package research where available. |
| `superpowers:writing-plans` | Produce or follow a locked implementation plan before BUILD work. |
| `superpowers:subagent-driven-development` | Keep implementation scoped, isolated, test-driven, and spec-bound. |
| `/qa`, `/design-review`, `/cso` | Treat POLISH as verification, UX review, and security/risk review. |
| `second-opinion` | Usually means Codex is the independent reviewer; produce review artifacts, not edits. |
| `handoff-snapshot` | Write a timestamped `.planning/handoffs/` snapshot before switching tools or pausing. |
