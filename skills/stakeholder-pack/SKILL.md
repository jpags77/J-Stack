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