# j-stack

A Claude Code stack optimized for enterprise PoC delivery.

**Three goals:**
1. Higher-fidelity demos in less time
2. Defensive deliverables that preempt "did you try X" objections
3. Cross-tool memory for resuming work in Codex / Cursor / ChatGPT when Anthropic usage limits hit

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
