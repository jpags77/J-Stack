# Ponytail Audit Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the three highest-ROI findings from the ponytail-audit: extract 5 embedded skills from install.sh to standalone files, drop the stale global CLAUDE.md installer phase, and convert index.html from React/Babel to vanilla HTML.

**Architecture:** Each fix is independent. Fix 1 (skill extraction) + Fix 2 (phase removal) both touch install.sh and should execute sequentially in one task. Fix 3 (index.html) is fully independent and can run in parallel. A new test file validates the structural invariants after both changes.

**Tech Stack:** bash, python3 (stdlib only, for scripting installs.sh edits), vanilla HTML/CSS/JS (no frameworks)

## Global Constraints

- No new dependencies introduced
- install.sh must remain runnable end-to-end after changes (`set -euo pipefail` still applies)
- index.html must remain a single self-contained file (no build step, no bundler)
- `tests/codex-config.sh`-style assert pattern must be followed for new tests
- `skills/session-start/SKILL.md` in the repo must match the live `~/.claude/skills/session-start/SKILL.md` (the live version is authoritative — it has Iteration Progress reconciliation the embedded version lacks)

---

### Task 1: Extract 5 embedded skills to `skills/` files

**Files:**
- Create: `skills/poc-wiki-init/SKILL.md`
- Create: `skills/handoff-snapshot/SKILL.md`
- Create: `skills/second-opinion/SKILL.md`
- Create: `skills/stakeholder-pack/SKILL.md`
- Create: `skills/session-start/SKILL.md` ← copy from live, NOT from install.sh
- Create: `tests/structure.sh` (new structural test)

**Interfaces:**
- Produces: 5 skill directories under `skills/` matching the `skills/prior-art-survey/` pattern. Task 2 depends on these existing.

- [ ] **Step 1: Write the test first**

Create `tests/structure.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

assert_file() {
  local file="$1"
  [ -f "$file" ] || { echo "missing: ${file}" >&2; exit 1; }
}

assert_contains() {
  local file="$1"
  local pattern="$2"
  grep -Fq "$pattern" "$file" || { echo "missing pattern in ${file}: ${pattern}" >&2; exit 1; }
}

assert_not_contains() {
  local file="$1"
  local pattern="$2"
  ! grep -Fq "$pattern" "$file" || { echo "unexpected pattern in ${file}: ${pattern}" >&2; exit 1; }
}

# ── Skill files must exist ───────────────────────────────────────────────────
for skill in poc-wiki-init handoff-snapshot second-opinion stakeholder-pack session-start prior-art-survey; do
  assert_file "${ROOT}/skills/${skill}/SKILL.md"
  echo "  ✓ skills/${skill}/SKILL.md"
done

# ── Skill files must have frontmatter ───────────────────────────────────────
for skill in poc-wiki-init handoff-snapshot second-opinion stakeholder-pack session-start; do
  assert_contains "${ROOT}/skills/${skill}/SKILL.md" "name: ${skill}"
  echo "  ✓ skills/${skill}/SKILL.md has name: frontmatter"
done

# ── session-start must have Iteration Progress reconciliation (live version) ─
assert_contains "${ROOT}/skills/session-start/SKILL.md" "Iteration Progress"
assert_contains "${ROOT}/skills/session-start/SKILL.md" "[auto]"
echo "  ✓ skills/session-start/SKILL.md is current version (has Iteration Progress)"

# ── install.sh must NOT contain embedded skill heredocs ─────────────────────
assert_not_contains "${ROOT}/install.sh" "install_skill \"poc-wiki-init\""
assert_not_contains "${ROOT}/install.sh" "SKILL_EOF"
echo "  ✓ install.sh has no embedded skill heredocs"

# ── install.sh must use cp -r for custom skills ──────────────────────────────
assert_contains "${ROOT}/install.sh" "CUSTOM_SKILLS="
assert_contains "${ROOT}/install.sh" 'cp -r "$src" "${SKILLS_DIR}/"'
echo "  ✓ install.sh uses cp -r for custom skills"

# ── install.sh must NOT contain Phase 3.5 (GLOBAL_CLAUDE_SECTION) ───────────
assert_not_contains "${ROOT}/install.sh" "Phase 3.5: Global CLAUDE.md"
assert_not_contains "${ROOT}/install.sh" "GLOBAL_CLAUDE_SECTION"
echo "  ✓ install.sh has no Phase 3.5 / GLOBAL_CLAUDE_SECTION"

# ── index.html must NOT load React or Babel from CDN ────────────────────────
assert_not_contains "${ROOT}/index.html" "unpkg.com/react"
assert_not_contains "${ROOT}/index.html" "unpkg.com/@babel"
assert_not_contains "${ROOT}/index.html" "text/babel"
echo "  ✓ index.html loads no React/Babel CDN scripts"

echo ""
echo "All structure checks passed."
```

- [ ] **Step 2: Run test to confirm it fails (all assertions fail)**

```bash
bash tests/structure.sh
```

Expected: multiple failures (skills not created yet, install.sh still has heredocs)

- [ ] **Step 3: Copy the 4 skills from install.sh embedded content**

Run this Python script to extract skill content from install.sh heredocs:

```python
# save as /tmp/extract_skills.py and run: python3 /tmp/extract_skills.py
import os

os.chdir('/Volumes/Home/Users/Documents/Git/j-stack')

with open('install.sh', 'r') as f:
    content = f.read()

for name in ['poc-wiki-init', 'handoff-snapshot', 'second-opinion', 'stakeholder-pack']:
    marker = f"install_skill \"{name}\" <<'SKILL_EOF'\n"
    start = content.index(marker) + len(marker)
    end = content.index('\nSKILL_EOF', start)
    skill_content = content[start:end]
    os.makedirs(f'skills/{name}', exist_ok=True)
    with open(f'skills/{name}/SKILL.md', 'w') as f:
        f.write(skill_content)
    print(f'Created skills/{name}/SKILL.md ({len(skill_content.splitlines())} lines)')
```

- [ ] **Step 4: Copy the live session-start (NOT the embedded version)**

```bash
cp ~/.claude/skills/session-start/SKILL.md /Volumes/Home/Users/Documents/Git/j-stack/skills/session-start/SKILL.md
```

Verify it has the Iteration Progress content (live version):

```bash
grep -c "Iteration Progress\|\[auto\]" /Volumes/Home/Users/Documents/Git/j-stack/skills/session-start/SKILL.md
```

Expected: 2 or more matches. If 0, the wrong file was copied.

- [ ] **Step 5: Run partial test (skill files only)**

```bash
bash tests/structure.sh 2>&1 | head -20
```

Expected: skill file checks pass, install.sh checks still fail (install.sh not yet modified)

- [ ] **Step 6: Commit skill files**

```bash
git add skills/poc-wiki-init skills/handoff-snapshot skills/second-opinion skills/stakeholder-pack skills/session-start tests/structure.sh
git commit -m "feat: extract 5 custom skills from install.sh to skills/ files"
```

---

### Task 2: Shrink install.sh (Phase 2 + Phase 3.5 removal)

**Files:**
- Modify: `install.sh` (Phase 2 heredocs → cp -r loop; Phase 3.5 block removed)

**Interfaces:**
- Consumes: `skills/{poc-wiki-init,handoff-snapshot,second-opinion,stakeholder-pack,session-start}/SKILL.md` from Task 1
- Produces: install.sh that is ~820 lines shorter, Phase 3.5 gone

- [ ] **Step 1: Apply both edits to install.sh with a Python script**

```python
# save as /tmp/fix_install.py and run: python3 /tmp/fix_install.py
import os

os.chdir('/Volumes/Home/Users/Documents/Git/j-stack')

with open('install.sh', 'r') as f:
    content = f.read()

original_lines = len(content.splitlines())

# ── Fix 1: Replace Phase 2 (heredoc block) with cp -r loop ──────────────────
def line_start(text, substr):
    idx = text.index(substr)
    return text.rindex('\n', 0, idx) + 1

p2_start  = line_start(content, 'Phase 2: Custom skills')
p25_start = line_start(content, 'Phase 2.5: Prior-art')

new_phase2 = '''\
# ─── Phase 2: Custom skills ──────────────────────────────────────────────────────────────────────────────

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

'''

content = content[:p2_start] + new_phase2 + content[p25_start:]

# Remove duplicate SCRIPT_DIR now defined in Phase 2
old_dup = 'SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"\nAGENTS_DIR'
if old_dup in content:
    content = content.replace(old_dup, 'AGENTS_DIR', 1)
    print('Removed duplicate SCRIPT_DIR from Phase 2.5')

# ── Fix 2: Remove Phase 3.5 block entirely ───────────────────────────────────
p35_start = line_start(content, 'Phase 3.5: Global CLAUDE.md')
p36_start = line_start(content, 'Phase 3.6: SessionStart hook')
content = content[:p35_start] + content[p36_start:]
print('Removed Phase 3.5 (GLOBAL_CLAUDE_SECTION)')

with open('install.sh', 'w') as f:
    f.write(content)

new_lines = len(content.splitlines())
print(f'install.sh: {original_lines} lines -> {new_lines} lines ({original_lines - new_lines} removed)')
```

Expected output:
```
Removed duplicate SCRIPT_DIR from Phase 2.5
Removed Phase 3.5 (GLOBAL_CLAUDE_SECTION)
install.sh: 1266 lines -> ~430 lines (-836 removed)
```

- [ ] **Step 2: Verify install.sh is still valid bash**

```bash
bash -n install.sh && echo "Syntax OK"
```

Expected: `Syntax OK` (no output means syntax error)

- [ ] **Step 3: Run structure tests**

```bash
bash tests/structure.sh
```

Expected: all skill + install.sh checks pass; index.html checks still fail

- [ ] **Step 4: Run existing codex-config test**

```bash
bash tests/codex-config.sh && echo "codex-config OK"
```

Expected: `codex-config OK`

- [ ] **Step 5: Commit**

```bash
git add install.sh
git commit -m "refactor: extract skills to files, drop stale global CLAUDE.md installer phase"
```

---

### Task 3: Convert index.html from React/Babel to vanilla HTML

**Files:**
- Modify: `index.html` (full rewrite — React/Babel → pure HTML/CSS/JS)

**Interfaces:**
- Produces: `index.html` that passes the CDN checks in `tests/structure.sh`

**Key data to preserve verbatim** (these are rendered by the React components — must appear in final HTML):

```javascript
// SDLC_PHASES — 8 rows, each: { sdlc, stage, skills[], pm, color }
// PIPELINE_STAGES — 8 stages, each: { name, skills[] }
// STACK_LAYERS — 4 rows, each: { layer, badge, badgeColor, tools[] }
// PM_PRINCIPLES — 6 items: [title, body]
// Install command: "git clone https://github.com/jpagano-r7/j-stack.git\ncd j-stack\nbash install.sh"
```

**Interactive elements to preserve:**
- Nav: fixed position, gains backdrop-blur + border on scroll (JS scroll listener)
- Pipeline stages: each `.stage` box changes border color + background on `:hover` (CSS only)
- SDLC table rows: highlight on `:hover` (CSS only)
- Install copy button: copies 3-line command to clipboard (`navigator.clipboard.writeText`)
- TweaksPanel: **DELETE** — dead code (density preference was never wired)

**What to remove:**
- `<script src="unpkg.com/react...">` (all 3 CDN scripts)
- `<script type="text/babel">` block (entire React component tree)
- `TWEAK_DEFAULTS`, `TweaksPanel` component, edit-mode `postMessage` hooks
- `<div id="root"></div>` (replaced with actual HTML)

**HTML structure to produce:**

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>j-stack · Claude Code for Enterprise PoC</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=DM+Sans:ital,wght@0,300;0,400;0,500;0,600;1,400&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet">
  <style>
    /* All existing CSS variables and base styles preserved as-is */
    /* Add: nav.scrolled { backdrop-filter: blur(12px); ... } */
    /* Add: .stage:hover, .sdlc-row:hover for CSS-only hover effects */
  </style>
</head>
<body>
  <nav id="nav">...</nav>
  <main>
    <section id="hero">...</section>
    <section id="why">...</section>   <!-- BuildingBlocks -->
    <section id="what">...</section>  <!-- WhatItIs -->
    <section id="sdlc">...</section>  <!-- SDLCCoverage -->
    <section id="spec">...</section>  <!-- SpecDriven -->
    <section id="pipeline">...</section>
    <section id="stack">...</section> <!-- StackLayers -->
    <section id="memory">...</section>
    <section id="install">...</section>
  </main>
  <footer>...</footer>
  <script>
    // Nav scroll effect (~5 lines)
    // Copy button handler (~5 lines)
  </script>
</body>
</html>
```

- [ ] **Step 1: Rewrite index.html**

Open `index.html`. Starting from the existing `<style>` block (keep it verbatim), render each section as static HTML. Translate each React component to a `<section>` with equivalent markup. Key rules:

- CSS variables (`var(--indigo)`, etc.) stay in `<style>` — no change
- Google Fonts `<link>` stays
- `Mono` component → `<span class="mono">` (add `.mono { font-family: 'DM Mono', monospace; }`)
- `Label` component → `<div class="label">` (add `.label { font-size: 11px; font-weight: 600; letter-spacing: 0.08em; text-transform: uppercase; color: var(--text-dimmer); }`)
- `Card` component → `<div class="card">` (add `.card { background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius); overflow: hidden; }`)
- `SectionDivider` component → `<div class="section-divider"><div class="label">LABEL</div><div class="divider-line"></div></div>`
- Pipeline stage hover: add `.stage:hover { background: var(--surface2); }` + inline `border-color` via CSS variable override
- SDLC row hover: `.sdlc-row:hover { background: var(--surface2); }`
- Nav scroll: add `<script>` at bottom with `window.addEventListener('scroll', () => { document.getElementById('nav').classList.toggle('scrolled', window.scrollY > 20); })`
- Copy button: `<button onclick="copyInstall(this)">copy</button>` + `function copyInstall(btn) { navigator.clipboard.writeText('git clone ...\ncd j-stack\nbash install.sh').catch(()=>{}); btn.textContent='✓ copied'; setTimeout(()=>btn.textContent='copy', 2000); }`
- Delete everything related to TweaksPanel, TWEAK_DEFAULTS, edit mode postMessage

- [ ] **Step 2: Verify index.html has no React/Babel**

```bash
grep -c "unpkg.com/react\|unpkg.com/@babel\|text/babel" index.html
```

Expected: `0`

- [ ] **Step 3: Run structure tests**

```bash
bash tests/structure.sh
```

Expected: ALL checks pass

- [ ] **Step 4: Open in browser and verify visually**

```bash
open index.html
```

Check:
- Nav links scroll to correct sections
- Pipeline stages highlight on hover
- SDLC table rows highlight on hover
- Copy button changes to "✓ copied" on click and resets after 2s
- No JS errors in browser console

- [ ] **Step 5: Commit**

```bash
git add index.html
git commit -m "refactor: replace React/Babel SPA with vanilla HTML — removes 1.3MB CDN deps"
```

---

### Task 4: Update wiki and log

**Files:**
- Modify: `.planning/index.md`
- Modify: `.planning/log.md`

- [ ] **Step 1: Update index.md**

In `.planning/index.md`, update the `## plans/` section:
```markdown
## plans/
- [2026-06-17-ponytail-fixes.md](plans/2026-06-17-ponytail-fixes.md) — ponytail audit fixes: skill extraction, install.sh shrink, vanilla HTML
```

- [ ] **Step 2: Update log.md**

Append to `.planning/log.md`:
```
## [2026-06-17 01:00] implementation | ponytail-fixes — 3 fixes: skills→files (-730 lines install.sh), Phase 3.5 dropped (-77 lines), index.html React→vanilla HTML (-1MB CDN)
```

- [ ] **Step 3: Commit**

```bash
git add .planning/
git commit -m "docs: record ponytail-fixes implementation in wiki"
```
