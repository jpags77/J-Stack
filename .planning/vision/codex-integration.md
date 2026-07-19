# Design: Codex as a First-Class j-stack Runtime

Date: 2026-05-29
Updated: 2026-07-19
Status: implemented; expanded to separate runtime

## Problem

j-stack already mentioned Codex as a handoff target and independent reviewer, but Codex had no generated root instruction file. A manually imported `AGENTS.md` existed, while `install.sh` only managed `CLAUDE.md`. Future installs could drift, and Codex would not reliably know the phase pipeline or how to interpret Claude slash-skill names.

## Decision

Treat Codex as a separate runtime through `AGENTS.md` and `.planning/AGENTS.md`, while keeping `.planning/` as the shared state layer. Claude remains the primary skill host for Claude slash commands and plugin execution. Codex should not emulate those slash commands directly; it follows the same lane semantics through Codex-native repo work.

## Operating modes

- **Direct runtime mode:** The user opens the repo in Codex intentionally. Codex reads `AGENTS.md`, `.planning/index.md`, `.planning/log.md`, and the latest handoff snapshot, then continues the current phase directly.
- **Fallback mode:** Claude usage limits hit or the user switches tools. Codex resumes from the same `.planning/` state.
- **Review mode:** Claude invokes Codex for `second-opinion`. Codex inspects the requested artifact independently and returns review-ready findings for `.planning/reviews/`.

## Implementation

- `install.sh` now generates or updates root `AGENTS.md` with Codex lane configuration.
- `install.sh --codex-only` configures the Codex runtime without requiring Claude Code, Superpowers, gstack skills, Claude agents, or the Claude SessionStart hook.
- `poc-wiki-init` now emits a richer `.planning/AGENTS.md` template for Codex.
- Root `AGENTS.md` and `.planning/AGENTS.md` now include Codex runtime modes and a Claude-skill-to-Codex-behavior mapping.
- README documents the Codex runtime and its install path.
- `tests/codex-config.sh` verifies the installer, root instructions, planning schema, and README stay aligned.
