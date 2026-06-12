# Project Context for Codex CLI

This project uses a markdown wiki at .planning/ as its single source of truth.

## Before any work

1. Read .planning/index.md.
2. Read .planning/log.md for recent activity.
3. Read .planning/handoffs/ for the most recent snapshot - Claude Code or another tool may have left state for you to resume from.

## Phase pipeline

EXPAND -> REFINE -> SURVEY -> PLAN -> BUILD -> POLISH -> DEFEND -> HANDOFF

Respect the lane ownership from the root AGENTS.md/CLAUDE.md files. Do not skip ahead to implementation when the wiki says the project is still in an earlier phase.

### Prior-art gate (SURVEY before PLAN)

Before writing or following an implementation plan, `.planning/index.md` must show `Prior-art: ✅ complete` in its Current State block. If it shows `⬜ pending` (or the flag is missing), run the prior-art survey first — use the bundled prior-art skill files, make a build/adopt/fork/hybrid recommendation, then set the flag to `✅ complete` in index.md and log it. Do not begin planning while prior-art is pending. This holds even when refinement would otherwise hand straight off to planning — SURVEY is never skipped, and prior-art runs at least once before implementation.

## Codex operating modes

You are likely being invoked because of one of these reasons:

- **Fallback mode:** Claude usage limits were hit, or the user deliberately switched tools. Resume from the latest wiki state and continue the current phase.
- **Review mode:** Claude invoked Codex for cross-vendor `second-opinion` review. Inspect the requested artifact independently and produce findings suitable for `.planning/reviews/`.

In either case, your output should be filed into .planning/ as a new page and logged in log.md.

## Work checkpoints

After significant code interactions, create a durable checkpoint before switching tasks:

1. Commit the coherent git diff locally.
2. Update `.planning/` with notable decisions, review output, or changed state.
3. Append `.planning/log.md`.
4. Run `handoff-snapshot`.

Do not push to GitHub automatically. Push only when the user asks or an explicit publish workflow is active.

## Claude skill mapping for Codex

Claude slash commands and skills are process labels. In Codex, map them to equivalent behavior:

| Claude surface | Codex behavior |
| --- | --- |
| `/office-hours`, `/plan-ceo-review` | Challenge problem framing, scope, and MVP shape in EXPAND. |
| `superpowers:brainstorming` | Refine requirements and compare approaches before planning. |
| `prior-art-survey` | Use the bundled prior-art skill files and current research to make a build/adopt/fork/hybrid recommendation. |
| `superpowers:writing-plans` | Create or follow the implementation plan before editing code. |
| `superpowers:subagent-driven-development` | Execute the plan in small, test-driven, isolated changes. |
| `/qa`, `/design-review`, `/cso` | Verify behavior, UX, and security/risk posture in POLISH. |
| `second-opinion` | Act as the independent reviewer and write review-ready findings. |
| `handoff-snapshot` | Write `.planning/handoffs/<timestamp>-snapshot.md` as a structured blackboard before pausing, switching tools, or checkpointing significant work. |
