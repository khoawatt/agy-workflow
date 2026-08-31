#!/usr/bin/env bash
# ============================================================================
# Install agy-workflow project-scoped configuration into a target repository.
#
#   bash install-project.sh /path/to/repo
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

# Install .agents skills & scripts
copy_if_absent "$TEMPLATES/merge-approved-pr.sh" "$TARGET/.agents/scripts/merge-approved-pr.sh" 755
copy_if_absent "$REPO_DIR/skills/chatgpt-review/SKILL.md" "$TARGET/.agents/skills/chatgpt-review/SKILL.md"
copy_if_absent "$REPO_DIR/skills/gemini-review/SKILL.md" "$TARGET/.agents/skills/gemini-review/SKILL.md"
copy_if_absent "$REPO_DIR/skills/autoreview/SKILL.md" "$TARGET/.agents/skills/autoreview/SKILL.md"
copy_if_absent "$REPO_DIR/skills/chatgpt-project/SKILL.md" "$TARGET/.agents/skills/chatgpt-project/SKILL.md"
copy_if_absent "$REPO_DIR/skills/chatgpt-new/SKILL.md" "$TARGET/.agents/skills/chatgpt-new/SKILL.md"
copy_if_absent "$REPO_DIR/skills/gemini-new/SKILL.md" "$TARGET/.agents/skills/gemini-new/SKILL.md"

# Install hooks (for auto-review context injection)
copy_if_absent "$REPO_DIR/hooks/autoreview_prompt.sh" "$TARGET/.agents/hooks/autoreview_prompt.sh" 755
copy_if_absent "$REPO_DIR/hooks.json" "$TARGET/.agents/hooks.json"

# Append or create AGENTS.md / GEMINI.md collaboration section
AGENTS="$TARGET/AGENTS.md"
if [ -f "$AGENTS" ]; then
  if grep -q "ChatGPT–Antigravity Collaboration\|ChatGPT review bridge" "$AGENTS"; then
    warn "AGENTS.md already has collaboration section; skipping"
  else
    { printf '\n'; cat "$TEMPLATES/AGENTS.collaboration.md"; } >> "$AGENTS"
    log "appended collaboration section to AGENTS.md"
  fi
else
  cp "$TEMPLATES/AGENTS.collaboration.md" "$AGENTS"
  log "created AGENTS.md (collaboration section)"
fi

echo
log "Done. Antigravity will automatically discover .agents/ in $TARGET."
