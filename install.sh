#!/usr/bin/env bash
# j-stack install script
# Sets up the Claude Code enterprise PoC stack:
#   Superpowers + cherry-picked gstack skills + 5 custom skills + prior-art bundle
#   + CLAUDE.md lane config + SessionStart hook
#
# Usage: bash install.sh [--skip-codex] [--skip-verify]

set -euo pipefail

SKIP_CODEX=false
SKIP_VERIFY=false
for arg in "$@"; do
  case $arg in
    --skip-codex)  SKIP_CODEX=true ;;
    --skip-verify) SKIP_VERIFY=true ;;
  esac
done

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; NC='\033[0m'
info()  { echo -e "${GREEN}[j-stack]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*" >&2; }
halt()  { error "$*"; exit 1; }

SKILLS_DIR="${HOME}/.claude/skills"

# ─── Phase 0: Prerequisites ───────────────────────────────────────────────────

info "Checking prerequisites…"

command -v claude &>/dev/null || halt "claude not found. Install Claude Code first: https://claude.ai/code"
command -v git    &>/dev/null || halt "git not found."
command -v bash   &>/dev/null || halt "bash not found."

# Check Superpowers plugin
if ! claude --help 2>/dev/null | grep -q "superpowers\|brainstorm"; then
  warn "Superpowers plugin not detected in 'claude --help' output."
  warn "Install it inside Claude Code with:"
  warn "  /plugin marketplace add obra/superpowers-marketplace"
  warn "  /plugin install superpowers@superpowers-marketplace"
  read -rp "Continue anyway? [y/N] " yn
  [[ $yn =~ ^[Yy]$ ]] || halt "Aborted. Install Superpowers first."
fi

# prior-art survey skill + scout agents are bundled in this repo — installed in Phase 2.5 below

# ─── Phase 0.5: Codex CLI ─────────────────────────────────────────────────────

if [ "$SKIP_CODEX" = false ]; then
  info "Phase 0 — Codex CLI setup…"
  if command -v codex &>/dev/null; then
    CODEX_VER=$(codex --version 2>/dev/null || echo "unknown")
    info "Codex CLI already installed: ${CODEX_VER}"
  else
    warn "Codex CLI not found."
    warn "The second-opinion skill requires it. Install it per current OpenAI docs:"
    warn "  https://github.com/openai/codex  (verify current install method)"
    warn "Typical install: npm install -g @openai/codex"
    read -rp "Skip Codex CLI setup and continue? [y/N] " yn
    [[ $yn =~ ^[Yy]$ ]] || halt "Aborted. Install Codex CLI, then re-run install.sh."
  fi
fi

# ─── Phase 1: Cherry-pick gstack skills ───────────────────────────────────────

info "Phase 1 — Cherry-picking gstack skills…"

GSTACK_SCRATCH="/tmp/gstack-source"

if [ -d "$GSTACK_SCRATCH" ]; then
  info "Updating existing gstack clone at ${GSTACK_SCRATCH}…"
  git -C "$GSTACK_SCRATCH" pull --ff-only 2>/dev/null || true
else
  info "Cloning gstack to ${GSTACK_SCRATCH}…"
  git clone --depth 1 https://github.com/garrytan/gstack.git "$GSTACK_SCRATCH"
fi

GSTACK_SKILLS=(cso office-hours plan-ceo-review qa design-shotgun design-html design-review codex document-release freeze guard)

missing=()
for skill in "${GSTACK_SKILLS[@]}"; do
  [ -d "${GSTACK_SCRATCH}/${skill}" ] || missing+=("$skill")
done
if [ ${#missing[@]} -gt 0 ]; then
  halt "Missing gstack skill folders: ${missing[*]}. gstack repo may have changed. Check and update install.sh."
fi

mkdir -p "$SKILLS_DIR"

get_gstack_model() {
  case "$1" in
    cso)             echo opus ;;
    office-hours)    echo opus ;;
    plan-ceo-review) echo opus ;;
    qa)              echo sonnet ;;
    design-shotgun)  echo sonnet ;;
    design-html)     echo sonnet ;;
    design-review)   echo sonnet ;;
    codex)           echo sonnet ;;
    document-release) echo sonnet ;;
    freeze)          echo haiku ;;
    guard)           echo haiku ;;
    *)               echo sonnet ;;
  esac
}

for skill in "${GSTACK_SKILLS[@]}"; do
  dest="${SKILLS_DIR}/${skill}"
  cp -r "${GSTACK_SCRATCH}/${skill}" "${SKILLS_DIR}/"
  model="$(get_gstack_model "$skill")"

  # Find the main skill entry file
  entry=""
  for candidate in "${dest}/SKILL.md" "${dest}/skill.md" "${dest}/README.md"; do
    [ -f "$candidate" ] && entry="$candidate" && break
  done

  if [ -z "$entry" ]; then
    warn "Could not find entry file for gstack/${skill} — skipping model injection"
    continue
  fi

  # Inject model: directive into YAML frontmatter if not already present
  if head -1 "$entry" | grep -q "^---"; then
    if ! grep -q "^model:" "$entry"; then
      # Insert after opening ---
      sed -i.bak "1a\\
model: ${model}" "$entry"
      rm -f "${entry}.bak"
    fi
  else
    # No frontmatter — prepend it
    tmpfile=$(mktemp)
    printf -- "---\nmodel: %s\n---\n" "$model" | cat - "$entry" > "$tmpfile"
    mv "$tmpfile" "$entry"
  fi

  info "  Installed gstack/${skill} (model: ${model})"
done

# ─── Phase 2: Custom skills ────────────────────────────────────────────────────────────────────────────

info "Phase 2 — Installing custom skills…"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CUSTOM_SKILLS=(poc-wiki-init handoff-snapshot second-opinion stakeholder-pack session-start)

for skill in "${CUSTOM_SKILLS[@]}"; do
  src="${SCRIPT_DIR}/skills/${skill}"
  if [ ! -d "$src" ]; then
    halt "Expected skills/${skill}/ not found in repo. Clone may be incomplete."
  fi
  cp -r "$src" "${SKILLS_DIR}/"
  info "  Installed custom skill: ${skill}"
done

# ─── Phase 2.5: Prior-art research skill + scout agents ───────────────────────

info "Phase 2.5 — Installing prior-art survey skill and scout agents…"

AGENTS_DIR="${HOME}/.claude/agents"

src="${SCRIPT_DIR}/skills/prior-art-survey"
if [ ! -d "$src" ]; then
  halt "Expected skills/prior-art-survey/ not found in repo. Clone may be incomplete."
fi
cp -r "$src" "${SKILLS_DIR}/"
info "  Installed skill: prior-art-survey"

# Scouts are agent definitions, not skills — the Agent tool honors their
# model: sonnet frontmatter, so research runs in the sonnet lane even when
# the orchestrating session is on opus.
mkdir -p "$AGENTS_DIR"
PRIOR_ART_AGENTS=(prior-art-oss-scout prior-art-library-scout prior-art-patterns-scout)

for agent in "${PRIOR_ART_AGENTS[@]}"; do
  src="${SCRIPT_DIR}/agents/${agent}.md"
  if [ ! -f "$src" ]; then
    halt "Expected agents/${agent}.md not found in repo. Clone may be incomplete."
  fi
  cp "$src" "${AGENTS_DIR}/"
  # Remove stale skill-form scout from older installs
  rm -rf "${SKILLS_DIR:?}/${agent}"
  info "  Installed agent: ${agent} (model: sonnet)"
done

# ─── Phase 3: CLAUDE.md configuration ────────────────────────────────────────

info "Phase 3 — Configuring project CLAUDE.md…"

CLAUDE_SECTION='
## Stack ownership (skill lane management)

Multiple skill packs are installed. Each owns a specific phase of the workflow:

- **Front-end scoping (Expand phase):** /office-hours, /plan-ceo-review (gstack)
- **Refining (Refine phase):** Superpowers brainstorming
- **Prior art (Survey phase):** prior-art-survey (custom)
- **Planning (Plan phase):** Superpowers writing-plans
- **Building (Build phase):** Superpowers subagent-driven-development, with /design-shotgun + /design-html for UI work
- **Polishing (Polish phase):** /qa, /design-review, /cso (gstack)
- **Defending (Defend phase):** second-opinion, stakeholder-pack (custom)
- **Handoff:** /document-release (gstack), handoff-snapshot (custom)

Run them in order. Do NOT use gstack'"'"'s /autoplan or /plan-eng-review — they overlap Superpowers'"'"' planning lane and create conflicts.

## Wiki

This project'"'"'s source of truth lives at `.planning/`. Read `.planning/index.md` before any non-trivial work. Check `.planning/handoffs/` for the most recent snapshot — another tool may have left state for you to resume from.

## Cross-tool

When usage limits hit, run `handoff-snapshot` and resume in Codex / Cursor / ChatGPT / Gemini. Each has its own schema file in `.planning/`.

## Work checkpoints

After significant code interactions, create a durable checkpoint before switching tasks: commit the coherent git diff, update `.planning/` with notable decisions or review output, append `.planning/log.md`, and run `handoff-snapshot`. Do not push to GitHub automatically; push only when the user asks or an explicit publish workflow is active.
'

PROJECT_CLAUDE="${PWD}/CLAUDE.md"
if [ -f "$PROJECT_CLAUDE" ]; then
  if grep -q "Stack ownership" "$PROJECT_CLAUDE"; then
    info "  CLAUDE.md already contains stack ownership section — skipping"
  else
    printf '\n# Project Context\n%s' "$CLAUDE_SECTION" >> "$PROJECT_CLAUDE"
    info "  Appended stack ownership section to existing CLAUDE.md"
  fi
else
  printf '# Project Context\n%s' "$CLAUDE_SECTION" > "$PROJECT_CLAUDE"
  info "  Created CLAUDE.md with stack ownership section"
fi

# ─── Phase 3.25: AGENTS.md configuration ──────────────────────────────────────

info "Phase 3.25 — Configuring project AGENTS.md…"

AGENTS_SECTION='
## Stack ownership (skill lane management)

Multiple skill packs are installed. Each owns a specific phase of the workflow:

- **Front-end scoping (Expand phase):** /office-hours, /plan-ceo-review (gstack)
- **Refining (Refine phase):** Superpowers brainstorming
- **Prior art (Survey phase):** prior-art-survey (custom)
- **Planning (Plan phase):** Superpowers writing-plans
- **Building (Build phase):** Superpowers subagent-driven-development, with /design-shotgun + /design-html for UI work
- **Polishing (Polish phase):** /qa, /design-review, /cso (gstack)
- **Defending (Defend phase):** second-opinion, stakeholder-pack (custom)
- **Handoff:** /document-release (gstack), handoff-snapshot (custom)

Run them in order. Do NOT use gstack'"'"'s /autoplan or /plan-eng-review — they overlap Superpowers'"'"' planning lane and create conflicts.

## Wiki

This project'"'"'s source of truth lives at `.planning/`. Read `.planning/index.md` before any non-trivial work. Check `.planning/handoffs/` for the most recent snapshot — another tool may have left state for you to resume from.

## Cross-tool

When usage limits hit, run `handoff-snapshot` and resume in Codex / Cursor / ChatGPT / Gemini. Each has its own schema file in `.planning/`.

## Work checkpoints

After significant code interactions, create a durable checkpoint before switching tasks: commit the coherent git diff, update `.planning/` with notable decisions or review output, append `.planning/log.md`, and run `handoff-snapshot`. Do not push to GitHub automatically; push only when the user asks or an explicit publish workflow is active.

## Codex role

Codex is a first-class j-stack runtime with two primary operating modes:

- **Fallback mode:** Claude Code hits usage limits or the user deliberately switches tools. Resume from `.planning/index.md`, the latest `.planning/handoffs/` snapshot, and `.planning/log.md`.
- **Review mode:** Claude invokes Codex for an independent `second-opinion` review. Inspect only the requested artifact unless the prompt asks for broader repo context, and return findings suitable for filing under `.planning/reviews/`.

In both modes, keep `.planning/` as the durable source of truth. Notable analysis, decisions, reviews, and handoff state should be written into the appropriate `.planning/` section and logged in `.planning/log.md`.

## Claude skill mapping for Codex

Claude slash commands and skills are the source names for the process. In Codex, follow the same lane semantics even when the command itself is not available:

| Claude surface | Codex behavior |
| --- | --- |
| `/office-hours`, `/plan-ceo-review` | Run EXPAND as a problem/scope challenge before design work. |
| `superpowers:brainstorming` | Refine requirements and approaches before planning or code edits. |
| `prior-art-survey` | Use the bundled prior-art skill files and web/package research where available. |
| `superpowers:writing-plans` | Produce or follow a locked implementation plan before BUILD work. |
| `superpowers:subagent-driven-development` | Keep implementation scoped, isolated, test-driven, and spec-bound. |
| `/qa`, `/design-review`, `/cso` | Treat POLISH as verification, UX review, and security/risk review. |
| `second-opinion` | Usually means Codex is the independent reviewer; produce review artifacts, not edits. |
| `handoff-snapshot` | Write a timestamped `.planning/handoffs/` blackboard snapshot before switching tools, pausing, or checkpointing significant work. |
'

AGENTS_CODEX_APPEND='
## Work checkpoints

After significant code interactions, create a durable checkpoint before switching tasks: commit the coherent git diff, update `.planning/` with notable decisions or review output, append `.planning/log.md`, and run `handoff-snapshot`. Do not push to GitHub automatically; push only when the user asks or an explicit publish workflow is active.

## Codex role

Codex is a first-class j-stack runtime with two primary operating modes:

- **Fallback mode:** Claude Code hits usage limits or the user deliberately switches tools. Resume from `.planning/index.md`, the latest `.planning/handoffs/` snapshot, and `.planning/log.md`.
- **Review mode:** Claude invokes Codex for an independent `second-opinion` review. Inspect only the requested artifact unless the prompt asks for broader repo context, and return findings suitable for filing under `.planning/reviews/`.

In both modes, keep `.planning/` as the durable source of truth. Notable analysis, decisions, reviews, and handoff state should be written into the appropriate `.planning/` section and logged in `.planning/log.md`.

## Claude skill mapping for Codex

Claude slash commands and skills are the source names for the process. In Codex, follow the same lane semantics even when the command itself is not available:

| Claude surface | Codex behavior |
| --- | --- |
| `/office-hours`, `/plan-ceo-review` | Run EXPAND as a problem/scope challenge before design work. |
| `superpowers:brainstorming` | Refine requirements and approaches before planning or code edits. |
| `prior-art-survey` | Use the bundled prior-art skill files and web/package research where available. |
| `superpowers:writing-plans` | Produce or follow a locked implementation plan before BUILD work. |
| `superpowers:subagent-driven-development` | Keep implementation scoped, isolated, test-driven, and spec-bound. |
| `/qa`, `/design-review`, `/cso` | Treat POLISH as verification, UX review, and security/risk review. |
| `second-opinion` | Usually means Codex is the independent reviewer; produce review artifacts, not edits. |
| `handoff-snapshot` | Write a timestamped `.planning/handoffs/` blackboard snapshot before switching tools, pausing, or checkpointing significant work. |
'

PROJECT_AGENTS="${PWD}/AGENTS.md"
if [ -f "$PROJECT_AGENTS" ]; then
  if grep -q "Codex role" "$PROJECT_AGENTS"; then
    info "  AGENTS.md already contains Codex lane configuration — skipping"
  elif grep -q "Stack ownership" "$PROJECT_AGENTS"; then
    printf '\n%s' "$AGENTS_CODEX_APPEND" >> "$PROJECT_AGENTS"
    info "  Appended Codex lane configuration to existing AGENTS.md"
  else
    printf '\n# Project Context\n%s' "$AGENTS_SECTION" >> "$PROJECT_AGENTS"
    info "  Appended j-stack section to existing AGENTS.md"
  fi
else
  printf '# Project Context\n%s' "$AGENTS_SECTION" > "$PROJECT_AGENTS"
  info "  Created AGENTS.md with Codex lane configuration"
fi

# ─── Phase 3.6: SessionStart hook ─────────────────────────────────────────────

info "Phase 3.6 — Installing SessionStart hook…"

SETTINGS_JSON="${HOME}/.claude/settings.json"
HOOK_MARKER="MANDATORY j-stack"

write_session_hook() {
  python3 - "$SETTINGS_JSON" <<'PYEOF'
import json, os, sys

path = sys.argv[1]
marker = "MANDATORY j-stack"
command = (
    "echo '{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\","
    "\"additionalContext\":\"MANDATORY j-stack: Invoke the session-start skill "
    "immediately before any development work (coding, planning, design, or file "
    "changes). Skip only for pure Q&A that produces no artifacts. Do not wait for "
    "user instruction — run it now.\"}}'"
)
entry = {"hooks": [{"type": "command", "command": command,
                    "statusMessage": "Loading j-stack session context..."}]}

data = {}
if os.path.exists(path):
    try:
        with open(path) as f:
            data = json.load(f)
    except Exception:
        print("PARSE_ERROR")
        sys.exit(3)

hooks = data.setdefault("hooks", {})
sessions = hooks.setdefault("SessionStart", [])
if marker in json.dumps(sessions):
    print("ALREADY")
    sys.exit(0)
sessions.append(entry)
os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
print("WROTE")
PYEOF
}

if grep -q "$HOOK_MARKER" "$SETTINGS_JSON" 2>/dev/null; then
  info "  SessionStart hook already present — skipping"
elif command -v python3 &>/dev/null; then
  result="$(write_session_hook)"
  case "$result" in
    WROTE)   info "  ✓ SessionStart hook written to ${SETTINGS_JSON}" ;;
    ALREADY) info "  SessionStart hook already present — skipping" ;;
    *)
      warn "  Could not auto-merge ${SETTINGS_JSON} (invalid JSON or write error)."
      warn "  Add the SessionStart hook manually — see README 'Manual hook setup'."
      ;;
  esac
else
  warn "  python3 not found — cannot safely merge ${SETTINGS_JSON}."
  warn "  Add the SessionStart hook manually — see README 'Manual hook setup'."
fi

# ─── Phase 4: Verification ────────────────────────────────────────────────────

if [ "$SKIP_VERIFY" = false ]; then
  info "Phase 4 — Verification…"

  all_ok=true

  # Check all skills exist
  ALL_SKILLS=("${GSTACK_SKILLS[@]}" poc-wiki-init handoff-snapshot second-opinion stakeholder-pack session-start prior-art-survey)
  for skill in "${ALL_SKILLS[@]}"; do
    if [ -d "${SKILLS_DIR}/${skill}" ]; then
      info "  ✓ ${skill}"
    else
      error "  ✗ ${skill} — missing from ${SKILLS_DIR}"
      all_ok=false
    fi
  done

  # Check scout agent definitions exist
  for agent in "${PRIOR_ART_AGENTS[@]}"; do
    if [ -f "${AGENTS_DIR}/${agent}.md" ]; then
      info "  ✓ agent: ${agent}"
    else
      error "  ✗ agent: ${agent} — missing from ${AGENTS_DIR}"
      all_ok=false
    fi
  done

  # Check codex if not skipped
  if [ "$SKIP_CODEX" = false ]; then
    if command -v codex &>/dev/null; then
      info "  ✓ codex CLI"
    else
      warn "  ✗ codex CLI not found — second-opinion skill will not work until installed"
    fi
  fi

  if [ "$all_ok" = true ]; then
    info "All checks passed."
  else
    error "Some checks failed. See above."
    exit 1
  fi
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN} j-stack installation complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Next steps:"
echo "  1. Open a new Claude Code session in your project directory"
echo "  2. session-start fires automatically (SessionStart hook) — it orients,"
echo "     or bootstraps the .planning/ wiki on first run for this project"
echo "  3. It dispatches to /office-hours to begin EXPAND (founder-lens scoping)"
echo "  4. Follow the pipeline in ~/.claude/CLAUDE.md"
echo ""
echo "Each session: session-start → confirm fidelity → confirm phase → do work → handoff-snapshot (if switching tools)"
echo "Pipeline:     EXPAND → REFINE → SURVEY → PLAN → BUILD → POLISH → DEFEND → HANDOFF"
echo ""
