We’re implementing a custom Claude code config:

# Custom PoC Stack — Implementation Plan v2

> **For Claude Code reading this fresh:** This plan describes a custom Claude Code stack for building enterprise PoCs. You are the implementer. Each phase has explicit file paths, full file contents to create, and verification steps. Read the entire plan once before starting, then execute phase by phase. Commit after each phase. Use Superpowers’ subagent-driven-development if available; otherwise execute directly. **Important:** Some external commands (CLI install paths, package names) may have changed since this plan was written — verify current install instructions via web search before running.

-----

## Mission

Build a Claude Code stack optimized for enterprise PoC delivery. Three goals: (1) higher-fidelity demos in less time, (2) defensive deliverables that preempt “did you try X” objections, (3) cross-tool memory for resuming work in Codex / Cursor / ChatGPT when Anthropic usage limits hit.

The stack is **Claude Code + Superpowers + cherry-picked gstack skills + four custom skills + a markdown wiki**. Do not install gstack wholesale; do not run its ./setup script. Cherry-pick specific skill folders only.

-----

## Prerequisites

Verify these are present before starting. If anything is missing, halt and report.

|Requirement                            |Verify with                                                                                 |If missing                                                                                                                   |
|---------------------------------------|--------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------|
|Claude Code installed                  |which claude                                                                              |Install per official docs                                                                                                    |
|Superpowers plugin installed           |ls ~/.claude/plugins/marketplaces/*superpowers* or /help shows /superpowers:brainstorm|Install via /plugin marketplace add obra/superpowers-marketplace then /plugin install superpowers@superpowers-marketplace|
|prior-art-survey skill installed     |ls ~/.claude/skills/prior-art-survey/SKILL.md                                             |Already delivered to the user separately. Halt if absent and ask.                                                            |
|Git, bash, standard Unix tools         |Should already be present                                                                   |—                                                                                                                            |
|OpenAI Codex CLI (for second-opinion)|which codex                                                                               |See Phase 0                                                                                                                  |

-----

## External repositories

You will need to reference (not clone wholesale) the following:

|Repo                                                                        |Purpose                          |What to read                            |
|----------------------------------------------------------------------------|---------------------------------|----------------------------------------|
|https://github.com/obra/superpowers                                       |Existing framework, do not modify|README only — confirms skill conventions|
|https://github.com/garrytan/gstack                                        |Cherry-pick source               |Specific skill folders listed in Phase 1|
|Codex CLI canonical repo (verify via web search — official OpenAI Codex CLI)|Codex CLI install instructions   |Install + auth section                  |

For gstack, you do not clone into ~/.claude/skills/. You clone to a scratch location (e.g., /tmp/gstack-source) and copy out only the skill folders specified.

-----

## Phase 0 — Codex CLI setup

The second-opinion skill (built in Phase 2) shells out to Codex CLI. Set it up first.

1. Web-search for current Codex CLI install instructions (the package name and install path may have changed since this plan was written; verify before running).
1. Install Codex CLI globally per current official docs.
1. Authenticate Codex CLI with the user’s OpenAI account. **Do not** put the OpenAI API key in any Claude Code config file — Codex CLI manages its own auth.
1. Verify with a smoke test: codex --version returns a version, and a trivial codex invocation against a small file returns output.

Halt and report if any step fails. Do not proceed to Phase 1 without working Codex CLI — the second-opinion skill depends on it.

-----

## Phase 1 — Cherry-pick gstack skills

Clone gstack to a scratch location, then copy specified skill folders into ~/.claude/skills/. Edit each copied SKILL.md to add a model: directive in YAML frontmatter (gstack skills default to whatever Claude Code is configured to, which is wasteful).
# Clone to scratch
git clone --depth 1 https://github.com/garrytan/gstack.git /tmp/gstack-source

# Verify expected skill folders exist; halt if not
for skill in cso office-hours plan-ceo-review qa design-shotgun design-html design-review codex document-release freeze guard; do
  if [ ! -d "/tmp/gstack-source/$skill" ]; then
    echo "MISSING: /tmp/gstack-source/$skill"
    exit 1
  fi
done

# Copy each into ~/.claude/skills/
mkdir -p ~/.claude/skills
for skill in cso office-hours plan-ceo-review qa design-shotgun design-html design-review codex document-release freeze guard; do
  cp -r "/tmp/gstack-source/$skill" ~/.claude/skills/
done
After copying, edit the YAML frontmatter of each skill’s SKILL.md (or equivalent entry file) to add a model: line. Match this table:

|gstack skill      |Model   |Reasoning                                                   |
|------------------|--------|------------------------------------------------------------|
|cso             |opus  |Security exploit reasoning is high-judgment work            |
|office-hours    |opus  |10x reframing — highest-judgment moment in pipeline         |
|plan-ceo-review |opus  |Strategic scope challenge                                   |
|qa              |sonnet|Audit against rubric, run known flows                       |
|design-shotgun  |sonnet|Image generation orchestration                              |
|design-html     |sonnet|Mockup → HTML pattern execution                             |
|design-review   |sonnet|Audit against design rubric                                 |
|codex           |sonnet|Just orchestrates the shell-out; Codex itself runs on OpenAI|
|document-release|sonnet|Read code, update docs against diffs                        |
|freeze          |haiku |Mechanical edit-lock                                        |
|guard           |haiku |Combines freeze and careful — both mechanical               |

If a skill file has no frontmatter or uses a different config mechanism, read its existing structure and add the model directive in whatever form that skill supports. If the skill does not support model selection, leave it and add a note to OUTSTANDING.md (create at repo root if needed).

**Verification:** Run claude and check /help shows the gstack commands (e.g., /cso, /office-hours). Each should be invokable without error on a trivial test input.

-----

## Phase 2 — Build four custom skills

Create the following four skills under ~/.claude/skills/. Each is a single SKILL.md file. Full content for each is below — copy verbatim, do not paraphrase.

### 2.1 — ~/.claude/skills/poc-wiki-init/SKILL.md
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

### 2. Create directory structure
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
### 3. Generate stub files
**index.md** — content-oriented catalog. Initial content:
# Wiki Index

One-line summary of every page in this wiki. Update on every page creation.

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
**log.md** — append-only chronological record. Initial content:
# Activity Log

Append-only. Format: ## [YYYY-MM-DD HH:MM] <operation> | <subject>

## [<current ISO timestamp>] init | wiki bootstrapped
**CLAUDE.md** — schema for Claude Code:
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
**AGENTS.md** — schema for Codex CLI:
# Project Context for Codex CLI

This project uses a markdown wiki at .planning/ as its single source of truth.

## Before any work

1. Read .planning/index.md.
2. Read .planning/handoffs/ for the most recent snapshot — Claude Code or another tool may have left state for you to resume from.

## Your role

You are likely being invoked because of one of these reasons:
- Cross-vendor second-opinion review (via the second-opinion skill in Claude Code).
- Direct user invocation because Claude usage limits were hit.

In either case, your output should be filed into .planning/ as a new page and logged in log.md.
**.cursor/rules** — schema for Cursor:
# Cursor Rules for this PoC

Wiki at .planning/ is single source of truth. Read .planning/index.md before any non-trivial work. Check .planning/handoffs/ for the most recent snapshot from another tool.

When producing notable output, file it back into .planning/ as a new page and update index.md.
**chatgpt-brief.md** — paste-into-ChatGPT primer:
# ChatGPT Context Primer for this PoC

Paste this into ChatGPT before asking questions about the project.

---

This project lives in a markdown wiki under .planning/. The relevant pages are:

[List the current contents of .planning/index.md here. The poc-wiki-init skill should populate this dynamically when first run; subsequent updates happen via handoff-snapshot.]

When I ask you about this project, I will paste relevant pages from .planning/ into the conversation. Your job is to reason about them and produce output I can file back into the wiki.
### 4. Initialize git
If the project is not already a git repo, run `git init` and add `.planning/` to be tracked. If it is, just `git add .planning/` and commit with message `wiki: bootstrap .planning/ structure`.
### 5. Optional remote
Ask the user whether they want to push the wiki to a private remote for cross-machine portability. If yes, prompt for the remote URL, configure it, and push. If no, skip — they can add it later.
### 6. Update log.md
Append: `## [<timestamp>] init | wiki bootstrapped`
## Output
Confirm to the user: "Wiki bootstrapped at .planning/. Schema files in place for Claude Code, Codex, Cursor, and ChatGPT. Run /office-hours next to start the founder-lens reframe."
### 2.2 — ~/.claude/skills/handoff-snapshot/SKILL.md
---
name: handoff-snapshot
description: Captures current Claude Code session state for cross-tool resumption. Activates when the user is about to hit Anthropic usage limits, deliberately switching tools, or pausing work for an extended period. Writes a continuation snapshot to .planning/handoffs/ that Codex CLI, Cursor, ChatGPT, or Gemini can read to resume work without losing context. Outputs a paste-ready prompt the user can drop into the next tool. Use proactively when context window is filling or limits are imminent.
model: haiku
---

# handoff-snapshot

## When to activate

- User mentions usage limits, hitting cap, switching tools, or pausing work.
- Context window is approaching limits and work is incomplete.
- User explicitly asks to "save state" or "snapshot" or "hand off".
- Before any planned tool switch.

## Process

### 1. Verify wiki exists

Check `.planning/` exists. If not, run poc-wiki-init first, or report that the project isn't wiki-enabled and offer to bootstrap one.

### 2. Generate snapshot

Write to `.planning/handoffs/<timestamp>-snapshot.md` with this structure:
# Handoff Snapshot — <timestamp>

## Context summary
[2-3 sentences: what is the user working on right now?]

## Recent decisions
[Bulleted list of decisions made in this session that aren't yet captured elsewhere in the wiki. If a decision is significant enough, ALSO file it as a separate page in vision/ or plans/ and update index.md.]

## Current task
[1-2 sentences: what was the user actively trying to do when this snapshot was taken?]

## Next steps
[Numbered list, ordered by priority. Each item should be specific enough that a fresh agent can act on it.]

## Open questions
[Anything blocked on user input or external answer.]

## Files touched this session
[List of files modified, with one-line summary of each change.]

## Continuation prompt
[A paste-ready prompt the user can drop into the next tool. Should reference this handoff file by path and include just enough context to resume. Keep under 200 words.]
### 3. Append to log.md
`## [<timestamp>] handoff | <reason: usage_limits / planned_switch / pause>`
### 4. Update index.md
Add the new handoff snapshot to the index with one-line summary.
### 5. Output to user
Show:
- Path to the snapshot file
- The continuation prompt (rendered as a copy-ready code block) for them to paste into the next tool
Example:
Snapshot written to: .planning/handoffs/2026-05-02-1430-snapshot.md

Paste this into your next tool (Codex / Cursor / ChatGPT / Gemini):

---
[continuation prompt here]
---
## Output
Snapshot file + paste-ready continuation prompt. User can now switch tools cleanly.
### 2.3 — ~/.claude/skills/second-opinion/SKILL.md
---
name: second-opinion
description: Generalized cross-model review. Dispatches an artifact (spec, diff, architecture decision) to OpenAI Codex CLI for independent review, then synthesizes Claude's view and Codex's view into a structured agreement/disagreement matrix. Produces a stakeholder-ready deliverable artifact that preempts "did you try X" objections from Monday-morning-quarterback architects. Activates at decision checkpoints (post-design, post-implementation, post-security review) or before stakeholder demos. Requires Codex CLI installed and authenticated.
model: opus
---

# second-opinion

## When to activate

- After design is locked but before implementation starts.
- After implementation is complete but before stakeholder demo.
- After /cso security review, on the same artifact, to cross-check security posture.
- When user explicitly asks for "second opinion", "cross-model review", "Codex check".

## Why this exists

Enterprise AI consulting is full of opinion-havers. Every vendor has a stack they evangelize, every architect has a framework they prefer. Documented cross-vendor review is defensive armor: "Yes, we ran the architecture through OpenAI Codex independently — here's where it agreed and here's the one finding it raised, which we addressed."

The output is a deliverable artifact, not a developer-facing review note.

## Process

### 1. Identify the artifact under review

Resolve from user input:
- A file path (spec, plan, diff)
- A git ref (branch, commit, PR)
- A wiki page (e.g., .planning/plans/phase-1.md)

If ambiguous, ask the user once.

### 2. Verify Codex CLI is available

Run `which codex`. If absent, halt and instruct user to complete Phase 0 of the implementation plan.

### 3. Dispatch to Codex CLI

Shell out to Codex CLI to produce an independent review of the artifact. Exact command depends on the current Codex CLI version — verify via `codex --help` if uncertain. The intent: Codex reads the artifact and produces a structured assessment with concerns, agreements, and alternatives considered.

Capture Codex's output as text. Do not let Codex modify any files.

### 4. Produce Claude's review

In parallel (or sequentially if parallel dispatch isn't available), produce Claude's own review of the same artifact using the same schema:
- Concerns (issues with the current approach)
- Agreements (things the approach gets right)
- Alternatives considered (what else was on the table and why this won)

### 5. Synthesize

Compare the two reviews. Produce output in this format:
# Cross-Model Review: <artifact name>

**Artifact:** <path or ref>
**Reviewers:** Claude Opus 4.7 (primary), OpenAI Codex (independent)
**Date:** <ISO date>

## Convergent findings

[Findings flagged by BOTH reviewers — strongest signal. Each finding gets:
- Description (1-2 sentences)
- Both reviewers' confidence level
- Recommended action]

## Divergent findings

[Findings raised by only ONE reviewer — weaker signal but worth examining. Each finding gets:
- Description
- Which reviewer flagged it
- Why the other may not have (model bias, scope, etc.)
- Recommended disposition (address / acknowledge / dismiss with reason)]

## Alternatives considered

[Architectural alternatives both reviewers considered. Table format:

| Approach | Claude position | Codex position | Verdict |
|----------|-----------------|----------------|---------|
| ...      | ...             | ...            | ...     |
]

## Net assessment

[2-3 sentences: did the cross-model review change any recommendation? If yes, what changed? If no, the convergence itself is the deliverable signal.]

## Methodology note

This review used Claude Opus 4.7 and OpenAI Codex (<version>) reviewing the same artifact independently. Disagreement is expected and informative — convergence on a finding strengthens its signal; divergence prompts examination.
### 6. File the output
Write to `.planning/reviews/second-opinion-<artifact-slug>-<date>.md`. Update `.planning/index.md`. Append to `.planning/log.md`.
### 7. Output to user
Show the synthesis directly in the conversation, plus the path to the filed copy.
## Notes
- Cost: Codex runs on the user's OpenAI account, separately from Anthropic. Each run consumes OpenAI credits.
- If Codex CLI fails (auth error, API outage, rate limit), produce Claude-only review with an explicit note that cross-model review was unavailable, and recommend retry.
- Do NOT recommend specific Codex CLI flags or models in this skill — they may change. Use Codex CLI's defaults; let users configure their own Codex CLI separately.
### 2.4 — ~/.claude/skills/stakeholder-pack/SKILL.md
---
name: stakeholder-pack
description: Synthesizes all engagement review artifacts into a single defense-ready stakeholder document. Reads vision, prior-art, design rationale, security review, and second-opinion outputs from the wiki, then produces a structured doc that preempts the standard enterprise PoC review questions. Activates before stakeholder demos, before final handoff, or whenever the user asks for an executive-ready summary of the work. Output is exportable to PDF or pasteable into a deck.
model: opus
---

# stakeholder-pack

## When to activate

- Before a stakeholder demo or executive review.
- Before final PoC handoff to the customer.
- When user asks for "executive summary", "stakeholder doc", "deliverable summary", "presentation prep".

## Why this exists

Enterprise stakeholders ask the same five questions every time:
1. Why did you build it this way?
2. What else did you consider, and why didn't you use it?
3. Is this secure?
4. How do we know it actually works?
5. What's the gap between this and production?

Pre-answering all five in the deliverable changes the meeting from "defend the work" to "discuss what's next."

## Process

### 1. Verify wiki has source material

Check `.planning/` for required inputs:
- `.planning/vision/reframed-vision.md` (or any file in vision/) — for "why we built it this way"
- `.planning/prior-art/*.md` — for "what else we considered"
- `.planning/reviews/security-*.md` (output of /cso) — for "is it secure"
- `.planning/reviews/design-*.md` (output of /design-review) — for design rationale
- `.planning/reviews/second-opinion-*.md` — for cross-vendor agreement

If any are missing, list them and ask the user whether to proceed with available material or pause to generate the missing pieces. Default to listing the gaps and proceeding — the pack should report what it has and what it doesn't.

### 2. Read source artifacts

Read each file. Extract the strongest claims and decisions, not full content.

### 3. Synthesize

Produce a document with this structure:
# Stakeholder Review Pack — <PoC name>

**Engagement:** <name>
**Date:** <ISO date>
**Author:** <user>
**Version:** <auto-incremented>

---

## Executive summary

[3-4 sentences. What was built, why it matters, what the demo shows.]

---

## Why we built it this way

[Pull from vision/. Cover:
- The original ask vs. the reframed vision (the 10x lens)
- Key decisions made during scoping
- What we deliberately chose NOT to build, and why]

---

## What else we considered

[Pull from prior-art/. Cover:
- The OSS projects we evaluated and rejected (with reason)
- The libraries we chose and the alternatives we passed on
- The architectural patterns considered]

This section directly answers "did you try X" — if X was considered and rejected, it's named here with reasoning.

---

## Architecture & implementation

[Cover:
- High-level architecture (1 paragraph + diagram if available)
- Key technology choices with rationale
- What's working, what's stubbed, what's mocked]

Be honest about what's PoC vs. what's production-ready. This section pre-answers "is this real."

---

## Security posture

[Pull from reviews/security-*.md (the /cso output). Condense to:
- Scope of review (OWASP Top 10? STRIDE? Both?)
- Findings summary (count by severity)
- What was addressed in this PoC
- What would need additional work for production]

This section pre-answers "is this secure."

---

## Independent cross-vendor review

[Pull from reviews/second-opinion-*.md. Condense to:
- Reviewers used (Claude + Codex, etc.)
- Convergent findings summary
- Divergent findings worth noting
- Net assessment]

This section pre-answers "did you only trust one AI" — and is the unique defensive moat.

---

## What we'd do differently for production

[Honest gap analysis. Cover:
- Hardening required (error handling, observability, auth)
- Scale considerations not addressed in PoC
- Compliance / regulatory work not done
- Estimated effort to productionize]

This section pre-answers "is this prod-ready" by getting ahead of it. Counterintuitively, naming the gaps explicitly INCREASES stakeholder confidence — it shows the team understands what was and wasn't in scope.

---

## Recommended next steps

[3-5 concrete next-step options, ordered by user value, with rough effort estimates.]

---

## Appendix

- Full security review: .planning/reviews/security-*.md
- Full prior-art survey: .planning/prior-art/*.md
- Full cross-model review: .planning/reviews/second-opinion-*.md
- Implementation plan: .planning/plans/*.md
### 4. File the output
Write to `.planning/stakeholder-pack/v<N>-<date>.md` where N auto-increments based on existing versions. Update `.planning/index.md`. Append to `.planning/log.md`.
### 5. Output to user
Confirm path. Note that the doc is markdown — for executive consumption, recommend they pipe it through their preferred markdown-to-PDF converter or paste into Gamma / a deck.
## Anti-patterns
- **Defensive theater.** If the pack reads as "preemptive damage control," there's a positioning problem upstream. The pack should read as confident architecture rationale, not apology. Tone: "we considered X, chose Y because Z" — not "we're sorry we didn't use X."
- **Padding.** Don't include sections you have no source material for. If second-opinion wasn't run, don't fabricate a section — note it as gap and proceed.
- **Hiding gaps.** The "what we'd do for production" section is critical. Pretending the PoC is prod-ready is the fastest way to lose credibility on transition.
-----

## Phase 3 — Configure CLAUDE.md and coexistence

After Phases 1 and 2 are complete, the user has Superpowers + prior-art-survey + 11 gstack skills + 4 custom skills installed. They need a top-level CLAUDE.md to declare lane ownership and prevent skill conflicts.

If a project already has a CLAUDE.md, append the section below. If not, create one at the project root:
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
-----

## Phase 4 — Verification

Run an end-to-end smoke test to confirm the stack works.

1. Create a throwaway project: mkdir /tmp/poc-stack-test && cd /tmp/poc-stack-test
1. Run claude and trigger poc-wiki-init. Confirm .planning/ is created with all expected files.
1. Run /office-hours with a trivial test prompt. Confirm it activates and produces a vision doc.
1. Run /superpowers:brainstorm on the vision. Confirm it activates without conflicting with /office-hours.
1. Trigger prior-art-survey. Confirm the three scouts dispatch in parallel and return structured output.
1. Run /cso on a stub file (any small code file). Confirm it produces a security review.
1. Trigger second-opinion on the same stub file. Confirm Codex CLI is invoked and synthesis runs.
1. Trigger stakeholder-pack. Confirm it reports gaps for missing inputs but produces a partial pack.
1. Trigger handoff-snapshot. Confirm it writes a snapshot and outputs a paste-ready prompt.
1. Inspect .planning/log.md — should show entries for every operation.

Halt and report any step that fails. Do not commit-and-call-it-done if any step fails silently — verify each.

-----

## Reference: Model routing matrix (full table)

For convenience, the complete model assignment across the stack:

|Skill                                       |Model |Phase     |
|--------------------------------------------|------|----------|
|/office-hours (gstack)                    |opus  |Expand    |
|/plan-ceo-review (gstack)                 |opus  |Expand    |
|Superpowers brainstorming                 |opus  |Refine    |
|Superpowers writing-plans                 |opus  |Plan      |
|prior-art-survey (custom, main context)   |opus  |Survey    |
|prior-art-oss-scout (custom subagent)     |sonnet|Survey    |
|prior-art-library-scout (custom subagent) |sonnet|Survey    |
|prior-art-patterns-scout (custom subagent)|sonnet|Survey    |
|Superpowers subagent-driven-development   |sonnet|Build     |
|/design-shotgun (gstack)                  |sonnet|Build     |
|/design-html (gstack)                     |sonnet|Build     |
|/qa (gstack)                              |sonnet|Polish    |
|/design-review (gstack)                   |sonnet|Polish    |
|/cso (gstack)                             |opus  |Polish    |
|second-opinion (custom)                   |opus  |Defend    |
|stakeholder-pack (custom)                 |opus  |Defend    |
|/codex (gstack)                           |sonnet|Defend    |
|/document-release (gstack)                |sonnet|Handoff   |
|poc-wiki-init (custom)                    |haiku |Setup     |
|handoff-snapshot (custom)                 |haiku |Cross-tool|
|/freeze, /guard (gstack)                |haiku |Safety    |

**Principle:** opus for judgment moments (scoping, security reasoning, cross-model synthesis, stakeholder framing). sonnet for execution moments (implementation, audits, conversions). haiku for housekeeping (templating, summarizing, mechanical operations).

-----

## Reference: Phase pipeline
EXPAND  →  REFINE   →  SURVEY   →  PLAN     →  BUILD    →  POLISH   →  DEFEND   →  HANDOFF
gstack     superpwrs   custom      superpwrs   superpwrs   gstack      custom      gstack
                                               + gstack                            + custom
/office-   brainstorm  prior-art-  writing-    subagent-   /qa         second-     /document-
hours                  survey      plans       driven-dev  /design-    opinion     release
/plan-ceo-                                     /design-    review                  handoff-
review                                         shotgun     /cso        stakeholder-snapshot
                                               /design-                pack
                                               html
-----

## Out of scope / not implementing

These were considered and explicitly rejected. Do not implement them as part of this plan.

|Skipped                                                                               |Reason                                                                                                                |
|--------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------|
|Full gstack install                                                                   |Adoption tax, conflicts with Superpowers, overlap with custom skills                                                  |
|gstack /autoplan, /plan-eng-review, /plan-design-review                         |Overlap Superpowers’ planning lane                                                                                    |
|gstack /investigate, /review, /ship, /land-and-deploy, /canary, /benchmark|Prod-shipping discipline; PoC mission doesn’t need it                                                                 |
|gstack /retro, /pair-agent, /learn, gbrain integration                          |Solve problems outside PoC mission                                                                                    |
|LiteLLM gateway                                                                       |Adds proxy complexity for one OpenAI shell-out; not worth it. Revisit if multiple non-Anthropic models become routine.|
|MCP-based memory                                                                      |~6K token tax per session; markdown wiki achieves the same goal with zero overhead                                    |
|Custom voice-input integration                                                        |Already supported by AquaVoice / Whisper; no skill work needed                                                        |

-----

## Notes for the implementer

- **Verify external commands.** Codex CLI install path, gstack repo URL, and Superpowers install method may have changed since this plan was written. Web-search current docs before running install commands.
- **Commit per phase.** Each phase produces a clean change set. Commit at phase boundaries with messages like phase-1: cherry-pick gstack skills so rollback is granular.
- **Report blockers, don’t guess.** If a step fails (missing file, command not found, auth error), halt and report. Do not improvise — the user needs to know what went wrong.
- **Idempotency.** All four custom skills should detect existing state and not overwrite. Verify this by running each skill twice on the same project; the second run should report current state and exit cleanly.
- **No editorial.** This plan deliberately omits philosophical justification for each choice. The user has already approved the design; your job is execution.