# Headroom Integration

## What it is

[Headroom](https://github.com/headroom-ai/headroom) is an MCP server that compresses
large content into a compact representation and returns a hash for later retrieval.
It is already installed and initialized via a Bash hook in `.claude/settings.local.json`.

## Token impact

Compression eliminates the cost of holding large tool outputs in the active context
window. The retrieve step is only needed when a specific detail is required — most
reasoning only needs the compressed summary.

## Integration levels

### Global (all projects)

Added to `~/.claude/CLAUDE.md`: compress large tool output before reasoning over it.

Triggers:
- `Read` result over ~150 lines not needed in full
- Long `Bash` output (grep dumps, find trees, git log)
- `WebFetch` result before analysis
- Multiple large inputs before synthesis

### j-stack pipeline (specific checkpoints)

Added to `.planning/CLAUDE.md`: four named pipeline moments.

| Moment | What to compress |
|--------|-----------------|
| session-start | `index.md`, `log.md`, handoff files |
| prior-art-survey | Each scout's output before cross-scout synthesis |
| BUILD subagent returns | Subagent transcript before parent context ingestion |
| SURVEY/BUILD file reads | Any file >~150 lines read for orientation only |

## What was skipped

Automatic compression (hook-based, on every Read/Bash) — headroom's init hook already
runs; adding auto-compression would compress small outputs where it adds latency with
no benefit. Manual-at-checkpoint discipline is sufficient.
