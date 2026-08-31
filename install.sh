#!/usr/bin/env bash
# ============================================================================
# Install the ChatGPT Review bridge + Gemini review bridge for Antigravity (AGY)
#
#   bash install.sh            full setup (config + npm deps + chromium + skills)
#   bash install.sh --config   only copy AGY skills / scripts / commands
#   bash install.sh --deps     only install node deps + chromium + system libs
# ============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG_GEMINI="$HOME/.gemini/config"
BRIDGE="$HOME/.gemini/chatgpt-bridge"
GEMINI="$HOME/.gemini/gemini-bridge"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { printf "${GREEN}==>${NC} %s\n" "$*"; }
warn() { printf "${YELLOW}!! %s${NC}\n" "$*"; }
die()  { printf "${RED}ERROR: %s${NC}\n" "$*"; exit 1; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || die "missing command: $1"; }

MODE="${1:-full}"

setup_config() {
  log "Setting up Antigravity configuration in $CFG_GEMINI"
  mkdir -p "$CFG_GEMINI/skills" "$BRIDGE/bin" "$GEMINI/bin" "$HOME/.local/bin"

  # Copy skills to global config so they are discoverable across all AGY workspaces
  cp -R "$REPO_DIR/skills/"* "$CFG_GEMINI/skills/"

  # Bridge binaries + package manifest + default config
  cp "$REPO_DIR/bin/chatgpt-review.mjs" "$REPO_DIR/bin/chatgpt-review" "$REPO_DIR/bin/autoreview" "$BRIDGE/bin/"
  cp "$REPO_DIR/package.json" "$BRIDGE/"
  [ -f "$BRIDGE/bridge-config.json" ] || cp "$REPO_DIR/bridge-config.json" "$BRIDGE/"

  # Gemini bridge
  cp "$REPO_DIR/bin/gemini-review.mjs" "$REPO_DIR/bin/gemini-review" "$GEMINI/bin/"
  cp "$REPO_DIR/package.json" "$GEMINI/"
  [ -f "$GEMINI/bridge-config.json" ] || printf '{ "max_chars": 400000, "max_turns": 40, "max_age_hours": 48 }\n' > "$GEMINI/bridge-config.json"

  # Make scripts executable
  chmod +x "$BRIDGE/bin/chatgpt-review" "$BRIDGE/bin/chatgpt-review.mjs" "$BRIDGE/bin/autoreview"
  chmod +x "$GEMINI/bin/gemini-review" "$GEMINI/bin/gemini-review.mjs"

  # Symlink to ~/.local/bin so PATH finds them immediately
  ln -sfn "$BRIDGE/bin/chatgpt-review" "$HOME/.local/bin/chatgpt-review"
  ln -sfn "$BRIDGE/bin/autoreview" "$HOME/.local/bin/autoreview"
  ln -sfn "$GEMINI/bin/gemini-review" "$HOME/.local/bin/gemini-review"
  ln -sfn "$REPO_DIR/bin/agy-work" "$HOME/.local/bin/agy-work"

  # Also link opencode bridges if existing to share node_modules & logged-in profiles
  if [ -d "$HOME/.config/opencode/chatgpt-bridge/node_modules" ] && [ ! -d "$BRIDGE/node_modules" ]; then
    log "Reusing existing node_modules from opencode"
    ln -sfn "$HOME/.config/opencode/chatgpt-bridge/node_modules" "$BRIDGE/node_modules"
  fi
  if [ -d "$HOME/.config/opencode/gemini-bridge/node_modules" ] && [ ! -d "$GEMINI/node_modules" ]; then
    log "Reusing existing gemini node_modules from opencode"
    ln -sfn "$HOME/.config/opencode/gemini-bridge/node_modules" "$GEMINI/node_modules"
  fi
  if [ -d "$HOME/.config/opencode/chatgpt-bridge/libs" ] && [ ! -d "$BRIDGE/libs" ]; then
    ln -sfn "$HOME/.config/opencode/chatgpt-bridge/libs" "$BRIDGE/libs"
  fi
  if [ -d "$HOME/.config/opencode/chatgpt-bridge/profile" ] && [ ! -d "$BRIDGE/profile" ]; then
    log "Reusing existing ChatGPT profile from opencode"
    ln -sfn "$HOME/.config/opencode/chatgpt-bridge/profile" "$BRIDGE/profile"
  fi
  if [ -d "$HOME/.config/opencode/gemini-bridge/profile" ] && [ ! -d "$GEMINI/profile" ]; then
    log "Reusing existing Gemini profile from opencode"
    ln -sfn "$HOME/.config/opencode/gemini-bridge/profile" "$GEMINI/profile"
  fi

  log "Config and skills installed."
}

setup_deps() {
  need_cmd node; need_cmd npm
  if [ ! -d "$BRIDGE/node_modules" ]; then
    log "Installing npm dependencies in $BRIDGE"
    mkdir -p "$BRIDGE"
    (cd "$BRIDGE" && npm install --no-audit --no-fund)
  fi

  if [ -f "$GEMINI/package.json" ] && [ ! -d "$GEMINI/node_modules" ]; then
    log "Installing npm dependencies in $GEMINI"
    mkdir -p "$GEMINI"
    (cd "$GEMINI" && npm install --no-audit --no-fund)
  fi

  log "Installing Playwright Chromium"
  (cd "$BRIDGE" && npm exec -- playwright install chromium) || \
    npx --yes playwright@$(node -p "require('$BRIDGE/package.json').dependencies.playwright") install chromium

  log "Dependencies installed."
}

case "$MODE" in
  --config)
    setup_config
    ;;
  --deps)
    setup_deps
    ;;
  full)
    setup_config
    setup_deps
    ;;
  *)
    die "Unknown mode: $MODE (use --config, --deps, or full)"
    ;;
esac

echo
log "Setup completed successfully!"
log "Verify with:"
echo "  chatgpt-review status"
echo "  gemini-review status"
