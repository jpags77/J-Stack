/**
 * j-stack-plan — deterministic planning pipeline
 *
 * Pipeline: REFINE → SURVEY (parallel) → PRE-MORTEM → PLAN
 *
 * PLAN is last. It reads brainstorm + prior art + pre-mortem and writes a spec
 * that explicitly addresses every identified failure mode.
 *
 * Usage:
 *   /j-stack-plan                          — reads context from .planning/
 *   /j-stack-plan "build X for Y use case" — injects an additional brief
 *
 * Requires: Claude Code v2.1.154+ with dynamic workflows enabled.
 * Enable: /config → Dynamic workflows → on
 *
 * Output files (all under .planning/):
 *   vision/brainstorm-<date>.md
 *   prior-art/oss-<date>.md
 *   prior-art/libraries-<date>.md
 *   prior-art/patterns-<date>.md
 *   decisions/pre-mortem-<date>.md
 *   plans/spec-v1.md  (or spec-vN.md if prior versions exist)
 */

const date = new Date().toISOString().slice(0, 10);
const userBrief = args ? `\n\nAdditional context from user: ${args}` : "";

// ─── Phase 1: REFINE — Brainstorming ─────────────────────────────────────────

await agent(`
  You are running the REFINE phase of the j-stack pipeline.

  Read for project context:
  - .planning/CRITICAL_FACTS.md
  - .planning/status.md
  ${userBrief}

  Run superpowers:brainstorming. Conduct structured pressure-testing of what we are
  building and why. Challenge the core assumptions. Ask: is this actually the right
  problem? What would we cut if forced to ship in half the time?

  File the complete brainstorming output to: .planning/vision/brainstorm-${date}.md
  Append to .planning/log.md:  ## [${date}] brainstorming | REFINE complete
  Update .planning/index.md to reference the new file.

  Do not summarise — write the full brainstorming output to the wiki file.
`);

// ─── Phase 2: SURVEY — Three parallel prior-art scouts ───────────────────────

await Promise.all([

  agent(`
    You are the OSS scout in the SURVEY phase of the j-stack pipeline.

    Read .planning/vision/brainstorm-${date}.md for what we are building.

    Search GitHub, package registries, and known open-source projects for existing
    solutions we could adopt or adapt instead of building from scratch. For each:
    - Name, repo URL, licence
    - What it solves and what it leaves out
    - Adopt / adapt / reject — with one-line rationale

    File findings to: .planning/prior-art/oss-${date}.md
    Append to .planning/log.md: ## [${date}] prior-art-oss | SURVEY complete
  `),

  agent(`
    You are the library scout in the SURVEY phase of the j-stack pipeline.

    Read .planning/vision/brainstorm-${date}.md for what we are building.

    Search language-specific ecosystems (npm, PyPI, Go modules, Cargo, etc.) for
    packages that solve this problem — or 80% of it. For each:
    - Package name, ecosystem, weekly downloads / stars
    - What it provides
    - Use / avoid — with one-line rationale

    File findings to: .planning/prior-art/libraries-${date}.md
    Append to .planning/log.md: ## [${date}] prior-art-libraries | SURVEY complete
  `),

  agent(`
    You are the patterns scout in the SURVEY phase of the j-stack pipeline.

    Read .planning/vision/brainstorm-${date}.md for what we are building.

    Identify the established architectural and design patterns that apply to this
    problem domain. For each:
    - Pattern name and canonical reference
    - Why it fits (or doesn't fit) this problem
    - Apply / adapt / avoid — with one-line rationale

    File findings to: .planning/prior-art/patterns-${date}.md
    Append to .planning/log.md: ## [${date}] prior-art-patterns | SURVEY complete
  `)

]);

// ─── Phase 3: PRE-MORTEM — Stress-test before the spec exists ────────────────

await agent(`
  You are running the PRE-MORTEM phase of the j-stack pipeline.

  No spec exists yet — that is intentional. Your job is to stress-test the approach
  BEFORE the plan is written, so the plan can be designed to address the risks.

  Read everything gathered so far:
  - .planning/vision/brainstorm-${date}.md
  - .planning/prior-art/oss-${date}.md
  - .planning/prior-art/libraries-${date}.md
  - .planning/prior-art/patterns-${date}.md

  Assume the project has launched and failed. Work backwards. Identify the top 5
  failure modes across these categories:
    1. Technical — wrong assumptions, underestimated complexity, integration failures
    2. Scope — feature creep, wrong core use case, shifting definition of done
    3. Assumptions — dependencies unavailable, user behaviour differed, data quality
    4. Process — spec drift mid-build, verification skipped, subagent coordination
    5. Stakeholder — demo missed the ask, security/compliance blocked adoption

  For each failure mode produce:
    - Name
    - How it manifests
    - Likelihood: high / medium / low
    - Early warning signal to watch for during BUILD
    - Mitigation: what the plan must include to address this

  Close with a net assessment: what are the non-negotiable things the plan must
  address to be credible?

  File output to: .planning/decisions/pre-mortem-${date}.md
  Append to .planning/log.md: ## [${date}] pre-mortem | PRE-MORTEM complete
  Update .planning/index.md to reference the new file.
`);

// ─── Phase 4: PLAN — Spec writing with full context ──────────────────────────

await agent(`
  You are running the PLAN phase of the j-stack pipeline. This is the final phase.

  You have the full output of brainstorming, prior-art research, and pre-mortem analysis.
  Your job is to write a complete, locked implementation spec that synthesises all of it.

  Read:
  - .planning/vision/brainstorm-${date}.md
  - .planning/prior-art/oss-${date}.md
  - .planning/prior-art/libraries-${date}.md
  - .planning/prior-art/patterns-${date}.md
  - .planning/decisions/pre-mortem-${date}.md  ← REQUIRED: the spec must address each
    failure mode identified here. For each one, note explicitly how the spec mitigates it.

  Run superpowers:writing-plans with all of the above as input context. The spec must:
  1. Incorporate the strongest ideas from brainstorming
  2. Record prior-art decisions (what was selected and why — cite the survey files)
  3. For each pre-mortem failure mode: include a "Risk mitigation" note in the relevant
     spec section explaining how the design addresses it

  Check whether .planning/plans/ already contains a spec. If so, name the new file
  spec-v<N+1>.md (incrementing N). Otherwise use spec-v1.md.

  File the locked spec to: .planning/plans/spec-v1.md  (or vN+1 if prior exist)
  Update .planning/CRITICAL_FACTS.md: set Current phase to BUILD
  Rewrite .planning/status.md:
    Phase: BUILD
    Last completed: PLAN (j-stack-plan workflow)
    Active task: none
    Next steps: run session-start to begin BUILD phase
  Append to .planning/log.md: ## [${date}] writing-plans | PLAN complete — pipeline done
  Update .planning/index.md.
`);
