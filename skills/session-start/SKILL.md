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
1. `.planning/index.md` — full file. Extract: current iteration, current phase, fidelity level, what's been completed, and the `Prior-art:` flag from the `## Current State` block (`✅ complete` or `⬜ pending`).
2. `.planning/log.md` — last 15 entries. Extract: what happened last session, any open decisions or blockers, and which phase-step skills have run since the last iteration bump.
3. `.planning/handoffs/` — most recent file if any. Extract: next steps, continuation prompt.
4. Artifact scan — list `.planning/prior-art/`, `.planning/plans/`, `.planning/reviews/`, `.planning/stakeholder-pack/`. The presence (or absence) of artifacts in these folders tells you which phase steps have already run. You will turn this into a phase-progress checklist in step 8.
5. Graphify check — look for `graphify-out/GRAPH_REPORT.md` in the project root. If present, the project has a knowledge graph; note this for the orientation brief. Not required — graphify is an on-demand tool for large or unfamiliar codebases.

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

If the codebase is large or unfamiliar, suggest running `/graphify .` before SURVEY or PLAN — it builds a structural knowledge graph subagents can query instead of reading files individually (71× fewer tokens on large corpora). File the resulting `graphify-out/GRAPH_REPORT.md` to `.planning/vision/` so it becomes part of the wiki.

Record answers in `.planning/index.md` under a `## Engagement Context` section. These answers shape how every phase runs — they are not optional.

Skip these questions if the wiki already has an `## Engagement Context` section with answers.

### 4. Build orientation summary

From what you read, construct:
- **Iteration:** N (or "1 / first session" if no prior sessions)
- **Engagement type:** greenfield or existing repo
- **Goal:** [from engagement context or "not set"]
- **Last phase completed:** [phase name or "none"]
- **Currently in phase:** [phase name or "starting fresh"]
- **Fidelity target:** [working PoC / polished demo / MVP / not set]
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
   - Reset every `## Iteration Progress` line to ⬜ — **except** the SURVEY / prior-art line. Prior-art runs once per project lifecycle (see prior-art-survey), so the `Prior-art:` flag and its checklist line stay ✅ once set; a new iteration does not require re-surveying.

3. If the change affects the spec or plan:
   - Rename existing plan file to archive it (e.g., `plans/v1-spec.md` stays as-is — never delete)
   - Note that a new `plans/vN+1-spec.md` should be written when PLAN phase re-runs
   - Do not attempt to create the new plan file now — that belongs to `superpowers:writing-plans`

4. Tell the user: "Iteration bumped to N+1. Re-entering [phase]. Existing plan archived as v[N]."

### 7. Record session start in log

Append to `.planning/log.md`:
`## [timestamp] session-start | iteration [N] | phase: [current phase] | goal: [session goal]`

### 8. Compute phase progress, output orientation brief, and dispatch

**8a. Reconcile the `## Iteration Progress` checklist in `index.md`.** That checklist is the record of which phase steps have run this iteration. Bring it up to date before dispatching:

- **`[auto]` steps** — confirm from the wiki artifact named in the checklist. These signals are reliable because the skill files a distinguishable artifact:
  - `office-hours` → `vision/` has a design doc
  - `prior-art-survey` → the `Prior-art:` flag in Current State (**authoritative**)
  - `writing-plans` → `plans/` has a plan for this iteration
  - `subagent-driven-development` → source commits since the plan
  - `second-opinion` → `reviews/second-opinion-*`
  - `qa` → `reviews/qa-*`
  - `design-review` → `reviews/design-*`
  - `cso` → `reviews/security-*`
  - `stakeholder-pack` → `stakeholder-pack/` non-empty
  - `handoff-snapshot` → `handoffs/` has a recent snapshot
  - If the artifact exists, set the line ✅; otherwise leave it ⬜.
  - (`/qa`, `/cso`, `/design-review` only file these reports because the governance CLAUDE.md instructs it after they run — so the artifact is the confirmation.)
- **`[confirm]` steps** (`plan-ceo-review`, `brainstorming`, `document-release`) — these leave no reliable, distinguishable wiki trace. If the checklist still shows ⬜ for one and the current phase implies it should have run, **ask the user**: "Has `/plan-ceo-review` run this iteration? I can't confirm it from the wiki." Record their answer by ticking the line, so it persists and you don't ask again.

Scope to the **current iteration**: an artifact or tick from a prior iteration does not satisfy a step now. When `[auto]` evidence is genuinely ambiguous, treat the step as ⬜ and surface it — a silently skipped step is the exact failure this catches.

Write the reconciled checklist back to `index.md`.

**8b. Output the orientation brief**, including a phase-progress checklist for the current phase:

```
SESSION ORIENTATION
───────────────────────────────────────────
Iteration : [N]
Phase     : [current phase]
Fidelity  : [level]
Prior-art : [✅ complete / ⬜ pending]
Graph     : ✅ graphify-out/ present — query with /graphify or `graphify query "..."`
            ← omit this line entirely when graphify-out/ is absent
Last session: [1-sentence summary or "first session"]
This session: [session goal]
[If scope changed]: Scope change recorded — re-entering [phase], prior plan archived as v[N].

[Current phase] progress (iteration [N]):
  ✅ [step that has run]
  ⬜ [step pending]   ← next
[If an earlier step in this phase was skipped]: ⚠ [step] never ran this iteration — recommend running it.
───────────────────────────────────────────
```

**8c. Dispatch the first pending (⬜) step of the current phase** — do not wait for further instruction:

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

**Prior-art gate.** If the current phase is PLAN (or you are about to dispatch `superpowers:writing-plans`) and `Prior-art:` is `⬜ pending`, do NOT dispatch writing-plans. Dispatch `prior-art-survey` first and tell the user: "Prior-art hasn't run this project — running SURVEY before PLAN." This mirrors the gate in the governance CLAUDE.md.

**Multi-step phases (POLISH, DEFEND, HANDOFF).** Dispatch the first ⬜ step from the 8a checklist. Always surface skipped steps explicitly even if the recorded phase has moved on — e.g. "Heads up: we're in POLISH but `/cso` has never run this iteration. Run it before DEFEND?" A later phase being recorded does not mean every step of the current one completed.

If the user's session goal names a specific step ("run the security review"), honor that over the default first-pending dispatch.

If the phase is ambiguous or the session goal implies re-entering a different phase than recorded, confirm with the user before dispatching.
