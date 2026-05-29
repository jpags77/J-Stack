# Design: Codex as a First-Class j-stack Runtime

Date: 2026-05-29
Status: implemented

## Problem

j-stack already mentioned Codex as a handoff target and independent reviewer, but Codex had no generated root instruction file. A manually imported `AGENTS.md` existed, while `install.sh` only managed `CLAUDE.md`. Future installs could drift, and Codex would not reliably know the phase pipeline or how to interpret Claude slash-skill names.

## Decision

Treat Codex as a first-class runtime through `AGENTS.md` and `.planning/AGENTS.md`, while keeping `.planning/` as the shared state layer. Codex should not emulate Claude slash commands directly. Instead, the Codex instruction files map each Claude skill surface to equivalent Codex behavior.

## Operating modes

- **Fallback mode:** Claude usage limits hit or the user switches tools. Codex reads `AGENTS.md`, `.planning/index.md`, `.planning/log.md`, and the latest handoff snapshot, then continues the current phase.
- **Review mode:** Claude invokes Codex for `second-opinion`. Codex inspects the requested artifact independently and returns review-ready findings for `.planning/reviews/`.

## Implementation

- `install.sh` now generates or updates root `AGENTS.md` with Codex lane configuration.
- `poc-wiki-init` now emits a richer `.planning/AGENTS.md` template for Codex.
- Root `AGENTS.md` and `.planning/AGENTS.md` now include Codex operating modes and a Claude-skill-to-Codex-behavior mapping.
- README documents the two Codex integration modes.
- `tests/codex-config.sh` verifies the installer, root instructions, planning schema, and README stay aligned.
