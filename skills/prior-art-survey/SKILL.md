---
name: prior-art-survey
description: Conducts a prior-art investigation before implementation planning. Activates after brainstorming produces a spec for a non-trivial feature, service, or component. Dispatches three parallel research subagents (whole OSS projects, libraries/SDKs, architectural patterns), synthesizes findings into a fit-gap report, and forces a build/adopt/fork/hybrid checkpoint with the user before writing-plans runs. Use whenever a spec describes something that probably already exists as software (parser, scheduler, queue, dashboard, ORM, auth, CMS, etc.).
---

# Prior Art Survey

## When this skill activates

This skill runs **between brainstorming and writing-plans**, when the brainstormed spec describes:

- A new feature, service, or component non-trivial enough to warrant its own implementation plan
- Anything that sounds like a category of software that probably already exists (CMS, scheduler, parser, ORM, dashboard, queue, auth, file uploader, search index, etc.)
- An architectural decision where established patterns likely exist

This skill does NOT activate for:

- Trivial changes (single-function edits, bug fixes, refactors)
- Glue code or wiring unique to this codebase
- Work where the user has already explicitly chosen a library/approach during brainstorming
- Direct continuations of in-progress work

If unsure, default to running it. The cost is one parallel research pass; the cost of skipping it is reinventing maintained software or building on a deprecated package.

## Why this exists

LLM coding agents have two failure modes around prior art:

1. **Reinvention.** Building from scratch what a maintained library already solves, because the library wasn't surfaced during brainstorming.
1. **False consolidation.** Declaring an existing project "close enough" when it isn't, leading to a fork that costs more than greenfield would have.

A focused research pass before planning catches both. The result feeds writing-plans with explicit context, so the implementation plan reflects an actual decision instead of a default.

## Process

### Step 1: Confirm the spec is ready

The brainstorm output must include:

- A clear problem statement
- Functional requirements (what it must do)
- Any explicit constraints (language, framework, license, deployment target, performance bounds)

If any of these are missing, return to brainstorming. Do not proceed with prior-art research against an underspecified target — the scouts will return noise.

### Step 2: Dispatch three parallel scout subagents

Launch all three in parallel, each with the full spec and its specific scope:

1. **prior-art-oss-scout** — searches for whole projects/applications that overlap with the spec
1. **prior-art-library-scout** — searches for libraries/SDKs/packages that solve the core problem within an existing codebase, and verifies current maintenance status (catches deprecated packages)
1. **prior-art-patterns-scout** — searches for established architectural patterns and reference implementations

Each returns a structured fit-gap report. See the agent definitions for the exact format.

### Step 3: Synthesize findings

Consolidate the three scout reports into a single brief for the user. Use this structure:

```markdown
## Prior Art Survey: [spec name]

### What already exists
[2–4 sentences naming the strongest candidates across all three categories. Be specific — name the projects, libraries, or patterns.]

### Fit-gap summary

| Option | Type | Covers from spec | Doesn't cover | Maintenance | License |
|--------|------|------------------|---------------|-------------|---------|
| ...    | OSS / Library / Pattern | ... | ... | active / stable / dormant | ... |

### Stale-package warnings
[Any packages the agent might pattern-match to from training data that are now deprecated, with the current replacement. Pulled from the library scout.]

### Recommendation
**[BUILD | ADOPT | FORK | HYBRID]**

[2–3 sentences explaining why. If ADOPT or FORK, name the specific project or library. If HYBRID, name which library covers which subset and what's left to build.]

### Open questions for the user
[Anything the scouts couldn't resolve from search alone — e.g., "does the user need feature X, which only project Y supports?"]
```

Save this synthesis to `.planning/prior-art/[spec-slug].md` if the project uses a planning directory, otherwise keep it in the conversation.

### Step 4: Mandatory checkpoint with the user

Present the synthesis and ask explicitly:

> Given this prior art, what do you want to do?
> 
> - **Build** — proceed with the original spec from scratch
> - **Adopt [name]** — use the existing project/library; planning may be unnecessary or much smaller
> - **Fork [name]** — start from the existing project and modify; planning shifts to "what to change"
> - **Hybrid** — use [library X] for [subset] and build [the rest]

Do NOT proceed to writing-plans without an explicit answer from the user. The original spec may need revision based on the choice.

### Step 5: Pass results to writing-plans

The synthesis document and the user's choice become inputs to writing-plans. If the user chose ADOPT, FORK, or HYBRID:

- The implementation plan must reference the specific prior art by name
- The plan must explain how it's being used (as-is, with config, with modifications)
- The plan should NOT redo work the prior art already covers

If the user chose BUILD, the synthesis still feeds the plan as context — the patterns scout output in particular should inform architectural decisions.

## Anti-patterns this skill prevents

- **Link-dump research.** Scout reports must contain fit-gap analysis, not just URLs. The skill rejects scout output that is only links.
- **Consolidation bias.** If an option doesn't actually fit, the recommendation must say BUILD, not "fork X with substantial modifications." Heavy modifications are usually a sign the fit is wrong.
- **Stale package suggestion.** The library scout verifies current maintenance status and version before recommending. Packages deprecated since the model's training cutoff get flagged with their current replacement.
- **Premature commitment.** The checkpoint is mandatory; the user, not the agent, makes the build/adopt/fork call.
- **Padded results.** If a scout finds zero good candidates, it says so. Better to report "nothing fits, build it" than to recommend an abandoned project as the best of a bad set.

## Output

A synthesis document at `.planning/prior-art/[spec-slug].md` (if planning directory exists) and an explicit user decision recorded in the conversation, both passed forward to writing-plans.
