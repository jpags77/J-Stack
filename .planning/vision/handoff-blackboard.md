# Design: Structured Handoff Blackboard

Date: 2026-06-12
Status: accepted

## Problem

`handoff-snapshot` originally produced a narrative session summary. That helps a human resume, but it leaves too much implicit for cross-tool agent handoff: which facts are confirmed, which sources are stale, what changed locally, and what a fresh agent should trust when README, `.planning/`, local git, and GitHub disagree.

## Decision

Upgrade `handoff-snapshot` into a structured blackboard. Each snapshot keeps the human continuation prompt, but starts with a valid JSON block using schema `j-stack.handoff.blackboard.v1`.

The blackboard records:

- repo state: branch, HEAD, dirty flag, remote
- engagement state: iteration, phase, fidelity, current task
- claims with status, confidence, and provenance
- decisions with rationale and source
- conflicts with preferred source and reason
- open questions with owner
- ordered next actions with blockers
- touched artifacts and verification results

## Operating Rule

After significant code interactions, create a durable checkpoint before switching tasks:

1. Commit the coherent git diff locally.
2. Update `.planning/` with notable decisions, review output, or changed state.
3. Append `.planning/log.md`.
4. Run `handoff-snapshot`.

GitHub push is intentionally not automatic. Pushing crosses the local/remote boundary and should happen only when the user asks or an explicit publish workflow is active.

## Prior Art

Inspired by the blackboard coordination pattern in `dl1683/irys-stateful-swarms`, especially typed shared state, provenance, confidence, and contradiction handling. j-stack adopts the artifact shape, not the full swarm runtime.
