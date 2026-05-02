# Outstanding Items

## Blockers requiring user action

### 1. Codex CLI authentication — requires user action

Codex CLI is installed (`codex-cli 0.128.0`) but has not been authenticated. On first `codex` invocation, authenticate via:
- **ChatGPT OAuth** (requires Plus/Pro/Business/Edu/Enterprise plan), or
- **API key:** `export OPENAI_API_KEY="sk-..."`

The `second-opinion` skill depends on authenticated Codex CLI.

---

## Installed skills — complete inventory (33 total)

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

### Superpowers (14 skills, installed from obra/superpowers)
| Skill | Model | Phase |
|---|---|---|
| brainstorming | opus | Refine |
| writing-plans | opus | Plan |
| subagent-driven-development | sonnet | Build |
| dispatching-parallel-agents | — | Build |
| executing-plans | — | Build |
| test-driven-development | — | Build |
| systematic-debugging | — | Debug |
| verification-before-completion | — | Build |
| requesting-code-review | — | Polish |
| receiving-code-review | — | Polish |
| finishing-a-development-branch | — | Handoff |
| using-git-worktrees | — | Build |
| using-superpowers | — | Meta |
| writing-skills | — | Meta |

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

---

## Phase 4 verification status

All steps can now run except step 7 (requires Codex auth):
- Step 2: `poc-wiki-init` ✓
- Step 3: `/office-hours` ✓
- Step 4: `/superpowers:brainstorm` → `/brainstorming` ✓
- Step 5: `prior-art-survey` ✓
- Step 6: `/cso` ✓
- Step 7: `second-opinion` — blocked on Codex CLI auth
- Step 8: `stakeholder-pack` ✓
- Step 9: `handoff-snapshot` ✓
