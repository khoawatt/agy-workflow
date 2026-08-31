#!/usr/bin/env bash
# ============================================================================
# Install the ChatGPT Review bridge + Gemini review bridge for Antigravity (AGY)
#
#   bash install.sh            full setup (config + npm deps + chromium + system libs)
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

  # projects.conf for agy-work launcher (N-project, port from opencode-workflow)
  if [ -f "$REPO_DIR/config/projects.conf" ]; then
    if [ -f "$CFG_GEMINI/projects.conf" ]; then
      log "Kept existing projects.conf: $CFG_GEMINI/projects.conf"
    else
      cp "$REPO_DIR/config/projects.conf" "$CFG_GEMINI/projects.conf"
      chmod 0644 "$CFG_GEMINI/projects.conf" 2>/dev/null || true
      log "Installed projects.conf: $CFG_GEMINI/projects.conf (edit to add repos, then agy-work --reset)"
    fi
  fi

  # Copy skills to global config so they are discoverable across all AGY workspaces
  cp -R "$REPO_DIR/skills/"* "$CFG_GEMINI/skills/"

  # Bridge binaries + package manifest + default config (do not overwrite local state)
  cp "$REPO_DIR/bin/chatgpt-review.mjs" "$REPO_DIR/bin/chatgpt-review" "$REPO_DIR/bin/autoreview" "$BRIDGE/bin/"
  # session-auth for Gemini classifier
  [ -f "$REPO_DIR/bin/session-auth.mjs" ] && cp "$REPO_DIR/bin/session-auth.mjs" "$BRIDGE/bin/" 2>/dev/null || true
  [ -f "$REPO_DIR/bin/session-auth.mjs" ] && cp "$REPO_DIR/bin/session-auth.mjs" "$GEMINI/bin/" 2>/dev/null || true
  # Sources sync (hybrid .git + metadata) - also available as chatgpt-review sources / src-sync etc.
  [ -f "$REPO_DIR/bin/chatgpt-sources-sync.mjs" ] && cp "$REPO_DIR/bin/chatgpt-sources-sync.mjs" "$BRIDGE/bin/" || true
  [ -f "$REPO_DIR/bin/sources" ] && cp "$REPO_DIR/bin/sources" "$BRIDGE/bin/" || true
  cp "$REPO_DIR/package.json" "$BRIDGE/"
  [ -f "$BRIDGE/bridge-config.json" ] || cp "$REPO_DIR/bridge-config.json" "$BRIDGE/"

  # Gemini bridge
  cp "$REPO_DIR/bin/gemini-review.mjs" "$REPO_DIR/bin/gemini-review" "$GEMINI/bin/"
  cp "$REPO_DIR/package.json" "$GEMINI/"
  [ -f "$GEMINI/bridge-config.json" ] || printf '{ "max_chars": 400000, "max_turns": 40, "max_age_hours": 48 }\n' > "$GEMINI/bridge-config.json"

  # Make scripts executable
  chmod +x "$BRIDGE/bin/chatgpt-review" "$BRIDGE/bin/chatgpt-review.mjs" "$BRIDGE/bin/autoreview"
  [ -f "$BRIDGE/bin/chatgpt-sources-sync.mjs" ] && chmod +x "$BRIDGE/bin/chatgpt-sources-sync.mjs" || true
  [ -f "$BRIDGE/bin/sources" ] && chmod +x "$BRIDGE/bin/sources" || true
  [ -f "$BRIDGE/bin/session-auth.mjs" ] && chmod +x "$BRIDGE/bin/session-auth.mjs" || true
  chmod +x "$GEMINI/bin/gemini-review" "$GEMINI/bin/gemini-review.mjs"
  [ -f "$GEMINI/bin/session-auth.mjs" ] && chmod +x "$GEMINI/bin/session-auth.mjs" || true

  # Symlink to ~/.local/bin so PATH finds them immediately
  ln -sfn "$BRIDGE/bin/chatgpt-review" "$HOME/.local/bin/chatgpt-review"
  ln -sfn "$BRIDGE/bin/autoreview" "$HOME/.local/bin/autoreview"
  ln -sfn "$GEMINI/bin/gemini-review" "$HOME/.local/bin/gemini-review"
  ln -sfn "$BRIDGE/bin/sources" "$HOME/.local/bin/sources" 2>/dev/null || true
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

  # System libraries that headful Chromium needs on Debian/Ubuntu
  install_system_libs
  log "Dependencies installed."
}

# ---------------------------------------------------------------------------
# Ensure Chromium's shared libraries are present (Debian/Ubuntu).
# Uses sudo if available, otherwise downloads .deb packages into libs/.
# ---------------------------------------------------------------------------
install_system_libs() {
  command -v apt-get >/dev/null 2>&1 || { warn "Not an apt system; assuming libs are present."; return; }

  # Probe the chromium binary for missing libs.
  local chrome=""
  if [ -d "$BRIDGE" ]; then
    chrome="$(node -e "
      const { existsSync } = require('fs');
      const os = require('os');
      const { join } = require('path');
      const root = join(os.homedir(), '.cache', 'ms-playwright');
      try {
        const dirs = require('fs').readdirSync(root).sort().reverse();
        for (const d of dirs) {
          if (!d.startsWith('chromium-')) continue;
          for (const c of [join(root,d,'chrome-linux64','chrome'), join(root,d,'chrome-linux','chrome')]) {
            if (existsSync(c)) { console.log(c); process.exit(0); }
          }
        }
      } catch {}
      process.exit(0);
    " 2>/dev/null || true)"
  fi
  [ -n "$chrome" ] || { warn "Chromium not found yet; system libs check skipped."; return; }

  local missing
  missing="$(ldd "$chrome" 2>/dev/null | grep 'not found' | awk '{print $1}' | tr '\n' ' ' || true)"
  [ -n "$missing" ] || { log "All Chromium system libraries present."; return; }
  warn "Missing libraries: $missing"

  if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    log "Installing missing libraries via apt (passwordless sudo available)"
    sudo apt-get update -y >/dev/null 2>&1 || true
    # map common missing libs to packages
    local pkgs="libnspr4 libnss3 libasound2t64"
    sudo apt-get install -y --no-install-recommends $pkgs || \
      sudo apt-get install -y --no-install-recommends libnspr4 libnss3 libasound2
    return
  fi

  warn "No passwordless sudo. Downloading .deb packages into $BRIDGE/libs (user-space)."
  mkdir -p "$BRIDGE/libs" /tmp/agy-bridge-libs
  cd /tmp/agy-bridge-libs
  apt-get download libnspr4 libnss3 libasound2t64 2>/dev/null || \
    apt-get download libnspr4 libnss3 libasound2
  for f in *.deb; do dpkg -x "$f" rootfs 2>/dev/null || true; done
  [ -d rootfs/usr/lib/x86_64-linux-gnu ] && cp -R rootfs/usr/lib/x86_64-linux-gnu/* "$BRIDGE/libs/" || \
    cp -R rootfs/usr/lib/* "$BRIDGE/libs/" 2>/dev/null || true
  log "User-space libraries installed into $BRIDGE/libs"
}

# ---------------------------------------------------------------------------
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
    log "Setup complete."
    echo
    log "Next steps:"
    echo "  1. Sign in to ChatGPT once:  $BRIDGE/bin/chatgpt-review login"
    echo "     (optional) Gemini:        $GEMINI/bin/gemini-review login   # sign in with your Google account"
    echo "  2. Verify:                   $BRIDGE/bin/chatgpt-review status   (expect loggedIn: true)"
    echo "     (optional) Gemini:        $GEMINI/bin/gemini-review status    (expect loggedIn: true)"
    echo "  3. Restart AGY so it loads the new skills."
    echo
    echo "  Use chatgpt-review ask, gemini-review ask, autoreview on|off, or agy-work to launch tmux."
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
