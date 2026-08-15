# Prior art — coleam00/skills

**Source:** https://github.com/coleam00/skills (MIT, Cole Medin, "Cole's AI Skills" — the AI Layer from the Dynamous Agentic Coding course)
**Surveyed:** 2026-08-15
**Scope:** single-source comparison against j-stack. **This is not a completed `prior-art-survey` run** — no library/OSS/patterns scout fan-out, one repo only. The `Prior-art:` gate flag in `index.md` stays `⬜ pending`.
**Decision type:** selective adopt (4 adopt, 2 adopt-as-mechanism, 1 structural decision to make, rest rejected)

---

## What it is

33 skills in `.claude/skills/`, shipped as a Claude Code plugin marketplace (`.claude-plugin/marketplace.json`)
and installable via `npx skills add`. Built around one loop run per ticket:

**prime → plan → implement → validate → review → commit → PR** (the "PIV loop")

Around it: intent-side skills (PRD, architecture, epic slicing), parallel-work skills (worktrees), and a set of
**meta-skills for building your own AI layer** (rules, hooks, skills, ablation, opportunity scans, retros).

## Shape comparison

| | j-stack | coleam00/skills |
|---|---|---|
| Organizing spine | 8-phase engagement pipeline (EXPAND→…→HANDOFF) | one per-ticket dev loop (PIV) |
| Unit of work | an engagement / PoC | a ticket |
| Source of truth | `.planning/` wiki, cross-session | the codebase + per-run artifacts |
| Composition | curates 3 packs (Superpowers + 11 gstack cherry-picks + 6 custom) | one self-contained pack |
| Distribution | 419-line `install.sh` writing into `~/.claude/` | plugin marketplace + `npx skills add` |
| Human gates | heavy (office-hours, ceo-review, stakeholder-pack) | light (review + PR) |
| Meta-layer | none — j-stack improves itself by hand-run audits | 8 skills dedicated to it |

**The headline:** the two repos barely compete on the build loop, and barely overlap at all on the meta-layer.
j-stack's PLAN/BUILD/POLISH lanes are already assigned and the PIV loop would collide with them. But Cole has a
whole category j-stack does not have — **skills whose job is to keep the AI layer itself honest** — and that
category maps almost one-to-one onto j-stack's open audit backlog.

---

## ADOPT

### 1. `second-brain-audit` — the doctrine, not the script → closes **N7**

**Highest-value item in the repo for us.**

The core idea: every stored fact is either **state** (one current value, *changes*, must be **replaced**) or
**event** (a timestamped thing that *happened*, must be **appended**). The update rules are opposites. Append a
state and you get two answers to one question with nothing marking which is current — and the stale copy usually
sits higher in the file, so it gets read first. The skill's key claim is that **structure carries this rule, not
an instruction**: asking a model to remember to update the old entry fails quietly and constantly.

That is a precise description of finding **C13**, which this repo has confirmed against itself and has *still not
fully fixed*. `index.md` is state. `log.md` is event. j-stack got the two-file split right by instinct and then
drifted anyway, because nothing ever named the rule or checked it. Right now `index.md` still reports
`Prior-art: ⬜ pending` while `plans/2026-06-17-ponytail-fixes.md` exists — a plan that ran without its survey,
which is exactly the drift the gate was built to catch.

Its **Phase 2** procedure is the reusable part and needs no tooling: read the always-loaded surface completely,
extract every state-shaped claim, hunt the freshest evidence for each, and sort into **confirmed /
contradicted / unsupported** — treating "unsupported" as a finding in its own right, not a pass.

- **Adopt:** the state-vs-event doctrine into `.planning/CLAUDE.md`, and Phase 2 as the body of the N7 doctor.
- **Skip:** `scripts/audit.py` (400 lines). It compares monetary values across notes — near-useless on a wiki
  with no money in it, which the skill itself admits via its COVERAGE WARNING. Write `tests/wiki-doctor.sh`
  instead: Prior-art flag vs `prior-art/` contents, Iteration Progress ticks vs `reviews/` files, index
  `Last updated` vs `log.md` tail, handoff pointer vs newest file in `handoffs/`.
- **Worth stealing verbatim:** *"the count has to be the same twice — a model asked to tally 600 bullets returns
  a confident number and a different one tomorrow. The script counts. The agent judges."* That is the argument
  for why N7 is a script and not a prompt.

### 2. `system-execution-report` + `system-evolution-review` — a better answer to **N6**

N6 (bundle `recall-learnings` / `graduate-learnings`) has been open since 2026-07-10 and is awkward: those skills
don't exist as files anywhere in the repo (C1), and D1 attaches a hard privacy constraint — never ship the
developer's Obsidian vault content, fresh installs must init empty.

This pair does the same job — capture what was learned, feed it back into the system — with **no vault, no
Obsidian, no personal data to leak**. D1's constraint is satisfied by construction.

- `system-execution-report` runs right after an implementation: files touched, validation results, what went
  well, **divergences from plan** (each with planned/actual/reason/type), skipped items, recommendations.
- `system-evolution-review` consumes the plan + that report and reviews **the process, not the code**. It
  classifies each divergence good ✅ / bad ❌, traces root causes (unclear plan? missing context? missing
  validation? repeated manual step?), and emits concrete asset updates — *"update CLAUDE.md", "add this step to
  the plan skill", "this manual process repeated 3+ times, make it a skill"*.

Its framing is the useful bit: **good divergence reveals plan limitations → improve planning; bad divergence
reveals unclear requirements → improve communication; repeated issues reveal missing automation → create skills.**

**Fit:** slots into j-stack between BUILD and POLISH, or as a HANDOFF-adjacent step. Retarget its output paths
from `.claude/execution-reports/` and `.claude/system-reviews/` to `.planning/reviews/` so the existing POLISH
report-filing convention and `session-start` auto-detection pick it up for free.

**Recommendation:** adopt this pair *instead of* bundling the Obsidian learnings skills, and close N6 that way.
Needs a user decision — see Open questions.

### 3. `rules-check-drift` — small, closes the detection half of **C2/C14**

Checks whether `CLAUDE.md` / `AGENTS.md` is still *true* after a change set. Flags exactly three things and
nothing else: a stated rule that is now false, a drifted "where things live" map entry, and a genuinely new
durable invariant (as **one line**). Explicitly refuses to record that a feature was added, restate what the code
makes obvious, or add rationale prose.

j-stack fixed the **supply** side of doctrine drift with `templates/lane-doctrine.md` single-sourcing (N5, done).
It has no **detection** side. This is ~60 lines, one file, zero dependencies, and its governing line —
*"wrong rules are worse than missing rules; a longer rules file is worse than a lean one"* — is j-stack's own
stated constraint said better than j-stack says it.

**Fit:** POLISH lane, or fold into the wiki-doctor from item 1 so one command checks both the wiki and the rules
files.

### 4. `hooks-create` — and the harder idea behind it

j-stack ships exactly one hook: the SessionStart hook that `install.sh` hand-writes into `~/.claude/settings.json`
via an inline python3 merge (install.sh:273-328). It works, but it is bespoke and there is no path to a second
hook.

`hooks-create` supplies the reusable part: a lifecycle-event selection table (PreToolUse / PostToolUse / Stop /
UserPromptSubmit / SessionStart / Notification / PreCompact) keyed on *when it fires* and *whether it can block*,
plus the settings-wiring procedure. Its distinction is the one that matters here:

> **a rule *asks* the agent to behave; a hook *guarantees* it, at the tooling layer the model can't talk its way around.**

**The consequence for j-stack is bigger than the skill.** The prior-art gate — the thing `.planning/CLAUDE.md`
calls out in bold as the reason SURVEY exists — is currently a paragraph of prose. This repo violated it (C13),
which is a live demonstration that a prose gate is not a gate. A blocking hook that refuses `writing-plans` while
`Prior-art: ⬜ pending` would make it real. Same for the work-checkpoint discipline.

---

## ADOPT AS MECHANISM (not as a pipeline step)

### 5. `ablate-ai-layer` — evidence for the leanness constraint

Runs the *same real task* many times in throwaway detached git worktrees, once with the AI layer intact and once
with the always-loaded set stripped, then grades every rule against what actually changed. Never touches the
working tree. Its premise: **model upgrades quietly retire instructions** — a rule written around a weaker model
becomes dead weight competing for attention with rules that still matter, and reading the file will not tell you
which is which.

j-stack's standing constraint is "keep it lean" (`index.md` → Constraints), enforced entirely by taste across a
401-line README, a 419-line installer, and doctrine in four files. There is no evidence base. This is the method
that would produce one.

Also worth internalizing even if the script is never run: **only the always-loaded set is worth stripping.**
Skills, subagents and path-scoped rules cost nothing until they fire, so deleting them buys back no context —
which is a sharper version of the argument j-stack's own README makes about token optimization.

**Cost:** 324-line runner, real token spend per run, needs a user-chosen probe task. Occasional audit, not a
pipeline step.

### 6. `worktree-create` / `worktree-merge` — a lane j-stack simply doesn't have

Fan out N git worktrees (each on its own branch, gitignored config copied in, deps installed, health-checked, via
one setup subagent per worktree), then integrate them back through a single safe integration branch with
validation after each merge. j-stack's BUILD is single-threaded through Superpowers subagent-driven-development.
No lane conflict, purely additive. Low priority but free.

---

## REJECT

| What | Why |
|---|---|
| The whole **PIV loop** (`piv-plan-implementation`, `piv-implement`, `piv-validate`, `piv-review-changes`, `piv-fix-review-findings`, `piv-commit`, `piv-create-pr`, `piv-review-pr`, `piv-run-full-loop`) | Direct lane collision. This is Cole's PLAN/BUILD/POLISH, already owned by Superpowers writing-plans + subagent-driven-development + gstack `/qa` `/cso` `/design-review`. Adopting it recreates precisely the conflict the stack-ownership rule bans `/autoplan` and `/plan-eng-review` for. |
| `plan-create-prd`, `plan-architecture`, `plan-create-stories`, `piv-slice-epic` | Overlap `/office-hours`, `/plan-ceo-review`, and Superpowers brainstorming (EXPAND/REFINE). Same conflict, earlier in the pipeline. |
| `prime-codebase` / `prime-backend` / `prime-frontend` | Overlap `session-start` (wiki-first orientation) and graphify (structural, 71× cheaper on large corpora). The frontend/backend *scoping* idea is mildly interesting for existing-repo engagements; not worth the lane risk. |
| `piv-investigate-issue` / `piv-implement-issue` | Issue-driven RCA loop. j-stack is engagement-driven, not ticket-driven. Revisit only if j-stack starts taking maintenance engagements. |
| `build-dark-factory` | 806-line SKILL.md + ~7,000 lines of templates for a fully autonomous self-shipping repo. Architecturally opposed to j-stack's human-gated model (office-hours, ceo-review, stakeholder-pack are the *product*). Interesting long-term; wrong now. |
| `skills-create` | Environment already provides `skill-creator`. |
| `agent-browser`, `ast-grep` | Generic tooling, no pipeline relevance. `ast-grep` could pair with graphify someday. |
| `setup-ai-tutor` | Sample-project specific; the author says so. |
| `rules-create-global` | j-stack *generates* its CLAUDE.md/AGENTS.md from `templates/lane-doctrine.md` — already solved, better, for our case. |
| `opportunity-scan` | Borderline. Maps to N17 (instrumentation) and its reactive/proactive split is a good frame, but j-stack's equivalent is the hand-run self-audit that produced the 2026-07-10 snapshot. Defer; revisit with N17. |

---

## Structural lessons (not skills)

1. **Distribution: plugin marketplace vs. `install.sh`.** Cole ships `.claude-plugin/marketplace.json` and users
   run `/plugin marketplace add coleam00/skills`. That buys managed read-only skills, namespaced invocation
   (`/skills:piv-implement`), `/plugin marketplace update`, and one-toggle disable. j-stack's 419-line installer
   does more than a plugin can (gstack cherry-picks with model injection, agents, the SessionStart hook,
   CLAUDE.md/AGENTS.md section management, `--codex-only`) — so it cannot go fully plugin. But the **six custom
   skills** could ship as a plugin while the installer keeps the rest. Worth a real decision; would meaningfully
   shrink the thing j-stack has to maintain by hand.

2. **Publish the always-on context cost.** Cole states a number: ~4,200 tokens for 33 descriptions, with
   `claude plugin details skills` for the per-skill breakdown. j-stack's README argues token optimization at
   three levels and publishes no equivalent figure. Cheap to compute, concrete, and it is the claim most likely
   to be challenged.

3. **`references/` split as house style.** SKILL.md stays lean; detail moves to `references/`, loaded only when
   needed (`ast-grep`, `skills-create`, `ablate-ai-layer`, `build-dark-factory` all do this). j-stack's
   `session-start` is 189 lines in one file; `poc-wiki-init` already uses co-located `templates/`. Low priority,
   but the convention is right.

4. **The meta-layer is a category, not a skill.** Eight of Cole's 33 skills exist to keep the AI layer honest.
   j-stack has zero and does this work by hand, episodically, which is why the 2026-07-10 audit found 16
   confirmed defects in its own configuration. Items 1-5 above are all one bet: **give j-stack a meta-lane.**

---

## Proposed backlog delta

| Action | Effect |
|---|---|
| **N7** — build `tests/wiki-doctor.sh` on `second-brain-audit` Phase 2 + state/event doctrine | unblocks; was blocked on N4 (now done) |
| **N6** — replace "bundle Obsidian learnings skills" with "adopt `system-execution-report` + `system-evolution-review`, retargeted to `.planning/reviews/`" | needs user sign-off; would close a 5-week-old blocked item and drop D1's privacy constraint entirely |
| **N19** *(new)* — adopt `rules-check-drift` into POLISH (or fold into the doctor) | closes detection half of C2/C14 |
| **N20** *(new)* — make the prior-art gate a blocking hook, not prose (`hooks-create` as the how) | the gate this repo demonstrably violated |
| **N21** *(new)* — decide: ship the 6 custom skills as a plugin marketplace alongside `install.sh`? | maintenance reduction |
| **N22** *(new)* — publish j-stack's always-on context cost in the README | credibility |
| **N23** *(new)* — adopt `worktree-create` / `worktree-merge` for parallel BUILD | additive, no conflict |
| **N24** *(new, low)* — run `ablate-ai-layer` once against j-stack's own always-loaded set | evidence for the leanness constraint |
| **N17** — keep deferred; revisit alongside `opportunity-scan` | unchanged |

## Open questions

- **Q3:** Does N6 become "adopt the execution-report/evolution-review pair" (dropping the Obsidian learnings
  bundle and D1's constraint with it), or do both ship? — *owner: user*
- **Q4:** Plugin marketplace for the custom skills (N21) — yes, no, or later? — *owner: user*

## Licensing

MIT, attribution required. Any adopted file must retain a provenance line pointing at
`https://github.com/coleam00/skills` and the MIT license. Prefer **rewriting to j-stack's conventions with
attribution** over copying verbatim — every candidate above needs retargeting to `.planning/` anyway.
