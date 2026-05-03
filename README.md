# j-stack

**[→ About j-stack (visual overview)](index.html)** · open `index.html` in a browser or enable GitHub Pages to serve it

A Claude Code stack optimized for enterprise PoC delivery.

**Three goals:**
1. Higher-fidelity demos in less time
2. Defensive deliverables that preempt "did you try X" objections
3. Cross-tool memory for resuming work in Codex / Cursor / ChatGPT when Anthropic usage limits hit

---

## Executive summary

### Why Superpowers changes everything

If you know Claude Code, you know the failure modes: agents that drift off-spec as context fills, implementations that "look right" but weren't test-driven, parallel subagents that clobber each other's work, half-finished features marked done. Good engineers solve these with process discipline. **[Superpowers](https://github.com/obra/superpowers)** is that discipline, encoded as skills.

Each skill is the answer to a known agentic coding anti-pattern:

| Skill | Anti-pattern it solves |
|-------|------------------------|
| `brainstorming` | Building the wrong thing perfectly. Forces structured pressure-testing of the product idea — *is this actually the right problem?* — before any engineering begins. |
| `writing-plans` | Spec drift. Locks a full implementation plan, reviewed by Opus, before a single line of code runs. Subagents implement against the spec, not against context that's 80k tokens deep. |
| `test-driven-development` | Code that looks right but isn't. Enforces red-green-refactor: tests are written first against the spec, implementation follows only when the test fails for the right reason. |
| `subagent-driven-development` | Sequential bottlenecks. Parallelizes implementation across multiple Claude instances, each with a bounded task from the spec. |
| `using-git-worktrees` | Parallel agents clobbering each other. Each subagent gets its own git worktree — isolated branch, clean working tree, no collisions. |
| `systematic-debugging` | Thrashing. Replaces "try random things until it works" with a structured hypothesis → reproduce → isolate → fix protocol. |
| `verification-before-completion` | Premature done. Claude verifies the task actually meets its acceptance criteria before marking it complete — not just "the code runs." |

Together these aren't features — they're **a baseline of agentic coding discipline** that most teams wing on every project. Superpowers makes them the default.

**[gstack](https://github.com/garrytan/gstack)** is a community skill pack with 40+ tools. j-stack doesn't install it wholesale — that would conflict with Superpowers' planning lane and add adoption tax. Instead, 11 skills are cherry-picked for the gaps Superpowers doesn't cover: frontend scoping, UI work, security, QA, docs, and safety guardrails.

**Expand phase — Opus (judgment)**

| Skill | What it does | Why this one |
|-------|-------------|--------------|
| `/office-hours` | YC-style office hours. Challenges your assumptions about what you're building — *is this the right problem?* — before any engineering begins. | Highest-judgment moment in the pipeline. Reframes "what to build" as "what problem to solve." Opus only. |
| `/plan-ceo-review` | CEO/founder-lens scope challenge. Asks: is this the right scope? What's the minimum viable version? What would a 10x founder cut? | Pairs with `/office-hours` to pressure-test both the problem and the proposed solution before REFINE begins. |

**Polish phase — Sonnet (execution)**

| Skill | What it does | Why this one |
|-------|-------------|--------------|
| `/qa` | Systematic audit against a rubric — runs known user flows, checks edge cases, produces a structured findings report. | Not a vibe check. An audit against the spec. Runs after BUILD, before DEFEND. |
| `/design-shotgun` | Generates multiple design directions rapidly to explore the space before committing. | Used at the start of UI work. Avoids converging on the first idea. Feeds `/design-html`. |
| `/design-html` | Takes a mockup or design direction and converts it to production-quality HTML/CSS. | The execution skill for UI work. Pairs with `/design-shotgun` — explore, then build. |
| `/design-review` | Audits the implemented UI against design principles: consistency, hierarchy, accessibility basics. | Closes the loop on UI work after `/design-html`. Catches regressions before the demo. |
| `/cso` | Chief Security Officer mode. OWASP Top 10 + STRIDE analysis with findings by severity. | Security exploit reasoning is high-judgment work — Opus. Runs before DEFEND so the stakeholder pack has a real security section. |
| `/codex` | Orchestrates a shell-out to OpenAI Codex CLI. | Used internally by the `second-opinion` custom skill for cross-vendor review. Not invoked directly. |
| `/document-release` | Reads the diff and updates docs to match. | No manual documentation sprint at the end. Docs are a diff operation, not a writing assignment. |

**Safety — Haiku (mechanical)**

| Skill | What it does | Why this one |
|-------|-------------|--------------|
| `/freeze` | Locks specific files from editing. | Protects finalized artifacts (specs, stakeholder docs) from being modified mid-session. |
| `/guard` | Combines `/freeze` with careful mode. | Adds a second layer when you need Claude to treat certain files as read-only under any circumstances. |

**What was skipped and why:** gstack's `/autoplan` and `/plan-eng-review` overlap Superpowers' planning lane — two planners create conflicts. `/ship`, `/canary`, `/investigate`, and `/land-and-deploy` are prod-shipping tools; PoC mission doesn't need them. `/retro`, `/pair-agent`, and `gbrain` solve problems outside the PoC scope entirely.

### Prior-art research — a net new addition

Neither Superpowers nor gstack ships a prior-art research agent. This is an original addition to the stack, and it fills a real gap: AI agents are enthusiastic reinventors of wheels.

`prior-art-survey` dispatches **three parallel scouts** before any implementation begins:

| Scout | What it searches | Why it matters |
|-------|-----------------|----------------|
| OSS scout | GitHub, package registries, known open-source projects | Finds existing solutions you could adopt or adapt instead of building |
| Library scout | Language-specific ecosystems (npm, PyPI, etc.) | Finds packages that solve the problem — or 80% of it |
| Patterns scout | Established architectural and design patterns | Ensures the approach fits recognized patterns, not just intuition |

The output isn't just research — it becomes the "what else did you consider" section of the stakeholder pack, and it's the primary defense against the classic enterprise objection: *"did you look at X before building this?"*

### Token optimization and the second brain

Anthropic is tightening usage limits, and burning Opus credits on mechanical work is a real cost. j-stack addresses this at two levels.

**Model routing by cognitive demand** is the first defense. Every skill has an explicit model directive:

- **Opus** — judgment calls only: scoping, security reasoning, cross-model synthesis, stakeholder framing
- **Sonnet** — execution work: implementation, audits, UI conversion, code review
- **Haiku** — mechanical operations: templating, summarizing, file locking

The result: a full pipeline run spends Opus tokens where they move the needle and Haiku tokens on everything else.

**The `.planning/` wiki is the second defense** — and the emergency bailout. This is the same concept Andrej Karpathy describes with his Obsidian second brain: a persistent, structured external memory that outlives any single session or tool. Every decision, artifact, and handoff is written to markdown files in `.planning/`. The wiki is readable by every major AI tool through its own schema file:

| File | Read by |
|------|---------|
| `.planning/CLAUDE.md` | Claude Code |
| `.planning/AGENTS.md` | Codex CLI |
| `.planning/.cursor/rules` | Cursor |
| `.planning/chatgpt-brief.md` | ChatGPT (paste-in) |

When Anthropic limits hit mid-engagement — and they will — running `handoff-snapshot` writes a continuation prompt to `.planning/handoffs/`. Paste it into Codex, Cursor, or ChatGPT and the session resumes from exactly where it stopped. No context lost, no re-explanation, no starting over.

### What j-stack assembles

- **Superpowers** — agentic coding discipline (planning, TDD, worktrees, verification)
- **11 cherry-picked gstack skills** — frontend scoping, UI work, security, QA, docs, safety rails
- **prior-art-survey** — three parallel research scouts before any build begins
- **4 custom skills** — wiki bootstrapping, cross-tool handoff, cross-vendor review, stakeholder defense pack
- **Model routing** — explicit Opus/Sonnet/Haiku directives on every skill
- **`.planning/` second brain** — persistent cross-tool memory with emergency bailout

### Spec-driven development and TDD by default

The pipeline enforces a plan-before-build discipline. Nothing in BUILD starts until PLAN is locked:

```
EXPAND  → reframe the problem through a founder/10x lens
REFINE  → pressure-test the approach with structured brainstorming
SURVEY  → parallel prior-art research (OSS, libraries, architectural patterns)
PLAN    → full implementation spec reviewed by Opus before any code runs
BUILD   → TDD execution: tests first against the spec, then implementation
POLISH  → QA, design audit, and OWASP security review against the spec
DEFEND  → Codex CLI independently reviews Claude's work; findings synthesized
HANDOFF → docs generated from diff; cross-tool snapshot written
```

The `superpowers:test-driven-development` skill enforces red-green-refactor during BUILD. Subagents implement against the spec, not a vague prompt. The DEFEND phase runs Claude's output through OpenAI Codex independently — convergent findings from two vendors are the strongest signal an enterprise stakeholder can get.

### The five questions j-stack pre-answers

Enterprise stakeholders ask the same questions every time. j-stack produces artifacts that answer them before the meeting:

| Question | Artifact |
|----------|----------|
| Why did you build it this way? | Vision doc from `/office-hours` + `brainstorm` |
| What else did you consider? | `prior-art-survey` output (OSS, libraries, patterns) |
| Is it secure? | `/cso` OWASP/STRIDE security review |
| Does it actually work? | `/qa` audit against spec + TDD test suite |
| Why should I trust one AI vendor? | `second-opinion` cross-vendor convergence matrix |

All five are assembled into a single document by `stakeholder-pack` before the demo.

---

## SDLC coverage — the discovery-to-demo arc

j-stack covers the **discovery → demo arc** of the software development lifecycle. Every phase from problem definition through stakeholder handoff is explicitly handled by a skill. What's deliberately out of scope is the production-ops side — deployment, monitoring, incident response — because PoC mission ≠ production mission.

| SDLC Phase | j-stack Stage | Engineering PM Principle |
|---|---|---|
| Product Discovery | EXPAND | *Are we solving the right problem?* Founder/10x reframe before any engineering begins. |
| Requirements & Ideation | REFINE | Structured pressure-testing before committing to an approach. |
| Feasibility / Build-vs-Buy | SURVEY | Named, reasoned alternatives across OSS, libraries, and patterns. Every "did you try X" answered before the meeting. |
| Technical Design | PLAN | Spec locked before implementation begins. Explicit gate — nothing builds until this is done. |
| Development | BUILD | TDD (red-green-refactor enforced), parallel subagents, spec-bound execution. |
| QA & Security | POLISH | Definition of done against spec. OWASP/STRIDE risk management as a deliverable, not a checkbox. |
| Stakeholder Review | DEFEND | Pre-answered objections, cross-vendor AI validation. Meeting shifts from "defend the work" to "what's next." |
| Documentation & Handoff | HANDOFF | Docs generated from diff, not written afterward. Knowledge transfer built in. |

**Out of scope by design** (PoC mission ≠ production):

| SDLC Phase | Why excluded |
|---|---|
| Deployment / Release ops | Prod-shipping discipline; out of PoC scope |
| Monitoring / Observability | Post-launch ops |
| Incident response / Maintenance | Beyond the demo arc |

### Engineering PM principles baked in

- **Discovery before engineering** — EXPAND and REFINE exist before a line of spec is written. `/office-hours` specifically asks "are you solving the right problem?"
- **Build vs. buy at every dependency** — `prior-art-survey` runs three parallel scouts (OSS, libraries, patterns) and produces a named, reasoned landscape — not a gut call
- **Explicit phase gates** — each stage must complete before the next begins; nothing in BUILD runs without a locked PLAN output
- **Risk management as a deliverable** — `/cso` files an OWASP/STRIDE finding set; `second-opinion` adds a cross-vendor risk matrix; both are artifacts, not notes in a chat window
- **Documentation built in, not bolted on** — `/document-release` generates docs from the diff; `handoff-snapshot` captures session state; there is no "go document what you built" sprint at the end
- **Parallel workstreams** — `subagent-driven-development` and `prior-art-survey`'s three parallel scouts mirror how a PM schedules concurrent engineering tracks
- **Stakeholder communication** — `stakeholder-pack` pre-answers the five standard enterprise questions and turns the demo from a defense into a discussion about next steps

---

## What's in the stack

| Layer | Tools | Phase |
|-------|-------|-------|
| **Superpowers** | brainstorming, writing-plans, subagent-driven-development | Core framework |
| **gstack skills** (cherry-picked) | /office-hours, /plan-ceo-review, /qa, /design-shotgun, /design-html, /design-review, /cso, /codex, /document-release, /freeze, /guard | Scoping, polish, handoff |
| **Custom skills** | poc-wiki-init, handoff-snapshot, second-opinion, stakeholder-pack | Wiki, cross-tool, defense |
| **prior-art-survey** | Parallel OSS/library/patterns scouts | Survey (delivered separately) |

---

## Prerequisites

- [Claude Code](https://claude.ai/code) installed (`which claude`)
- [Superpowers plugin](https://github.com/obra/superpowers) installed in Claude Code
- `prior-art-survey` skill (delivered separately — ask if you don't have it)
- [OpenAI Codex CLI](https://github.com/openai/codex) installed and authenticated (for `second-opinion`)
- git, bash, standard Unix tools

---

## Installation

```bash
git clone https://github.com/jpagano-r7/j-stack.git
cd j-stack
bash install.sh
```

**Options:**

```bash
bash install.sh --skip-codex    # skip Codex CLI check (if not using second-opinion)
bash install.sh --skip-verify   # skip post-install verification
```

The script:
1. Checks prerequisites
2. Clones [gstack](https://github.com/garrytan/gstack) and copies 11 skills into `~/.claude/skills/`, injecting model directives
3. Installs 4 custom skills into `~/.claude/skills/`
4. Configures `CLAUDE.md` with skill lane ownership

---

## Workflow pipeline

```
EXPAND → REFINE → SURVEY → PLAN → BUILD → POLISH → DEFEND → HANDOFF
```

| Phase | Skill | Purpose |
|-------|-------|---------|
| Expand | `/office-hours`, `/plan-ceo-review` | Founder-lens reframe, scope challenge |
| Refine | `brainstorm` (Superpowers) | Idea pressure-testing |
| Survey | `prior-art-survey` | Parallel OSS/library/patterns research |
| Plan | `writing-plans` (Superpowers) | Implementation plan |
| Build | `subagent-driven-development`, `/design-shotgun`, `/design-html` | Execution |
| Polish | `/qa`, `/design-review`, `/cso` | Audit, design QA, security review |
| Defend | `second-opinion`, `stakeholder-pack` | Cross-vendor review, stakeholder doc |
| Handoff | `/document-release`, `handoff-snapshot` | Docs, cross-tool resumption |

---

## Model routing

Skills are assigned models based on cognitive demand:

- **Opus** — judgment moments: scoping, security reasoning, cross-model synthesis, stakeholder framing
- **Sonnet** — execution moments: implementation, audits, conversions
- **Haiku** — housekeeping: templating, summarizing, mechanical operations

---

## Cross-tool memory

Each PoC project runs `poc-wiki-init` once to create a `.planning/` wiki directory. The wiki contains schema files for every major AI tool:

| File | Consumed by |
|------|-------------|
| `.planning/CLAUDE.md` | Claude Code |
| `.planning/AGENTS.md` | Codex CLI |
| `.planning/.cursor/rules` | Cursor |
| `.planning/chatgpt-brief.md` | ChatGPT (paste-in) |

When Anthropic usage limits hit mid-engagement, run `handoff-snapshot` to write a continuation prompt, then paste it into the next tool.

---

## Custom skills

### `poc-wiki-init`
Bootstraps `.planning/` wiki structure at project start. Idempotent — safe to run again.

### `handoff-snapshot`
Writes a timestamped snapshot to `.planning/handoffs/` with context, decisions, next steps, and a paste-ready continuation prompt.

### `second-opinion`
Dispatches an artifact to Codex CLI for independent review, then synthesizes a convergence/divergence matrix. Output filed to `.planning/reviews/`.

### `stakeholder-pack`
Aggregates vision, prior-art, security, and cross-model review outputs into a single executive-ready document. Pre-answers the five standard enterprise PoC questions.

---

## What's NOT installed

These were considered and explicitly rejected:

| Skipped | Reason |
|---------|--------|
| Full gstack install | Conflicts with Superpowers, adoption tax |
| gstack /autoplan, /plan-eng-review | Overlap Superpowers' planning lane |
| gstack /investigate, /ship, /canary | Prod-shipping discipline; out of PoC scope |
| LiteLLM gateway | Proxy complexity not worth it for one OpenAI shell-out |
| MCP-based memory | ~6K token tax per session; markdown wiki achieves the same goal |

---

## Starting a new PoC

```
1. Open Claude Code in your project directory
2. /poc-wiki-init          ← bootstrap .planning/ wiki
3. /office-hours           ← founder-lens reframe
4. /superpowers:brainstorm ← pressure-test the vision
5. prior-art-survey        ← parallel prior-art research
6. writing-plans           ← implementation plan
7. ... build, polish, defend, handoff
```
