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

### 2. Codex CLI authentication — requires user action

Codex CLI is installed (`codex-cli 0.128.0`) but has not been authenticated. On first `codex` invocation, authenticate via:
- **ChatGPT OAuth** (requires Plus/Pro/Business/Edu/Enterprise plan), or
- **API key:** `export OPENAI_API_KEY="sk-..."`

The `second-opinion` skill depends on authenticated Codex CLI.

## Installed skills — complete inventory

### gstack (11 skills)
| Skill | Model | Phase |
|---|---|---|
| office-hours | opus | Expand |
| plan-ceo-review | opus | Expand |
| cso | opus | Polish |
| qa | sonnet | Polish |
| design-shotgun | sonnet | Build |
| design-html | sonnet | Build |
| design-review | sonnet | Polish |
| codex | sonnet | Defend |
| document-release | sonnet | Handoff |
| freeze | haiku | Safety |
| guard | haiku | Safety |

### Custom skills (8 skills)
| Skill | Model | Phase |
|---|---|---|
| prior-art-survey | opus | Survey |
| second-opinion | opus | Defend |
| stakeholder-pack | opus | Defend |
| prior-art-oss-scout | sonnet | Survey (subagent) |
| prior-art-library-scout | sonnet | Survey (subagent) |
| prior-art-patterns-scout | sonnet | Survey (subagent) |
| poc-wiki-init | haiku | Setup |
| handoff-snapshot | haiku | Cross-tool |

## Phase 4 verification status

Steps that can run now:
- Step 2: `poc-wiki-init` ✓
- Step 5: `prior-art-survey` ✓ (all four pieces installed)
- Step 6: `/cso` on a stub file ✓
- Step 7: `second-opinion` (requires Codex auth first)
- Step 8: `stakeholder-pack` ✓
- Step 9: `handoff-snapshot` ✓

Steps blocked on Superpowers:
- Step 3: `/office-hours`
- Step 4: `/superpowers:brainstorm`
