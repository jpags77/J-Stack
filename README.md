# j-stack

**[→ Visual overview](index.html)** · open in a browser or enable GitHub Pages

A Claude Code configuration for agentic product development — from problem definition through a demo-ready, defensible deliverable.

---

## What this is and where it came from

The goal was specific: **encode agentic coding best practices into the early phases of product development** — the discovery, scoping, prior art, and planning work that happens before a line of code runs. These phases are where AI agents cause the most damage when left undisciplined. They build the wrong thing confidently, reinvent existing solutions enthusiastically, and skip the "is this the right problem?" question entirely.

The approach was to not build this from scratch. Before writing anything, the right move was to research what already existed — and that research is exactly what the `prior-art-survey` skill in this stack does. Practicing what we preach.

That survey found two projects already doing the hard parts better than a greenfield build would:

- **[Superpowers](https://github.com/obra/superpowers)** by [@obra](https://github.com/obra) — agentic coding discipline encoded as Claude Code skills: structured brainstorming, spec-locked planning, TDD enforcement, parallel subagents in isolated worktrees, verification before completion. The answer to every known agentic anti-pattern.
- **[gstack](https://github.com/garrytan/gstack)** by [@garrytan](https://github.com/garrytan) — a 40+ skill community pack covering the gaps Superpowers doesn't: founder-lens scoping, UI design workflow, security review, QA, and cross-tool handoff.

j-stack is an integration layer on top of these two foundations. It doesn't replace them — it cherry-picks the right skills from each, adds four custom skills that fill remaining gaps (prior art research, cross-vendor review, stakeholder packaging, session continuity), wires them into a coherent pipeline, and configures the session behavior so the whole thing runs without manual orchestration.

The insight both projects share: **AI agents are powerful but undisciplined.** The value isn't the models — it's the process imposed on them. j-stack applies that principle earlier in the lifecycle than either project does alone, covering the full arc from "are we solving the right problem?" through a security-reviewed, cross-vendor-validated, stakeholder-ready deliverable.

**Credit where it's due:** the core discipline in this stack belongs to @obra and @garrytan. j-stack is configuration, integration, and the early-phase additions on top of their work.

---

## What we've put together — and why

### Superpowers — agentic coding discipline as a default

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

---

### gstack — specialized skills for the gaps Superpowers doesn't cover

**[gstack](https://github.com/garrytan/gstack)** is a community skill pack with 40+ tools. j-stack doesn't install it wholesale — that would conflict with Superpowers' planning lane and add adoption tax. Instead, 11 skills are cherry-picked for specific gaps: frontend scoping, UI work, security, QA, docs, and safety guardrails.

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

**What was skipped and why:** `/autoplan` and `/plan-eng-review` overlap Superpowers' planning lane — two planners create conflicts. `/ship`, `/canary`, `/investigate`, and `/land-and-deploy` are prod-shipping tools; PoC mission doesn't need them. `/retro`, `/pair-agent`, and `gbrain` solve problems outside the PoC scope entirely.

---

### prior-art-survey — a net new addition

Neither Superpowers nor gstack ships a prior-art research agent. This is an original addition, bundled in this repo under `skills/`, and it fills a real gap: **AI agents are enthusiastic reinventors of wheels.**

`prior-art-survey` dispatches three parallel scouts before any implementation begins:

| Scout | What it searches | Why it matters |
|-------|-----------------|----------------|
| OSS scout | GitHub, package registries, known open-source projects | Finds existing solutions you could adopt or adapt instead of building |
| Library scout | Language-specific ecosystems (npm, PyPI, etc.) | Finds packages that solve the problem — or 80% of it |
| Patterns scout | Established architectural and design patterns | Ensures the approach fits recognized patterns, not just intuition |

The output isn't just research — it becomes the "what else did you consider" section of the stakeholder pack, and it's the primary defense against the classic enterprise objection: *"did you look at X before building this?"*

---

### Five custom skills — what doesn't exist anywhere else

| Skill | What it does |
|-------|-------------|
| `session-start` | Session orientation ritual. Run at the start of every session — reads wiki state, confirms fidelity target, surfaces scope changes, handles iteration bumps, and declares the session goal before any work begins. Prevents silent drift between sessions. |
| `poc-wiki-init` | Bootstraps the `.planning/` wiki at project start. Asks the fidelity target question upfront, generates schema files for Claude Code, Codex, Cursor, and ChatGPT. Idempotent — safe to run again. |
| `handoff-snapshot` | Writes a timestamped snapshot to `.planning/handoffs/` with context, decisions, next steps, and a paste-ready continuation prompt for the next tool. |
| `second-opinion` | Dispatches an artifact to Codex CLI for independent review, then synthesizes a convergence/divergence matrix. Two AI vendors reviewing the same artifact independently. |
| `stakeholder-pack` | Aggregates vision, prior-art, security, and cross-model review outputs into a single executive-ready document. Pre-answers the five standard enterprise PoC questions. |

---

### Token optimization and the second brain

Anthropic is tightening usage limits, and burning Opus credits on mechanical work is a real cost. j-stack addresses this at two levels.

**Model routing by cognitive demand** is the first defense. Every skill carries an explicit model directive injected at install time:

- **Opus** — judgment calls: scoping, security reasoning, cross-model synthesis, stakeholder framing
- **Sonnet** — execution: implementation, audits, UI conversion, code review
- **Haiku** — mechanical operations: templating, summarizing, file locking

A full pipeline run spends Opus tokens where they move the needle and Haiku tokens on everything else.

**The `.planning/` wiki is the second defense** — and the emergency bailout. This is the same concept Andrej Karpathy describes with his Obsidian second brain: a persistent, structured external memory that outlives any single session or tool. Every decision, artifact, and handoff is written to markdown files in `.planning/`. The wiki speaks every tool's native language:

| File | Read by |
|------|---------|
| `.planning/CLAUDE.md` | Claude Code |
| `.planning/AGENTS.md` | Codex CLI |
| `.planning/.cursor/rules` | Cursor |
| `.planning/chatgpt-brief.md` | ChatGPT (paste-in) |

When Anthropic limits hit mid-engagement — and they will — `handoff-snapshot` writes a continuation prompt to `.planning/handoffs/`. Paste it into Codex, Cursor, or ChatGPT and the session resumes from exactly where it stopped. No context lost, no re-explanation, no starting over.

---

## How it works

### The pipeline

```
EXPAND → REFINE → SURVEY → PLAN → BUILD → POLISH → DEFEND → HANDOFF
```

| Phase | Skills | What happens |
|-------|--------|-------------|
| **Expand** | `/office-hours`, `/plan-ceo-review` | Founder-lens reframe. Are we solving the right problem? What would a 10x founder cut? |
| **Refine** | `brainstorm` (SP) | Structured pressure-testing of the approach. Locked before prior-art begins. |
| **Survey** | `prior-art-survey` | Three parallel scouts: OSS, libraries, patterns. Answers "did you try X" before it's asked. |
| **Plan** | `writing-plans` (SP) | Full implementation spec, Opus-reviewed. Nothing builds until this is locked. |
| **Build** | `subagent-driven-dev` (SP), `/design-shotgun`, `/design-html` | TDD execution. Parallel subagents in isolated worktrees, implementing against the spec. |
| **Polish** | `/qa`, `/design-review`, `/cso` | Audit against spec, design review, OWASP/STRIDE security analysis. |
| **Defend** | `second-opinion`, `stakeholder-pack` | Codex independently reviews Claude's output. Findings synthesized. Stakeholder pack assembled. |
| **Handoff** | `/document-release`, `handoff-snapshot` | Docs generated from diff. Wiki snapshot written for cross-tool resumption. |

### Complete skill flow

Every session enters through `session-start`, which reads wiki state and dispatches to the correct phase automatically.

```
session-start  [custom · sonnet]  ← fires automatically at session start (hook)
│
├── if no .planning/ wiki → poc-wiki-init  [custom · haiku]
│     ├── asks fidelity target (working PoC / polished demo / MVP)
│     └── if existing repo: asks goal, constraints, definition of done
│
├── orients: iteration / phase / fidelity / engagement goal
│
└── dispatches to current phase ↓

EXPAND
  /office-hours       [gstack · opus]   ← YC-style problem reframe
  /plan-ceo-review    [gstack · opus]   ← CEO/founder scope challenge

REFINE
  superpowers:brainstorming  [superpowers · opus]

SURVEY
  prior-art-survey    [custom · opus]
  ├── prior-art-oss-scout      [custom · sonnet]  ← parallel
  ├── prior-art-library-scout  [custom · sonnet]  ← parallel
  └── prior-art-patterns-scout [custom · sonnet]  ← parallel

PLAN
  superpowers:writing-plans  [superpowers · opus]

BUILD
  superpowers:subagent-driven-development  [superpowers · sonnet]
  ├── superpowers:using-git-worktrees          ← isolated branch per subagent
  ├── superpowers:test-driven-development      ← red-green-refactor enforced
  ├── superpowers:verification-before-completion ← gates done claims
  └── superpowers:systematic-debugging         ← invoked when stuck
  /design-shotgun  [gstack · sonnet]  ← UI: explore directions
  /design-html     [gstack · sonnet]  ← UI: execute direction

POLISH  (session-start checks log.md and dispatches to first pending)
  /qa             [gstack · sonnet]
  /design-review  [gstack · sonnet]
  /cso            [gstack · opus]

DEFEND
  second-opinion   [custom · opus]
  └── /codex  [gstack · sonnet]  ← shells out to OpenAI Codex CLI
  stakeholder-pack [custom · opus]

HANDOFF
  /document-release  [gstack · sonnet]
  handoff-snapshot   [custom · haiku]  ← also fires when switching tools

SAFETY / ON-DEMAND
  /freeze  [gstack · haiku]
  /guard   [gstack · haiku]
```

### SDLC coverage — the discovery-to-demo arc

j-stack covers the **discovery → demo arc** of the SDLC. What's deliberately out of scope is the production-ops side — deployment, monitoring, incident response — because PoC mission ≠ production mission.

| SDLC Phase | j-stack Stage | Engineering PM Principle |
|---|---|---|
| Product Discovery | EXPAND | *Are we solving the right problem?* Reframe before engineering begins. |
| Requirements & Ideation | REFINE | Structured pressure-testing before committing to an approach. |
| Feasibility / Build-vs-Buy | SURVEY | Named, reasoned alternatives. Every "did you try X" answered before the meeting. |
| Technical Design | PLAN | Spec locked before implementation. Explicit gate — nothing builds until this is done. |
| Development | BUILD | TDD enforced, parallel subagents, spec-bound execution. |
| QA & Security | POLISH | Definition of done against spec. Risk management as a deliverable. |
| Stakeholder Review | DEFEND | Pre-answered objections, cross-vendor validation. |
| Documentation & Handoff | HANDOFF | Docs from diff. Knowledge transfer built in, not bolted on. |

**Out of scope by design:** Deployment / Release ops · Monitoring / Observability · Incident response / Maintenance *(PoC mission ≠ production)*

### The five questions enterprise stakeholders always ask

j-stack produces artifacts that answer these before the meeting:

| Question | Artifact |
|----------|----------|
| Why did you build it this way? | Vision doc from `/office-hours` + `brainstorm` |
| What else did you consider? | `prior-art-survey` output (OSS, libraries, patterns) |
| Is it secure? | `/cso` OWASP/STRIDE security review |
| Does it actually work? | `/qa` audit against spec + TDD test suite |
| Why should I trust one AI vendor? | `second-opinion` cross-vendor convergence matrix |

All five are assembled by `stakeholder-pack` into a single document before the demo. The meeting shifts from "defend the work" to "discuss what's next."

---

## How to use it

### Prerequisites

- [Claude Code](https://claude.ai/code) installed (`which claude`)
- [Superpowers plugin](https://github.com/obra/superpowers) installed in Claude Code
- `prior-art-survey` + three scout skills (bundled in this repo — installed automatically by `install.sh`)
- [OpenAI Codex CLI](https://github.com/openai/codex) installed and authenticated (for `second-opinion`)
- git, bash, standard Unix tools

### Installation

```bash
git clone https://github.com/jpags77/J-Stack.git
cd j-stack
bash install.sh
```

```bash
bash install.sh --skip-codex    # skip Codex CLI check (if not using second-opinion)
bash install.sh --skip-verify   # skip post-install verification
```

The script clones gstack, copies 11 cherry-picked skills into `~/.claude/skills/` with model directives injected, installs the 5 custom skills, writes the project `CLAUDE.md` lane configuration, and creates a global `~/.claude/CLAUDE.md` that makes j-stack the session authority in every project.

### Starting a new PoC or improving an existing repo

`session-start` fires automatically at session start (configured as a hook by `install.sh`). You don't run it manually.

**First session on a new project:**
```
1. Open Claude Code in your project directory
2. session-start fires automatically
   ├── bootstraps .planning/ wiki (asks fidelity target)
   └── dispatches to /office-hours to begin EXPAND
3. Pipeline runs phase by phase from there
```

**First session on an existing repo:**
```
1. Open Claude Code in the repo
2. session-start fires automatically
   ├── bootstraps .planning/ wiki
   ├── asks: goal, constraints, definition of done, prior docs
   └── dispatches to the right phase based on your answers
      (new feature → EXPAND, known spec → PLAN, bug fixes → BUILD, etc.)
```

**Every subsequent session:**
```
1. session-start fires automatically
   ├── reads wiki: iteration / phase / fidelity / open items
   ├── confirms scope: "anything changed since last session?"
   ├── confirms fidelity target
   ├── asks session goal
   └── dispatches to current phase
```

**Iterative development:** Scope changes mid-engagement bump the iteration, identify which phase to re-enter, and archive the prior plan. You don't restart the pipeline; you re-enter at the right phase with the new input.

### What's NOT installed — and why

These were considered and explicitly rejected:

| Skipped | Reason |
|---------|--------|
| Full gstack install | Conflicts with Superpowers, adoption tax |
| gstack `/autoplan`, `/plan-eng-review` | Overlap Superpowers' planning lane |
| gstack `/investigate`, `/ship`, `/canary` | Prod-shipping discipline; out of PoC scope |
| LiteLLM gateway | Proxy complexity not worth it for one OpenAI shell-out |
| MCP-based memory | ~6K token tax per session; markdown wiki achieves the same goal |
