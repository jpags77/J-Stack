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