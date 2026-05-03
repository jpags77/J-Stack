# j-stack

**[→ About j-stack (visual overview)](index.html)** · open `index.html` in a browser or enable GitHub Pages to serve it

A Claude Code stack optimized for enterprise PoC delivery.

**Three goals:**
1. Higher-fidelity demos in less time
2. Defensive deliverables that preempt "did you try X" objections
3. Cross-tool memory for resuming work in Codex / Cursor / ChatGPT when Anthropic usage limits hit

---

## Executive summary — start here if you're new

### The building blocks

**[Claude Code](https://claude.ai/code)** is Anthropic's AI coding CLI. It's not autocomplete — it's an autonomous agent that reasons about architecture, writes and edits files, runs tests, browses documentation, and dispatches subagents. Think of it as a senior engineer who lives in your terminal.

**[Superpowers](https://github.com/obra/superpowers)** is a plugin framework that installs *skills* into Claude Code. Skills are structured workflow instructions that tell Claude *how* to approach problems, not just what to do. Key examples: `brainstorming` enforces structured idea pressure-testing before any planning begins; `writing-plans` locks a full implementation spec before a single line of code is written; `test-driven-development` enforces red-green-refactor discipline during the build phase; `subagent-driven-development` parallelizes implementation across multiple Claude instances, each working against the locked spec.

**[gstack](https://github.com/garrytan/gstack)** is a community skill pack — 40+ specialized tools covering security audits (OWASP/STRIDE), CEO-lens scoping, design QA, document generation, and more.

### What j-stack adds on top

Raw Superpowers + gstack is powerful but sprawling. j-stack is an opinionated assembly that makes specific choices:

- **Cherry-picks 11 of gstack's 40+ skills** — only the ones that complement rather than conflict with Superpowers' workflow
- **Injects explicit model directives** into each skill so you're not burning Opus credits on mechanical templating tasks
- **Builds 4 custom skills** that don't exist anywhere else (see below)
- **Wires up a `.planning/` wiki** readable by Claude Code, Codex CLI, Cursor, ChatGPT, and Gemini — context survives tool switches mid-engagement
- **Routes models by cognitive demand**: Opus for judgment calls, Sonnet for execution, Haiku for housekeeping

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
