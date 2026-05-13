#!/usr/bin/env bash
# j-stack install script
# Sets up the Claude Code enterprise PoC stack:
#   Superpowers + cherry-picked gstack skills + 4 custom skills + CLAUDE.md lane config
#
# Usage: bash install.sh [--skip-codex] [--skip-verify]

set -euo pipefail

SKIP_CODEX=false
SKIP_VERIFY=false
for arg in "$@"; do
  case $arg in
    --skip-codex)  SKIP_CODEX=true ;;
    --skip-verify) SKIP_VERIFY=true ;;
  esac
done

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; NC='\033[0m'
info()  { echo -e "${GREEN}[j-stack]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*" >&2; }
halt()  { error "$*"; exit 1; }

SKILLS_DIR="${HOME}/.claude/skills"

# ─── Phase 0: Prerequisites ───────────────────────────────────────────────────

info "Checking prerequisites…"

command -v claude &>/dev/null || halt "claude not found. Install Claude Code first: https://claude.ai/code"
command -v git    &>/dev/null || halt "git not found."
command -v bash   &>/dev/null || halt "bash not found."

# Check Superpowers plugin
if ! claude --help 2>/dev/null | grep -q "superpowers\|brainstorm"; then
  warn "Superpowers plugin not detected in 'claude --help' output."
  warn "Install it inside Claude Code with:"
  warn "  /plugin marketplace add obra/superpowers-marketplace"
  warn "  /plugin install superpowers@superpowers-marketplace"
  read -rp "Continue anyway? [y/N] " yn
  [[ $yn =~ ^[Yy]$ ]] || halt "Aborted. Install Superpowers first."
fi

# prior-art skills are bundled in this repo — installed in Phase 2.5 below

# ─── Phase 0.5: Codex CLI ─────────────────────────────────────────────────────

if [ "$SKIP_CODEX" = false ]; then
  info "Phase 0 — Codex CLI setup…"
  if command -v codex &>/dev/null; then
    CODEX_VER=$(codex --version 2>/dev/null || echo "unknown")
    info "Codex CLI already installed: ${CODEX_VER}"
  else
    warn "Codex CLI not found."
    warn "The second-opinion skill requires it. Install it per current OpenAI docs:"
    warn "  https://github.com/openai/codex  (verify current install method)"
    warn "Typical install: npm install -g @openai/codex"
    read -rp "Skip Codex CLI setup and continue? [y/N] " yn
    [[ $yn =~ ^[Yy]$ ]] || halt "Aborted. Install Codex CLI, then re-run install.sh."
  fi
fi

# ─── Phase 1: Cherry-pick gstack skills ───────────────────────────────────────

info "Phase 1 — Cherry-picking gstack skills…"

GSTACK_SCRATCH="/tmp/gstack-source"

if [ -d "$GSTACK_SCRATCH" ]; then
  info "Updating existing gstack clone at ${GSTACK_SCRATCH}…"
  git -C "$GSTACK_SCRATCH" pull --ff-only 2>/dev/null || true
else
  info "Cloning gstack to ${GSTACK_SCRATCH}…"
  git clone --depth 1 https://github.com/garrytan/gstack.git "$GSTACK_SCRATCH"
fi

GSTACK_SKILLS=(cso office-hours plan-ceo-review qa design-shotgun design-html design-review codex document-release freeze guard)

missing=()
for skill in "${GSTACK_SKILLS[@]}"; do
  [ -d "${GSTACK_SCRATCH}/${skill}" ] || missing+=("$skill")
done
if [ ${#missing[@]} -gt 0 ]; then
  halt "Missing gstack skill folders: ${missing[*]}. gstack repo may have changed. Check and update install.sh."
fi

mkdir -p "$SKILLS_DIR"

declare -A GSTACK_MODELS=(
  [cso]=opus
  [office-hours]=opus
  [plan-ceo-review]=opus
  [qa]=sonnet
  [design-shotgun]=sonnet
  [design-html]=sonnet
  [design-review]=sonnet
  [codex]=sonnet
  [document-release]=sonnet
  [freeze]=haiku
  [guard]=haiku
)

for skill in "${GSTACK_SKILLS[@]}"; do
  dest="${SKILLS_DIR}/${skill}"
  cp -r "${GSTACK_SCRATCH}/${skill}" "${SKILLS_DIR}/"
  model="${GSTACK_MODELS[$skill]}"

  # Find the main skill entry file
  entry=""
  for candidate in "${dest}/SKILL.md" "${dest}/skill.md" "${dest}/README.md"; do
    [ -f "$candidate" ] && entry="$candidate" && break
  done

  if [ -z "$entry" ]; then
    warn "Could not find entry file for gstack/${skill} — skipping model injection"
    continue
  fi

  # Inject model: directive into YAML frontmatter if not already present
  if head -1 "$entry" | grep -q "^---"; then
    if ! grep -q "^model:" "$entry"; then
      # Insert after opening ---
      sed -i.bak "1a\\
model: ${model}" "$entry"
      rm -f "${entry}.bak"
    fi
  else
    # No frontmatter — prepend it
    tmpfile=$(mktemp)
    printf -- "---\nmodel: %s\n---\n" "$model" | cat - "$entry" > "$tmpfile"
    mv "$tmpfile" "$entry"
  fi

  info "  Installed gstack/${skill} (model: ${model})"
done

# ─── Phase 2: Custom skills ────────────────────────────────────────────────────

info "Phase 2 — Installing custom skills…"

install_skill() {
  local name="$1"
  local dest="${SKILLS_DIR}/${name}"
  mkdir -p "$dest"
  cat > "${dest}/SKILL.md"
  info "  Installed custom skill: ${name}"
}

# 2.1 poc-wiki-init
install_skill "poc-wiki-init" <<'SKILL_EOF'
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
├── backlog.md
├── CLAUDE.md
├── AGENTS.md
├── .cursor/
│   └── rules
├── chatgpt-brief.md
├── state/
│   ├── project-state.yml
│   └── active-constraints.md
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
**Phase:** See `.planning/state/project-state.yml` (authoritative) — current: discovery
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

## Runtime state (read this first)

`.planning/state/project-state.yml` is the authoritative operational source of truth. Read it before any non-trivial work. It defines:
- Current phase (do not infer from conversation — use the file)
- Allowed and blocked work
- Active constraints
- Current goal

If you are mid-session and resuming after a context refresh, re-read `project-state.yml` before continuing. Do not rely on what you remember from earlier in the conversation.

## Before any non-trivial work

1. Read .planning/state/project-state.yml — phase, allowed work, active constraints.
2. Read .planning/index.md — iteration, fidelity level, what's been completed.
3. Read .planning/log.md — last 15 entries for recent activity.
4. Check .planning/handoffs/ for the most recent snapshot if one exists — another tool may have left state for you.

## Stack ownership (avoid skill conflicts)

- Superpowers + prior-art-survey owns: brainstorming, planning, building (think → plan → build).
- gstack contributes: front-end scoping (/office-hours, /plan-ceo-review), fidelity polish (/qa, /design-*, /cso), handoff docs (/document-release).
- Custom skills contribute: prior-art-survey, second-opinion, stakeholder-pack, poc-wiki-init, handoff-snapshot.

## Wiki maintenance

When you produce notable output (a decision, a comparison, an analysis), file it back into the wiki as a new page and update index.md. The wiki compounds rather than just accumulates.

After any significant change, update `state/project-state.yml` last_updated and append to log.md.

When approaching context limits or about to switch tools, run handoff-snapshot.
```

**AGENTS.md** — schema for Codex CLI:

```markdown
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

**state/project-state.yml** — authoritative runtime state. Initial content:

```yaml
project:
  name: [project directory name]
  mode: exploratory
  lifecycle: poc

current_state:
  phase: discovery
  focus: initial-orientation
  confidence: low
  last_updated: [current ISO timestamp]

active_goal:
  id: goal-001
  title: Initial project orientation
  desired_outcome: Fidelity target confirmed, session goal recorded, dispatch to correct phase

allowed_work:
  - inspect_existing_files
  - update_planning_docs
  - ask_clarifying_questions
  - run_session_start

blocked_work:
  - coding_without_approved_plan
  - architecture_changes_without_decision
  - deleting_planning_structure

active_constraints:
  - file_all_output_to_planning_wiki
  - preserve_markdown_first_design
  - keep_human_readable
  - no_silent_phase_changes

required_before_coding:
  - read state/project-state.yml
  - confirm phase allows implementation
  - identify active task in backlog.md

required_after_coding:
  - update backlog.md task status
  - append to log.md
  - update state/project-state.yml last_updated
```

**state/active-constraints.md** — human-readable constraint registry. Initial content:

```markdown
# Active Constraints

Constraints in effect for this project. Do not violate without logging a decision in log.md.

## Always active

- All output filed to .planning/ wiki
- Human-readable, markdown-first artifacts
- No silent phase changes — log transitions to log.md with reason
- Re-read state/project-state.yml before significant changes mid-session

## Phase-specific

(populated as work progresses — update when entering a new phase)

## Blocked approaches

(populated after architecture decisions — record what was ruled out and why)
```

**backlog.md** — state-aware task list. Initial content:

```markdown
# Backlog

Tasks include phase, entry criteria, and exit criteria. Update status in real time.

## Format

### T-NNN — [title]
Status: ready | in-progress | blocked | done
Phase: [phase name]
Mode: exploratory | cautious | aggressive | debug | polish
Priority: high | medium | low

Entry criteria:
- [what must be true before starting]

Constraints:
- [task-specific constraints]

Exit criteria:
- [what must be true to call it done]

---

## T-001 — Initial project orientation

Status: ready
Phase: discovery
Mode: exploratory
Priority: high

Entry criteria:
- Wiki bootstrapped

Constraints:
- No coding until PLAN phase complete

Exit criteria:
- /office-hours complete
- Fidelity target confirmed
- Session goal recorded in log.md
```

### 5. Initialize git

If the project is not already a git repo, run `git init` and add `.planning/` to be tracked. If it is, just `git add .planning/` and commit with message `wiki: bootstrap .planning/ structure`.

### 6. Optional remote

Ask the user whether they want to push the wiki to a private remote for cross-machine portability. If yes, prompt for the remote URL, configure it, and push. If no, skip — they can add it later.

### 7. Update log.md

Append: `## [<timestamp>] init | wiki bootstrapped`

## Output

Confirm to the user: "Wiki bootstrapped at .planning/. Schema files in place for Claude Code, Codex, Cursor, and ChatGPT. Run session-start at the beginning of each session, then /office-hours to start the founder-lens reframe."
SKILL_EOF

# 2.2 handoff-snapshot
install_skill "handoff-snapshot" <<'SKILL_EOF'
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

```markdown
# Handoff Snapshot — <timestamp>

## Context summary
[2-3 sentences: what is the user working on right now?]

## Recent decisions
[Bulleted list of decisions made in this session that aren't yet captured elsewhere in the wiki.]

## Current task
[1-2 sentences: what was the user actively trying to do when this snapshot was taken?]

## Next steps
[Numbered list, ordered by priority. Each item should be specific enough that a fresh agent can act on it.]

## Open questions
[Anything blocked on user input or external answer.]

## Files touched this session
[List of files modified, with one-line summary of each change.]

## Continuation prompt
[A paste-ready prompt the user can drop into the next tool. Reference this handoff file by path. Keep under 200 words.]
```

### 3. Update project-state.yml

If `.planning/state/project-state.yml` exists:
- Set `current_state.last_updated` to current timestamp
- If the phase changed during this session, update `current_state.phase` to reflect where work stopped
- Do not modify `allowed_work`, `blocked_work`, or `active_constraints` — those require explicit user decision

### 4. Append to log.md

`## [<timestamp>] handoff | <reason: usage_limits / planned_switch / pause> | phase: [current phase]`

### 5. Update index.md

Add the new handoff snapshot to the index with one-line summary.

### 6. Output to user

Show:
- Path to the snapshot file
- The continuation prompt (rendered as a copy-ready code block)

## Output

Snapshot file + paste-ready continuation prompt. User can now switch tools cleanly.
SKILL_EOF

# 2.3 second-opinion
install_skill "second-opinion" <<'SKILL_EOF'
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

Enterprise AI consulting is full of opinion-havers. Documented cross-vendor review is defensive armor: "Yes, we ran the architecture through OpenAI Codex independently — here's where it agreed and here's the one finding it raised, which we addressed."

The output is a deliverable artifact, not a developer-facing review note.

## Process

### 1. Identify the artifact under review

Resolve from user input:
- A file path (spec, plan, diff)
- A git ref (branch, commit, PR)
- A wiki page (e.g., .planning/plans/phase-1.md)

If ambiguous, ask the user once.

### 2. Verify Codex CLI is available

Run `which codex`. If absent, halt and instruct user to install Codex CLI.

### 3. Dispatch to Codex CLI

Shell out to Codex CLI to produce an independent review of the artifact. Verify current flags via `codex --help`. Capture output as text. Do not let Codex modify files.

### 4. Produce Claude's review

Produce Claude's own review of the same artifact:
- Concerns (issues with the current approach)
- Agreements (things the approach gets right)
- Alternatives considered (what else was on the table and why this won)

### 5. Synthesize

```markdown
# Cross-Model Review: <artifact name>

**Artifact:** <path or ref>
**Reviewers:** Claude Opus 4.7 (primary), OpenAI Codex (independent)
**Date:** <ISO date>

## Convergent findings
[Findings flagged by BOTH reviewers — strongest signal.]

## Divergent findings
[Findings raised by only ONE reviewer.]

## Alternatives considered

| Approach | Claude position | Codex position | Verdict |
|----------|-----------------|----------------|---------|

## Net assessment
[2-3 sentences: did the cross-model review change any recommendation?]

## Methodology note
This review used Claude Opus 4.7 and OpenAI Codex (<version>) reviewing the same artifact independently.
```

### 6. File the output

Write to `.planning/reviews/second-opinion-<artifact-slug>-<date>.md`. Update `.planning/index.md`. Append to `.planning/log.md`.

### 7. Output to user

Show the synthesis directly in the conversation, plus the path to the filed copy.

## Notes

- Cost: Codex runs on the user's OpenAI account, separately from Anthropic.
- If Codex CLI fails, produce Claude-only review with an explicit note and recommend retry.
- Do NOT hardcode Codex CLI flags — use its defaults; they may change.
SKILL_EOF

# 2.4 stakeholder-pack
install_skill "stakeholder-pack" <<'SKILL_EOF'
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
- `.planning/vision/` — for "why we built it this way"
- `.planning/prior-art/` — for "what else we considered"
- `.planning/reviews/security-*.md` (output of /cso) — for "is it secure"
- `.planning/reviews/design-*.md` — for design rationale
- `.planning/reviews/second-opinion-*.md` — for cross-vendor agreement

If any are missing, list them and ask the user whether to proceed with available material. Default: list gaps and proceed.

### 2. Read source artifacts

Read each file. Extract strongest claims and decisions, not full content.

### 3. Synthesize

```markdown
# Stakeholder Review Pack — <PoC name>

**Engagement:** <name>
**Date:** <ISO date>
**Author:** <user>
**Version:** <auto-incremented>

---

## Executive summary
[3-4 sentences. What was built, why it matters, what the demo shows.]

## Why we built it this way
[Pull from vision/. Cover the original ask vs. reframed vision, key decisions, what was deliberately not built.]

## What else we considered
[Pull from prior-art/. Name OSS projects evaluated and rejected, libraries chosen vs. alternatives, patterns considered.]

## Architecture & implementation
[High-level architecture, key technology choices with rationale, what's working vs. stubbed vs. mocked.]

## Security posture
[Pull from reviews/security-*. Scope of review, findings by severity, what was addressed, what needs production hardening.]

## Independent cross-vendor review
[Pull from reviews/second-opinion-*. Reviewers used, convergent findings, divergent findings, net assessment.]

## What we'd do differently for production
[Gap analysis: hardening required, scale considerations, compliance work, estimated effort to productionize.]

## Recommended next steps
[3-5 concrete options ordered by user value, with rough effort estimates.]

## Appendix
- Full security review: .planning/reviews/security-*.md
- Full prior-art survey: .planning/prior-art/*.md
- Full cross-model review: .planning/reviews/second-opinion-*.md
- Implementation plan: .planning/plans/*.md
```

### 4. File the output

Write to `.planning/stakeholder-pack/v<N>-<date>.md`. Update `.planning/index.md`. Append to `.planning/log.md`.

### 5. Output to user

Confirm path. Note: for executive consumption, pipe through markdown-to-PDF or paste into Gamma.

## Anti-patterns

- **Defensive theater.** Tone should be "we considered X, chose Y because Z" — not apology.
- **Padding.** Don't include sections with no source material — note the gap.
- **Hiding gaps.** The production-gap section is critical. Naming gaps explicitly increases credibility.
SKILL_EOF

# 2.5 session-start
install_skill "session-start" <<'SKILL_EOF'
---
name: session-start
description: Session orientation ritual for iterative development. Run at the start of every working session before any coding, design, or planning begins. Reads wiki state, identifies current iteration and phase, confirms fidelity target, surfaces scope changes since last session, and outputs a clear orientation brief. Prevents silent defaulting to wrong assumptions about what we're building and how complete it should be.
model: sonnet
---

# session-start

## When to activate

Run at the start of every development session — before any coding, design, or planning work begins. Also run when returning to a project after a gap, or when a stakeholder has provided new feedback between sessions.

## Process

### 1. Check wiki exists

Look for `.planning/` in the project root.

- If absent: invoke `poc-wiki-init` now — do not stop, do not ask the user to run it separately. poc-wiki-init is idempotent and will ask the fidelity question and create the wiki structure. After it completes, continue with step 2.
- If present: proceed.

### 2. Read current state

Read these files in order:
1. `.planning/state/project-state.yml` — if it exists. Extract: phase (authoritative), mode, allowed_work, blocked_work, active_goal, active_constraints. This file overrides any phase inferred from conversation.
2. `.planning/index.md` — full file. Extract: current iteration, fidelity level, what's been completed.
3. `.planning/log.md` — last 15 entries. Extract: what happened last session, any open decisions or blockers.
4. `.planning/handoffs/` — most recent file if any. Extract: next steps, continuation prompt.

### 3. Detect engagement type

Check whether this is a greenfield project or an existing codebase:
- **Greenfield:** no source files beyond scaffolding, or `.planning/index.md` says "new project"
- **Existing repo:** source files present, git history exists, or `.planning/index.md` describes ongoing work

If this is the **first session on an existing repo** (wiki just created by poc-wiki-init, or `## Current State` shows iteration 1 / phase "Not started"), ask these scoping questions before orientation:

**Existing repo intake questions:**
1. "What's the goal for this engagement? (e.g. add a feature, fix bugs, refactor, security hardening, migrate, improve performance, other)"
2. "Are there constraints I should know about? (e.g. must not break X, specific tech stack, deadline, can't change the API)"
3. "What does 'done' look like — how will you know this engagement was successful?"
4. "Is there existing documentation, a spec, or prior decisions I should read first?"

Record answers in `.planning/index.md` under a `## Engagement Context` section. These answers shape how every phase runs — they are not optional.

Skip these questions if the wiki already has an `## Engagement Context` section with answers.

### 4. Build orientation summary

From what you read, construct:
- **Iteration:** N (or "1 / first session" if no prior sessions)
- **Engagement type:** greenfield or existing repo
- **Goal:** [from engagement context or "not set"]
- **Last phase completed:** [phase name or "none"]
- **Currently in phase:** [phase from project-state.yml — authoritative]
- **Mode:** [execution_style from project-state.yml, or "exploratory" if not set]
- **Fidelity target:** [working PoC / polished demo / MVP / not set]
- **Allowed work this session:** [allowed_work list from project-state.yml, or "not restricted" if file absent]
- **Blocked work:** [blocked_work list from project-state.yml if any entries exist]
- **Active constraints:** [active_constraints from project-state.yml or active-constraints.md]
- **Last session summary:** 1–2 sentences from log.md
- **Open items:** unresolved decisions or blockers from last session

### 5. Ask three questions

Present the orientation summary, then ask:

**Q1 — Scope or direction change?**
"Is there new feedback, stakeholder input, or scope change since last session?"

- If yes: ask them to describe it. Identify which phase the change requires re-entering:
  - Core problem changed → re-enter EXPAND
  - Approach or spec changed → re-enter PLAN
  - Feature scope changed mid-build → re-enter BUILD
  - UI direction changed → re-enter POLISH
- If no: continue to Q2.

**Q2 — Fidelity confirmation**

If a fidelity level is already recorded in the wiki:
"We're targeting [level]. Still correct?"

If no fidelity level is recorded:
"What level of functionality are we targeting this engagement?
  A) Working PoC — functional core logic, real integrations, key edge cases handled, something that can be built upon
  B) Polished demo — looks great and works on the happy path, mocked data acceptable
  C) MVP — production-ready enough to put in front of real users"

Record or confirm the answer in `.planning/index.md` under `## Current State`.

**Q3 — Session goal**
"What do we want to accomplish this session?"

Take their answer as the declared session goal. Record it in log.md.

### 6. Handle scope changes

If Q1 revealed a scope change:

1. Append to `.planning/log.md`:
   `## [timestamp] change | iteration N→N+1 | [one-line reason for change]`

2. Update `## Current State` in `index.md`:
   - Bump iteration number
   - Set current phase to the re-entry point identified in Q1

3. If the change affects the spec or plan:
   - Rename existing plan file to archive it (e.g., `plans/v1-spec.md` stays as-is — never delete)
   - Note that a new `plans/vN+1-spec.md` should be written when PLAN phase re-runs
   - Do not attempt to create the new plan file now — that belongs to `superpowers:writing-plans`

4. Tell the user: "Iteration bumped to N+1. Re-entering [phase]. Existing plan archived as v[N]."

### 7. Record session start in log and update state

Append to `.planning/log.md`:
`## [timestamp] session-start | iteration [N] | phase: [current phase] | goal: [session goal]`

If `.planning/state/project-state.yml` exists, update `current_state.last_updated` to the current timestamp and set `active_goal.title` to the session goal from Q3.

### 8. Output orientation brief and dispatch

Present a clean summary:

```
SESSION ORIENTATION
───────────────────────────────────────────
Iteration : [N]
Phase     : [current phase — from project-state.yml]
Mode      : [execution_style]
Fidelity  : [level]
Allowed   : [allowed_work summary or "unrestricted"]
Blocked   : [blocked_work summary or "none"]
Last session: [1-sentence summary or "first session"]
This session: [session goal]
[If scope changed]: Scope change recorded — re-entering [phase], prior plan archived as v[N].
[If wiki sections empty]: Wiki sections unpopulated — skills should file output to .planning/ as work progresses.
───────────────────────────────────────────
NOTE: If you lose context mid-session, re-read .planning/state/project-state.yml before continuing.
```

Then immediately dispatch to the correct skill based on current phase — do not wait for further instruction:

| Current phase | Dispatch to |
|---------------|------------|
| Not started / EXPAND | Invoke `/office-hours` |
| EXPAND (office-hours done, ceo-review pending) | Invoke `/plan-ceo-review` |
| REFINE | Invoke `superpowers:brainstorming` |
| SURVEY | Invoke `prior-art-survey` |
| PLAN | Invoke `superpowers:writing-plans` |
| BUILD | Invoke `superpowers:subagent-driven-development` |
| BUILD — UI work in progress | Invoke `/design-shotgun` or `/design-html` depending on whether directions are locked |
| POLISH — code review pending | Invoke `/qa` |
| POLISH — security pending | Invoke `/cso` |
| POLISH — design review pending | Invoke `/design-review` |
| DEFEND — cross-vendor review pending | Invoke `second-opinion` |
| DEFEND — stakeholder pack pending | Invoke `stakeholder-pack` |
| HANDOFF — docs pending | Invoke `/document-release` |
| HANDOFF — switching tools | Invoke `handoff-snapshot` |

If the current phase has multiple sub-steps (e.g., POLISH has qa + cso + design-review), check `index.md` and `log.md` to determine which have already run, then dispatch to the first pending one.

If the phase is ambiguous or the session goal implies re-entering a different phase than recorded, confirm with the user before dispatching.
SKILL_EOF

# ─── Phase 2.5: Prior-art research skills ─────────────────────────────────────

info "Phase 2.5 — Installing prior-art research skills…"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRIOR_ART_SKILLS=(prior-art-survey prior-art-oss-scout prior-art-library-scout prior-art-patterns-scout)

for skill in "${PRIOR_ART_SKILLS[@]}"; do
  src="${SCRIPT_DIR}/skills/${skill}"
  if [ ! -d "$src" ]; then
    halt "Expected skills/${skill}/ not found in repo. Clone may be incomplete."
  fi
  cp -r "$src" "${SKILLS_DIR}/"
  info "  Installed ${skill}"
done

# ─── Phase 3: CLAUDE.md configuration ────────────────────────────────────────

info "Phase 3 — Configuring project CLAUDE.md…"

CLAUDE_SECTION='
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

Run them in order. Do NOT use gstack'"'"'s /autoplan or /plan-eng-review — they overlap Superpowers'"'"' planning lane and create conflicts.

## Wiki

This project'"'"'s source of truth lives at `.planning/`. Read `.planning/state/project-state.yml` first (phase, allowed work, active constraints), then `.planning/index.md`. Check `.planning/handoffs/` for the most recent snapshot — another tool may have left state for you to resume from.

## Cross-tool

When usage limits hit, run `handoff-snapshot` and resume in Codex / Cursor / ChatGPT / Gemini. Each has its own schema file in `.planning/`.
'

PROJECT_CLAUDE="${PWD}/CLAUDE.md"
if [ -f "$PROJECT_CLAUDE" ]; then
  if grep -q "Stack ownership" "$PROJECT_CLAUDE"; then
    info "  CLAUDE.md already contains stack ownership section — skipping"
  else
    printf '\n# Project Context\n%s' "$CLAUDE_SECTION" >> "$PROJECT_CLAUDE"
    info "  Appended stack ownership section to existing CLAUDE.md"
  fi
else
  printf '# Project Context\n%s' "$CLAUDE_SECTION" > "$PROJECT_CLAUDE"
  info "  Created CLAUDE.md with stack ownership section"
fi

# ─── Phase 3.5: Global CLAUDE.md ──────────────────────────────────────────────

info "Phase 3.5 — Configuring global ~/.claude/CLAUDE.md…"

GLOBAL_CLAUDE="${HOME}/.claude/CLAUDE.md"
GLOBAL_CLAUDE_SECTION='
## Session authority: j-stack governs

j-stack is the single system governing all product development sessions. Superpowers skills
are available as subcomponents and are invoked by j-stack'"'"'s phase ordering below. Do NOT
let `superpowers:using-superpowers` drive session behavior — j-stack'"'"'s phase ordering
takes precedence per Superpowers'"'"' own instruction-priority rules.

---

## Session start ritual

At the beginning of every development session — before any coding, planning, or design work —
invoke the `session-start` skill. It reads wiki state, confirms the fidelity target, surfaces
scope changes, and declares the session goal. Skip it only for pure Q&A or one-off lookups
that produce no artifacts.

If the project has no `.planning/` wiki yet, run `poc-wiki-init` first.

---

## j-stack phase pipeline

For any product, PoC, or feature development work, follow this pipeline in order:

EXPAND → REFINE → SURVEY → PLAN → BUILD → POLISH → DEFEND → HANDOFF

| Phase | Skills to invoke |
|-------|-----------------|
| Expand | /office-hours, /plan-ceo-review |
| Refine | superpowers:brainstorming |
| Survey | prior-art-survey |
| Plan | superpowers:writing-plans |
| Build | superpowers:subagent-driven-development, /design-shotgun, /design-html |
| Polish | /qa, /design-review, /cso |
| Defend | second-opinion, stakeholder-pack |
| Handoff | /document-release, handoff-snapshot |

Do NOT use: /autoplan, /plan-eng-review — they conflict with superpowers:writing-plans.

---

## Model routing

| Moment | Model |
|--------|-------|
| Judgment (scoping, security, synthesis, stakeholder) | opus |
| Execution (implementation, audits, UI, code review) | sonnet |
| Housekeeping (templating, summarizing, wiki writes) | haiku |

---

## State machine authority

When `.planning/state/project-state.yml` exists in a project, it is the operational source of truth. Rules:

- Read it at session start — before any planning, coding, or design.
- The `phase` field is authoritative. Do not infer phase from conversation context alone.
- Respect `allowed_work` and `blocked_work`. If a request requires blocked work, surface the conflict and ask before proceeding.
- Do not silently change the phase. Log all transitions to `.planning/log.md` with a reason.
- After significant work, update `current_state.last_updated` in the file.
'

mkdir -p "${HOME}/.claude"
if [ -f "$GLOBAL_CLAUDE" ]; then
  if grep -q "j-stack governs" "$GLOBAL_CLAUDE"; then
    info "  Global CLAUDE.md already contains j-stack section — skipping"
  else
    printf '\n# Global Claude Code Configuration\n%s' "$GLOBAL_CLAUDE_SECTION" >> "$GLOBAL_CLAUDE"
    info "  Appended j-stack section to existing ~/.claude/CLAUDE.md"
  fi
else
  printf '# Global Claude Code Configuration\n%s' "$GLOBAL_CLAUDE_SECTION" > "$GLOBAL_CLAUDE"
  info "  Created ~/.claude/CLAUDE.md with j-stack configuration"
fi

# ─── Phase 4: Verification ────────────────────────────────────────────────────

if [ "$SKIP_VERIFY" = false ]; then
  info "Phase 4 — Verification…"

  all_ok=true

  # Check all skills exist
  ALL_SKILLS=("${GSTACK_SKILLS[@]}" poc-wiki-init handoff-snapshot second-opinion stakeholder-pack session-start "${PRIOR_ART_SKILLS[@]}")
  for skill in "${ALL_SKILLS[@]}"; do
    if [ -d "${SKILLS_DIR}/${skill}" ]; then
      info "  ✓ ${skill}"
    else
      error "  ✗ ${skill} — missing from ${SKILLS_DIR}"
      all_ok=false
    fi
  done

  # Check codex if not skipped
  if [ "$SKIP_CODEX" = false ]; then
    if command -v codex &>/dev/null; then
      info "  ✓ codex CLI"
    else
      warn "  ✗ codex CLI not found — second-opinion skill will not work until installed"
    fi
  fi

  if [ "$all_ok" = true ]; then
    info "All checks passed."
  else
    error "Some checks failed. See above."
    exit 1
  fi
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN} j-stack installation complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Next steps:"
echo "  1. Open a new Claude Code session in your project directory"
echo "  2. Run: session-start    (orient — or poc-wiki-init if first time on this project)"
echo "  3. Run: /office-hours    (founder-lens scoping)"
echo "  4. Follow the pipeline in ~/.claude/CLAUDE.md"
echo ""
echo "Each session: session-start → confirm fidelity → confirm phase → do work → handoff-snapshot (if switching tools)"
echo "Pipeline:     EXPAND → REFINE → SURVEY → PLAN → BUILD → POLISH → DEFEND → HANDOFF"
echo ""
