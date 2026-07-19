# Handoff Snapshot — 2026-07-19T17:15:12Z

```json
{
  "schema": "j-stack.handoff.blackboard.v1",
  "timestamp": "2026-07-19T17:15:12Z",
  "agent": "Codex",
  "reason": "checkpoint",
  "repo": {
    "branch": "main",
    "head_before_changes": "a26713d",
    "remote_tracking": "origin/main",
    "dirty": true
  },
  "state": {
    "iteration": "1",
    "phase": "BUILD (maintenance)",
    "current_task": "Make Codex a separate j-stack runtime and validate the CLI install path"
  },
  "decisions": [
    {
      "id": "D3",
      "decision": "Codex is not the primary runtime; Claude remains the primary skill host. Codex is a separate runtime that uses AGENTS.md plus .planning/ to execute the same lane semantics directly."
    },
    {
      "id": "D4",
      "decision": "install.sh should support a Codex-only path so a repo can be configured for Codex without requiring Claude Code, Superpowers, gstack skill installation, Claude agents, or the Claude SessionStart hook."
    }
  ],
  "changes": [
    "Added install.sh --codex-only.",
    "Moved install.sh SCRIPT_DIR initialization before runtime branches.",
    "Kept the default installer Claude-oriented while skipping Claude-only phases in Codex-only mode.",
    "Added Codex-only verification for AGENTS.md and codex CLI.",
    "Updated final installer next steps for Codex-only runs.",
    "Updated README prerequisites, install instructions, and Codex runtime section.",
    "Updated templates/codex-role.md, skills/poc-wiki-init/templates/codex-role.md, root AGENTS.md, and .planning/AGENTS.md to include Direct runtime mode.",
    "Updated .planning/vision/codex-integration.md.",
    "Updated tests/codex-config.sh for --codex-only and fixed grep handling for patterns that begin with --."
  ],
  "local_environment_observed": [
    "codex found at /opt/homebrew/bin/codex.",
    "claude found at /Volumes/Home/Users/.local/bin/claude.",
    "Superpowers plugin found under /Volumes/Home/Users/.claude/plugins/."
  ],
  "verification": [
    "bash -n install.sh",
    "bash tests/structure.sh",
    "bash tests/codex-config.sh",
    "bash install.sh --codex-only",
    "git diff --check"
  ],
  "not_run": [
    "Full bash install.sh default path was not run because it mutates ~/.claude/skills, ~/.claude/agents, and ~/.claude/settings.json; Codex-only verification did not need those writes."
  ],
  "remaining_steps": [
    "Decide whether to run the full default installer locally to refresh Claude runtime files.",
    "Consider adding a managed-marker replacement strategy so install.sh can update stale AGENTS.md/CLAUDE.md sections instead of skipping once the heading exists.",
    "Continue backlog N6, N7/N9, and N14 from the audit snapshot."
  ]
}
```

## Human Summary

Codex is now documented and installable as a separate runtime. `bash install.sh --codex-only` configures and verifies `AGENTS.md` without touching the Claude skill host. The default installer still handles Claude skills, gstack, custom skills, agents, and the Claude SessionStart hook.

Local checks confirmed Codex CLI, Claude CLI, and the Superpowers plugin are present. The Codex-only installer path was run successfully. The full default installer was not run because it writes to the user's Claude home directories.
