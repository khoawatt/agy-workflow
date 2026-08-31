#!/usr/bin/env bash
# ============================================================================
# Install agy-workflow project-scoped configuration into a target repository.
#
#   bash install-project.sh /path/to/repo
#
# Copies (NEVER overwrites) the canonical policy and .agents resources from
# this template repo into the target. Existing files are left untouched and
# reported so the caller can merge manually.
# ============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES="$REPO_DIR/templates"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { printf "${GREEN}==>${NC} %s\n" "$*"; }
warn() { printf "${YELLOW}!! %s${NC}\n" "$*"; }
die()  { printf "${RED}ERROR: %s${NC}\n" "$*"; exit 1; }

TARGET="${1:-}"
[ -n "$TARGET" ] || die "usage: bash install-project.sh <repo-path>"
[ -d "$TARGET" ] || die "not a directory: $TARGET"
[ -d "$TARGET/.git" ] || warn "target does not look like a git repo (no .git) — continuing anyway"

TARGET="$(cd "$TARGET" && pwd)"

# copy_if_absent <src> <dst> [mode]
copy_if_absent() {
  local src="$1" dst="$2" mode="${3:-644}"
  if [ -e "$dst" ]; then
    warn "exists, skipping (merge manually): $dst"
  else
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    chmod "$mode" "$dst"
    log "created: $dst"
  fi
}

log "Installing agy-workflow project config into $TARGET"

# --- .agents resources (vision + merge wrapper) ---
copy_if_absent "$TEMPLATES/vision.md"                        "$TARGET/.agents/agents/vision.md"
[ -f "$TEMPLATES/opencode.jsonc" ] && copy_if_absent "$TEMPLATES/opencode.jsonc" "$TARGET/opencode.jsonc"
copy_if_absent "$TEMPLATES/merge-approved-pr.sh"             "$TARGET/.agents/scripts/merge-approved-pr.sh" 755

# --- .agents skills (mirrors opencode's .opencode/skills) ---
copy_if_absent "$REPO_DIR/skills/chatgpt-review/SKILL.md"    "$TARGET/.agents/skills/chatgpt-review/SKILL.md"
copy_if_absent "$REPO_DIR/skills/gemini-review/SKILL.md"     "$TARGET/.agents/skills/gemini-review/SKILL.md"
copy_if_absent "$REPO_DIR/skills/autoreview/SKILL.md"        "$TARGET/.agents/skills/autoreview/SKILL.md"
copy_if_absent "$REPO_DIR/skills/chatgpt-project/SKILL.md"   "$TARGET/.agents/skills/chatgpt-project/SKILL.md"
copy_if_absent "$REPO_DIR/skills/chatgpt-new/SKILL.md"       "$TARGET/.agents/skills/chatgpt-new/SKILL.md"
copy_if_absent "$REPO_DIR/skills/gemini-new/SKILL.md"        "$TARGET/.agents/skills/gemini-new/SKILL.md"

# Install hooks (for auto-review context injection)
copy_if_absent "$REPO_DIR/hooks/autoreview_prompt.sh"        "$TARGET/.agents/hooks/autoreview_prompt.sh" 755
copy_if_absent "$REPO_DIR/hooks.json"                        "$TARGET/.agents/hooks.json"

# --- Sources sync (hybrid .git + metadata, retention 1) — ported from opencode-workflow ---
copy_if_absent "$REPO_DIR/bin/chatgpt-sources-sync.mjs"      "$TARGET/bin/chatgpt-sources-sync.mjs" 755
copy_if_absent "$REPO_DIR/bin/sources"                       "$TARGET/bin/sources" 755
[ -f "$TARGET/bin/sources" ] && ln -sfn sources "$TARGET/bin/chatgpt-sources" 2>/dev/null || true

# --- .gitignore for Sources sync (hybrid, retention 1) ---
GITIGNORE="$TARGET/.gitignore"
if [ -f "$GITIGNORE" ]; then
  if ! grep -q "ChatGPT Sources sync" "$GITIGNORE"; then
    {
      printf '\n# ChatGPT Sources sync artifacts — repo snapshots for Project Sources (local only, contains .git + metadata)\n'
      printf '# Narrow pattern: only root probe zips, not all *.zip in subdirs\n'
      printf '/*_probe_*.zip\n'
      printf '/agy-workflow_*.zip\n'
      printf '/opencode-workflow_*.zip\n'
      printf '/*_probe_*.md\n'
      printf '.chatgpt-sources/\n'
      printf '.sources-tracking.json\n'
      printf 'tracking-last-version.json\n'
    } >> "$GITIGNORE"
    log "appended Sources sync ignore patterns to .gitignore"
  else
    warn ".gitignore already has Sources sync patterns; skipping"
  fi
else
  {
    printf '# ChatGPT Sources sync artifacts — repo snapshots for Project Sources (local only, contains .git + metadata)\n'
    printf '/*_probe_*.zip\n'
    printf '.chatgpt-sources/\n'
    printf 'tracking-last-version.json\n'
  } > "$GITIGNORE"
  log "created .gitignore with Sources sync patterns"
fi

# --- AGENTS.md collaboration section ---
# Never overwrite AGENTS.md; append the collaboration section only if the marker
# is absent. If present, do nothing (it is already integrated).
# Port timestamp backup from opencode-workflow/install-project.sh for safety.
AGENTS="$TARGET/AGENTS.md"
if [ -f "$AGENTS" ]; then
  if grep -q "ChatGPT–Antigravity Collaboration\|ChatGPT review bridge" "$AGENTS"; then
    warn "AGENTS.md already has collaboration section; skipping"
  else
    backup="$(mktemp "$AGENTS.backup.$(date +%Y%m%d%H%M%S).XXXXXX")"
    cp -p -- "$AGENTS" "$backup"
    log "Backed up AGENTS.md: $backup"
    { printf '\n'; cat "$TEMPLATES/AGENTS.collaboration.md"; } >> "$AGENTS"
    log "appended collaboration section to AGENTS.md"
  fi
else
  cp "$TEMPLATES/AGENTS.collaboration.md" "$AGENTS"
  log "created AGENTS.md (collaboration section)"
fi

echo
log "Done. Antigravity will automatically discover .agents/ in $TARGET."
log "If using Sources sync, run: $TARGET/bin/sources status"
