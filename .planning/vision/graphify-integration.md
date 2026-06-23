# Graphify Integration

**Status:** Wired as on-demand optional tool — 2026-06-18
**Plugin:** safishamsi/graphify · MIT · YC S26 · 63K+ stars · 1.2M PyPI downloads

---

## What it is

Graphify turns any codebase into a persistent, queryable knowledge graph using Tree-sitter AST extraction. Code never leaves the machine — extraction is pure local static analysis with zero API calls. For docs, PDFs, and images, an LLM backend is used but is optional.

**Output (written to `graphify-out/`):**

| File | Purpose |
|------|---------|
| `GRAPH_REPORT.md` | Architecture summary: god nodes, cross-module surprises, rationale from comments, suggested questions |
| `graph.json` | Full queryable graph — traversed by the AI or queried via CLI |
| `graph.html` | Interactive browser visualization |

**In Claude Code:**
```bash
uv tool install graphifyy
graphify install    # writes CLAUDE.md section + PreToolUse hook
/graphify .         # builds the graph for the current project
graphify query "what connects auth to database?"
```

Also exposes an MCP server for team-shared access.

**Token impact:** 71.5× fewer tokens on mixed corpora vs. reading raw files.

---

## Integration decision

**On-demand, not always-on. Not a mandatory phase step.**

j-stack is primarily for greenfield PoC delivery — building new things fast. Graphify's highest value is on large, unfamiliar *existing* codebases. Requiring it on every project would violate the ponytail principle (YAGNI).

**When to use it:**
- First session on an existing repo engagement (add a feature, refactor, migration)
- SURVEY or early PLAN phase when the spec requires understanding an existing system's structure
- Large BUILD sprints where subagents are navigating a growing codebase

**When to skip it:**
- Empty greenfield before meaningful code exists (nothing to map yet)

**Refresh cadence:**
- Build once: end of first BUILD sprint (once scaffolding exists)
- Refresh: at major phase transitions (PLAN→BUILD, BUILD→POLISH) when structure has shifted
- No need to rebuild every session — graph is stable between structural changes

---

## Session-start integration

`session-start` now:
1. Checks for `graphify-out/GRAPH_REPORT.md` in Step 2 (artifact scan)
2. Surfaces a `Graph: ✅` line in the orientation brief when present
3. During existing-repo intake (Step 3), suggests `/graphify .` for large/unfamiliar codebases

The `Graph:` line is omitted entirely when `graphify-out/` is absent — no noise for projects that don't use it.

---

## Wiki convention

File `graphify-out/GRAPH_REPORT.md` to `.planning/vision/` after building the graph so it becomes part of the wiki (rather than a parallel knowledge store):

```bash
cp graphify-out/GRAPH_REPORT.md .planning/vision/graphify-report.md
# update .planning/index.md and .planning/log.md
```

session-start's `[auto]` detection checks `graphify-out/GRAPH_REPORT.md` in the project root (not `.planning/`), so the original file location is the signal. Filing to `.planning/vision/` is for durable wiki record.

---

## CLAUDE.md conflict mitigation

`graphify install` appends content to the project's `CLAUDE.md` and installs a PreToolUse hook. Run `install.sh` first, then `graphify install`, so j-stack's lane config takes precedence. The appended graphify content (directing Claude toward graph queries) is additive and does not conflict with j-stack's phase pipeline.

---

## Install

Graphify is not bundled in `install.sh` — it is an optional per-project tool installed when needed:

```bash
/plugin marketplace add DietrichGebert/ponytail   # already done
uv tool install graphifyy                          # graphify CLI
graphify install                                   # wires into current project
```

No changes to `install.sh` required.
