# Ponytail Integration

**Status:** Implemented — 2026-06-17
**Plugin:** DietrichGebert/ponytail v4.7.0 · MIT · 25k+ stars

---

## What it is

Ponytail injects a minimalism decision tree into every code generation step. Before writing any code, the agent evaluates:

1. Does this need to exist? (YAGNI — skip if not)
2. Does stdlib do it?
3. Does the native platform do it?
4. Does an installed dependency do it?
5. Can it be done in one line?
6. Only then: write the minimum that works

Four intensity levels: `lite` / `full` / `ultra` / `off`. Security, accessibility, and validation are never compromised regardless of level.

Ships with three commands:
- `/ponytail-review` — examines a diff or doc, returns a delete-list
- `/ponytail-audit` — scans the whole repo, ranked findings
- `/ponytail-debt` — harvests deferred shortcuts into a tech-debt ledger

---

## Integration decision

**Level:** `full` (not `ultra`)

Ultra would flag TDD scaffolding (tests written before implementation) as YAGNI. `full` preserves that headroom while enforcing minimalism everywhere else.

**Phase placement: end of PLAN, before BUILD — not POLISH**

The initial instinct was to add `/ponytail-audit` as the first POLISH step. This was corrected: the highest-leverage moment is reviewing the *spec* before BUILD starts, not cleaning up over-engineered code after BUILD ends.

The plugin being always-on constrains code generation in real-time during BUILD. The explicit phase gate at PLAN is a second, upstream check on the spec itself.

```
[PLAN]  writing-plans          → spec produced
[PLAN]  ponytail-review spec   → trim YAGNI before BUILD  ← gate
[BUILD] subagent-driven-dev    (plugin active, constrains generation in real-time)
[POLISH] qa → design-review → cso
```

A POLISH audit would only catch bloat that already cost tokens to generate. The PLAN gate prevents it from being generated at all.

---

## Audit findings (run 2026-06-17)

Running `/ponytail-audit` on j-stack itself produced six ranked findings. Three were implemented immediately:

| Tag | Finding | Resolution |
|-----|---------|------------|
| `yagni` | 5 custom skills embedded as heredocs in install.sh (~730 lines) | Extracted to `skills/<name>/SKILL.md` files; install.sh uses `cp -r` like Phase 2.5 already did for prior-art-survey |
| `yagni` | GLOBAL_CLAUDE_SECTION in install.sh writes a stale simplified copy of `~/.claude/CLAUDE.md` that drifts immediately | Phase 3.5 removed; the real `~/.claude/CLAUDE.md` is managed separately and governs |
| `native` | index.html loaded React 18 + Babel standalone (~1.3MB CDN) for a static marketing page | Converted to vanilla HTML/CSS + minimal JS (nav scroll, copy button); TweaksPanel dead code deleted |

**Side effect fix:** The session-start skill embedded in install.sh was two iterations behind the live skill (missing Iteration Progress reconciliation, `[auto]`/`[confirm]` detection, Prior-art flag check). Extracting to a file and copying from the live version fixed this.

**Remaining findings (deferred):**

| Tag | Finding | Deferred reason |
|-----|---------|----------------|
| `yagni` | Stack ownership block duplicated verbatim in CLAUDE.md and AGENTS.md | Low urgency; both files are managed together |
| `delete` | TweaksPanel density preference wired but never applied | Fixed as part of React→HTML conversion |

---

## Background context (session 2026-06-17)

This session also surfaced two related patterns worth noting:

**`/goal` prompts** — issue a directive that names both the immediate task and the autonomous follow-on work. The Superpowers 6 gains ($165 overnight, 25+ experiments, 50% faster / 60% cheaper builds) came from a goal like: *"once this is done, run an autoresearch loop to improve cost-efficiency. make a hypothesis log. run at least 25 experiments."* The pattern: declare the optimization target and hypothesis structure upfront, don't prompt ad-hoc.

**Auto-research harness** (github.com/prime-radiant-inc/superpowers-autoresearch) — structured scientific method for AI skill improvement. Three tiers: MINE (free, extracts from existing artifacts), MICRO ($0.15–0.50/sample, controlled API calls with 5+ reps and a control group), FULL ($7–15/run, complete eval runs). Disciplines: exhaust MINE before MICRO, exhaust MICRO before FULL. The harness is the formalized version of what `/goal` prompts accomplish ad-hoc.

Both apply to j-stack: the `/goal` discipline is usable today in any session. The harness becomes relevant when experiment volume justifies formal infrastructure (hypothesis logs, reusable micro-test runners).
