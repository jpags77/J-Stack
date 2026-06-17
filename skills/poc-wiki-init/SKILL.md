---
name: poc-wiki-init
description: Bootstraps a markdown-wiki memory layer for a new PoC engagement. Creates the directory structure under .planning/, generates per-tool schema files (CLAUDE.md, AGENTS.md, .cursor/rules), initializes index.md and log.md with proper conventions, and optionally configures a private git remote for cross-machine portability. Activates whenever a new PoC engagement begins or when an existing project lacks .planning/ infrastructure. Used to enable cross-tool handoff when Anthropic usage limits force a switch to Codex / Cursor / ChatGPT / Gemini mid-engagement.
model: haiku
---

# poc-wiki-init

## When to activate

Run when starting a new PoC engagement, or when joining an existing project that lacks `.planning/` infrastructure. Idempotent — running on a project that already has `.planning/` reports current state and exits without overwriting.

## Why this exists

The same wiki must be readable by Claude Code, Codex CLI, Cursor, ChatGPT, and Gemini. Each tool reads its own schema file (CLAUDE.md, AGENTS.md, etc.), but the wiki content is one source of truth. When Claude usage limits force a tool switch mid-PoC, the new tool reads the wiki and resumes — no re-explanation needed.

## Process

### 1. Detect existing state

Check whether `.planning/` exists in the project root:
- If it does not: proceed to step 2.
- If it does: read `index.md`, summarize current state to the user, and exit. Do not modify.

### 2. Capture fidelity target

Before creating any files, ask:

"What level of functionality are we targeting for this engagement?
  A) Working PoC — functional core logic, real integrations, key edge cases handled, something that can be built upon
  B) Polished demo — looks great and works on the happy path, mocked data acceptable
  C) MVP — production-ready enough to put in front of real users"

Record the answer. It will be written into `index.md` in step 4. This answer governs how every phase is executed — it is not cosmetic.

### 3. Create directory structure

```
.planning/
├── index.md
├── log.md
├── CLAUDE.md
├── AGENTS.md
├── .cursor/
│   └── rules
├── chatgpt-brief.md
├── vision/
├── prior-art/
├── plans/
├── reviews/
├── stakeholder-pack/
├── handoffs/
└── raw/
```

### 4. Generate stub files

**index.md** — content-oriented catalog. Initial content:

```markdown
# Wiki Index

One-line summary of every page in this wiki. Update on every page creation.

## Current State

**Iteration:** 1
**Phase:** Not started — run session-start at the beginning of each session
**Fidelity target:** [answer from fidelity question above — A/B/C and description]
**Last updated:** [current ISO timestamp]

## vision/
(empty — populate after /office-hours)

## prior-art/
(empty — populate after prior-art-survey)

## plans/
(empty — populate after writing-plans)

## reviews/
(empty — populate after /design-review, /cso, second-opinion)

## stakeholder-pack/
(empty — populate after stakeholder-pack)

## handoffs/
(empty — populate when switching tools)
```

**log.md** — append-only chronological record. Initial content:

```markdown
# Activity Log

Append-only. Format: ## [YYYY-MM-DD HH:MM] <operation> | <subject>

## [<current ISO timestamp>] init | wiki bootstrapped
```

**CLAUDE.md** — schema for Claude Code:

```markdown
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

## Work checkpoints

After significant code interactions, create a durable checkpoint before switching tasks:

1. Commit the coherent git diff locally.
2. Update `.planning/` with notable decisions, review output, or changed state.
3. Append `.planning/log.md`.
4. Run `handoff-snapshot`.

Do not push to GitHub automatically. Push only when the user asks or an explicit publish workflow is active.
```

**AGENTS.md** — schema for Codex CLI:

```markdown
# Project Context for Codex CLI

This project uses a markdown wiki at .planning/ as its single source of truth.

## Before any work

1. Read .planning/index.md.
2. Read .planning/log.md for recent activity.
3. Read .planning/handoffs/ for the most recent snapshot - Claude Code or another tool may have left state for you to resume from.

## Phase pipeline

EXPAND -> REFINE -> SURVEY -> PLAN -> BUILD -> POLISH -> DEFEND -> HANDOFF

Respect the lane ownership from the root AGENTS.md/CLAUDE.md files. Do not skip ahead to implementation when the wiki says the project is still in an earlier phase.

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
```

**.cursor/rules** — schema for Cursor:

```markdown
# Cursor Rules for this PoC

Wiki at .planning/ is single source of truth. Read .planning/index.md before any non-trivial work. Check .planning/handoffs/ for the most recent snapshot from another tool.

When producing notable output, file it back into .planning/ as a new page and update index.md.
```

**chatgpt-brief.md** — paste-into-ChatGPT primer:

```markdown
# ChatGPT Context Primer for this PoC

Paste this into ChatGPT before asking questions about the project.

---

This project lives in a markdown wiki under .planning/. The relevant pages are:

[List the current contents of .planning/index.md here. The poc-wiki-init skill should populate this dynamically when first run; subsequent updates happen via handoff-snapshot.]

When I ask you about this project, I will paste relevant pages from .planning/ into the conversation. Your job is to reason about them and produce output I can file back into the wiki.
```

### 5. Initialize git

If the project is not already a git repo, run `git init` and add `.planning/` to be tracked. If it is, just `git add .planning/` and commit with message `wiki: bootstrap .planning/ structure`.

### 6. Optional remote

Ask the user whether they want to push the wiki to a private remote for cross-machine portability. If yes, prompt for the remote URL, configure it, and push. If no, skip — they can add it later.

### 7. Update log.md

Append: `## [<timestamp>] init | wiki bootstrapped`

## Output

Confirm to the user: "Wiki bootstrapped at .planning/. Schema files in place for Claude Code, Codex, Cursor, and ChatGPT. Run session-start at the beginning of each session, then /office-hours to start the founder-lens reframe."