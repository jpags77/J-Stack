# Wiki Index

One-line summary of every page in this wiki. Update on every page creation.

## Current State

**Iteration:** 1
**Phase:** EXPAND
**Fidelity target:** C — MVP (production-ready Claude Code skill stack)
**Prior-art:** ⬜ pending
**Last updated:** 2026-06-17T00:00:00Z

## Iteration Progress

Which phase steps have run in the **current** iteration. Reset all to ⬜ when the iteration bumps (session-start step 6). `[auto]` = session-start can confirm from a wiki artifact; `[confirm]` = no reliable wiki trace, so session-start asks the user and records the answer here.

- [EXPAND] office-hours — ✅  `[auto: vision/]`
- [EXPAND] plan-ceo-review — ⬜  `[confirm]`
- [REFINE] brainstorming — ⬜  `[confirm]`
- [SURVEY] prior-art-survey — ⬜  `[auto: Prior-art flag above — authoritative]`
- [PLAN] writing-plans — ⬜  `[auto: plans/]`
- [PLAN] ponytail-review spec — ⬜  `[confirm]`
- [BUILD] subagent-driven-development — ⬜  `[auto: commits since plan]`
- [POLISH] qa — ⬜  `[auto: reviews/qa-*]`
- [POLISH] design-review — ⬜  `[auto: reviews/design-*]`
- [POLISH] cso — ⬜  `[auto: reviews/security-*]`
- [DEFEND] second-opinion — ⬜  `[auto: reviews/second-opinion-*]`
- [DEFEND] stakeholder-pack — ⬜  `[auto: stakeholder-pack/]`
- [HANDOFF] document-release — ⬜  `[confirm]`
- [HANDOFF] handoff-snapshot — ⬜  `[auto: handoffs/]`

## Engagement Context

**Goal:** Maintain and improve j-stack as a production-ready Claude Code skill stack — keep it lean, current, and well-structured as a reusable foundation for enterprise PoC delivery.
**Constraints:** Must remain a single-command install; no new external dependencies without clear justification; skills-as-files pattern established 2026-06-17 is now the standard.
**Done when:** Pipeline, tooling, and documentation are coherent, tested, and ready for use on new PoC engagements.
**Prior docs:** CLAUDE.md, AGENTS.md, .planning/ wiki, skills/ and agents/ directories.

## vision/
- [understand-anything-integration.md](vision/understand-anything-integration.md) — CLOSED: Understand-Anything integration evaluated and rejected (scope mismatch)
- [codex-integration.md](vision/codex-integration.md) — implemented design for treating Codex as a first-class fallback and review runtime via AGENTS.md + .planning/
- [handoff-blackboard.md](vision/handoff-blackboard.md) — accepted design for structured handoff snapshots with typed state, provenance, conflicts, and checkpoint policy
- [ponytail-integration.md](vision/ponytail-integration.md) — ponytail plugin integration: plan-gate decision, full level, audit findings, /goal and auto-research context
- [graphify-integration.md](vision/graphify-integration.md) — graphify on-demand knowledge graph: session-start detection, existing-repo use case, wiki convention
- [headroom-integration.md](vision/headroom-integration.md) — headroom context compression: global triggers + j-stack pipeline checkpoints

## prior-art/
(empty — populate after prior-art-survey)

## plans/
- [2026-06-17-ponytail-fixes.md](plans/2026-06-17-ponytail-fixes.md) — ponytail audit fixes: skill extraction, install.sh shrink (-807 lines), vanilla HTML

## reviews/
(empty — populate after /qa, /design-review, /cso, second-opinion)

## stakeholder-pack/
(empty — populate after stakeholder-pack)

## handoffs/
(empty — populate when switching tools)
