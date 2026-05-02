# Outstanding Items

## Blockers requiring user action

### 1. Superpowers plugin — NOT installed

The plan requires Superpowers for the Refine, Plan, and Build phases (`brainstorming`, `writing-plans`, `subagent-driven-development`).

**Install via Claude Code interactive session:**
```
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

After install, verify `/superpowers:brainstorm` appears in `/help`.

### 2. prior-art-survey skill set — partially installed

Installed so far:
- ✅ `prior-art-oss-scout` — installed at `~/.claude/skills/prior-art-oss-scout/SKILL.md`

Still needed (paste each when ready):
- ❌ `prior-art-library-scout` — investigates libraries/SDKs (sonnet)
- ❌ `prior-art-patterns-scout` — investigates architectural patterns (sonnet)
- ❌ `prior-art-survey` — main orchestrator skill that dispatches all three scouts in parallel (opus)

**Action required:** Provide the remaining three skill definitions and they will be installed immediately.

### 3. Codex CLI authentication — requires user action

Codex CLI is installed (`codex-cli 0.128.0`) but has not been authenticated. On first `codex` invocation, authenticate via:
- **ChatGPT OAuth** (requires Plus/Pro/Business/Edu/Enterprise plan), or
- **API key:** `export OPENAI_API_KEY="sk-..."`

The `second-opinion` skill depends on authenticated Codex CLI.

## Phase 4 verification status

Steps that can run now (no Superpowers needed):
- Step 2: `poc-wiki-init` ✓
- Step 6: `/cso` on a stub file ✓
- Step 7: `second-opinion` (requires Codex auth first)
- Step 8: `stakeholder-pack` ✓
- Step 9: `handoff-snapshot` ✓

Steps blocked on prerequisites:
- Step 3: `/office-hours` — requires Superpowers
- Step 4: `/superpowers:brainstorm` — requires Superpowers
- Step 5: `prior-art-survey` — oss-scout installed; library-scout, patterns-scout, and main orchestrator still needed
